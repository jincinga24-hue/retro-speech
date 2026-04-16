# Architecture: AntWar — 蚂蚁帝国

## Tech Stack
- **Frontend:** Vite + TypeScript
- **Renderer:** PixiJS v8 (WebGL, texture sprites, shaders, particle system)
- **Animation:** DragonBones (free skeletal animation for ant rigs)
- **State:** localStorage for v1
- **Hosting:** Vercel via aips.build

## Folder Structure

```
antwar/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── public/
│   └── assets/
│       ├── textures/          — soil, rock, grass sprite sheets
│       ├── ants/              — DragonBones rig exports per ant type
│       ├── effects/           — particle textures, glow sprites
│       └── ui/                — icons, buttons
├── src/
│   ├── main.ts                — entry point, init PixiJS app
│   ├── game.ts                — game loop, phase management (setup/sealed)
│   │
│   ├── simulation/            — pure logic, zero rendering imports
│   │   ├── grid.ts            — CA soil grid (cell types, pheromones)
│   │   ├── colony.ts          — colony state, queen AI, resource mgmt
│   │   ├── ant.ts             — ant agent: state machine, movement
│   │   ├── combat.ts          — fight resolution, swarming, raids
│   │   ├── pheromones.ts      — trail laying, decay, following
│   │   ├── tunneling.ts       — dig logic, chamber creation
│   │   ├── win-conditions.ts  — queen kill, starvation, takeover checks
│   │   ├── food.ts            — food sources, foraging, storage
│   │   └── time.ts            — tick rate, fast-forward, day/night
│   │
│   ├── rendering/             — PixiJS rendering layer
│   │   ├── app.ts             — PixiJS application setup, resize
│   │   ├── tank.ts            — widget container, background, glass
│   │   ├── soil.ts            — textured soil layers, strata, pebbles
│   │   ├── tunnels.ts         — tunnel mesh rendering, organic edges
│   │   ├── ants.ts            — ant sprite pool, DragonBones playback
│   │   ├── lighting.ts        — colony glow, day/night, depth shadows
│   │   ├── particles.ts       — dig particles, fight dust, ambient
│   │   ├── surface.ts         — grass, entry holes, food on surface
│   │   └── camera.ts          — zoom, pan (future)
│   │
│   ├── ui/                    — DOM-based UI (outside canvas)
│   │   ├── setup.ts           — setup phase: place queens, food, rocks
│   │   ├── scoreboard.ts      — Red vs Blue stats overlay
│   │   ├── territory-bar.ts   — thin balance-of-power strip
│   │   ├── event-log.ts       — slide-up panel with timestamped entries
│   │   ├── speed-controls.ts  — 1x/2x/5x/10x buttons
│   │   └── win-screen.ts      — victory overlay with stats
│   │
│   ├── state/
│   │   ├── persistence.ts     — localStorage save/load
│   │   └── catchup.ts         — fast-forward missed time on reopen
│   │
│   └── utils/
│       ├── random.ts          — seeded RNG for reproducible sims
│       ├── vec2.ts            — 2D vector math
│       └── constants.ts       — grid size, tick rate, colony defaults
│
└── docs/
    ├── PRD.md
    ├── UI-DESIGN.md
    └── ARCHITECTURE.md
```

## Key Libraries
- **pixi.js** (v8): WebGL renderer, sprite batching, containers, filters
- **@pixi/particle-emitter**: particle effects (dig, dust, ambient)
- **dragonbones-pixi** (or pixi-dragonbones): skeletal animation runtime
- **No framework** (React/Vue): pure TS + PixiJS + vanilla DOM for UI

## Data Flow

```
User Input (setup phase)
    ↓
Game State (colony positions, food, rocks)
    ↓
Simulation Tick Loop (pure functions)
    ├── grid.update()        → soil cells, pheromone decay
    ├── colony.update()      → queen decisions, egg laying
    ├── ant.update()         → each ant's state machine
    ├── combat.resolve()     → fight outcomes
    ├── tunneling.dig()      → new tunnel cells
    ├── food.forage()        → food pickup/deposit
    └── winConditions.check()→ game over?
    ↓
Render Loop (60fps, reads simulation state)
    ├── soil.render()        → textured background
    ├── tunnels.render()     → carved tunnel meshes
    ├── ants.render()        → position/animate sprites
    ├── lighting.render()    → colony glow, shadows
    └── particles.render()   → dig/fight/ambient effects
    ↓
UI Update (DOM, reads simulation state)
    ├── scoreboard.update()  → territory %, population, food
    ├── territoryBar.update()→ red/blue balance
    ├── eventLog.append()    → new events
    └── winScreen.show()     → if game over
```

## Simulation Architecture

### Grid
- 2D array of cells, each cell is: `SOIL | TUNNEL | CHAMBER | ROCK | SURFACE | FOOD`
- Each cell also stores: `pheromoneRed`, `pheromoneBlue`, `moisture`
- Grid resolution: ~200x140 cells for the widget viewport
- Tunnels are carved by removing SOIL cells

### Ant Agent
```
States: IDLE → FORAGING → CARRYING → DEPOSITING → RETURNING
        IDLE → PATROLLING → FIGHTING → FLEEING
        IDLE → DIGGING → (back to IDLE)
        IDLE → TENDING_LARVAE → (back to IDLE)

Each tick:
  1. Read current cell + nearby cells
  2. Follow pheromone gradient (strongest trail of own colony)
  3. Execute state behavior (move, dig, pick up, fight, etc.)
  4. Deposit pheromone on current cell
  5. Consume energy
  6. Die if energy = 0 or health = 0
```

### Colony AI
- Queen adjusts egg-laying rate based on food reserves
- Colony shifts worker/soldier ratio based on border threat level
- Expansion direction follows food sources and moisture gradients
- Defense: when enemy detected, nearby soldiers converge

### Combat
- 1v1: type advantage (soldier > worker > scout) + energy + random
- Swarming: multiple ants in same cell multiply strength
- Fight duration: 2-5 ticks, loser dies, winner loses some energy

### Separation of Concerns
- **Simulation knows nothing about rendering.** It operates on pure data.
- **Rendering reads simulation state each frame** and updates visuals.
- **UI reads simulation state** and updates DOM elements.
- This allows: fast-forward (run N ticks without rendering), testing (sim without canvas), replay (record tick states).
