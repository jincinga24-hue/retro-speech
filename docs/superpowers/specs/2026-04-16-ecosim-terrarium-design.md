# EcoSim — Sealed Terrarium Ecosystem Simulator

**Date:** 2026-04-16
**Status:** Design approved
**Host:** aips.build

## Overview

A browser-based sealed terrarium ecosystem simulator inspired by the viral TikTok 上帝模拟器生态缸 (God Simulator Eco-Tank) trend and 小鱼缸 phone widgets. Users build a terrarium with terrain and creatures, seal it, then observe the ecosystem play out with real population dynamics, food chains, and environmental cycles. Illustrated/cute visual style with smooth skeletal animations. No existing open-source land terrarium simulator exists — this fills that gap.

## Core Concept

- One terrarium tank, side-view cross-section
- Two phases: **Setup** (god mode — place creatures and terrain) then **Sealed** (pure observation, no intervention)
- Real ecological simulation underneath: food chains, reproduction, death, environmental feedback loops
- Illustrated/cute visual style (soft shapes, expressive, Studio Ghibli-meets-nature-doc)
- Hosted on aips.build (Vercel)

## Creatures (22 types)

### Predators (4)
| Creature | Chinese | Role |
|----------|---------|------|
| Gecko | 壁虎 | Top predator, hunts insects |
| Praying Mantis | 螳螂 | Ambush hunter |
| Spider | 蜘蛛 | Web-builder, catches flying insects |
| Centipede | 蜈蚣 | Underground hunter |

### Prey / Herbivores (6)
| Creature | Chinese | Role |
|----------|---------|------|
| Cricket | 蟋蟀 | Fast, chirps at night |
| Grasshopper | 蚱蜢 | Jumps, eats plants |
| Caterpillar → Butterfly | 毛毛虫 → 蝴蝶 | Metamorphosis |
| Snail | 蜗牛 | Slow, eats moss/plants |
| Slug | 蛞蝓 | No shell, faster than snail |
| Earthworm | 蚯蚓 | Underground, aerates soil |

### Colony Insects (3)
| Creature | Chinese | Role |
|----------|---------|------|
| Ants | 蚂蚁 | Tunnel, forage, carry food |
| Termites | 白蚁 | Eat wood, build mounds |
| Pill Bugs (Roly-poly) | 鼠妇 | Group behavior, moisture-loving |

### Decomposers (3)
| Creature | Chinese | Role |
|----------|---------|------|
| Springtails | 跳虫 | Tiny, break down waste |
| Isopods | 潮虫 | Eat decaying matter |
| Dung Beetle | 粪金龟 | Rolls/buries waste |

### Flyers (2)
| Creature | Chinese | Role |
|----------|---------|------|
| Butterfly | 蝴蝶 | Metamorphosis from caterpillar |
| Firefly | 萤火虫 | Glows at night |

### Plants (4+)
Moss, ferns, small mushrooms, succulents. Plants grow, spread, and die based on light, moisture, and nutrients.

## Simulation Engine

### Dual-Layer Architecture

**Layer 1: Environment (cellular automata grid)**
- Each cell: soil type, moisture, temperature, light level, nutrients, decay matter
- Gas diffusion: O2/CO2 spread across cells
- Day/night cycle: affects light, temperature, creature behavior
- Moisture: evaporates from surface, accumulates underground
- Plants grow/spread based on light + moisture + nutrients

**Layer 2: Creatures (entity-based agents)**
- Each creature: position, energy, hunger, age, health, state (idle/hunting/fleeing/eating/sleeping)
- Free movement across grid (not cell-locked)
- Per-species behavior trees (gecko stalks differently than ant forages)
- Food chain enforced: predators hunt prey, herbivores eat plants, decomposers eat dead matter
- Reproduction at energy threshold, death at energy 0 or max age
- Genetic variation: offspring inherit parent traits with slight mutations (speed, size, energy efficiency)

### Environmental Feedback Loop
Dead creatures → decay matter → decomposers break down → nutrients → plants grow → O2 produced → herbivores eat plants → predators eat herbivores → circle of life

### Time
- Simulation ticks at configurable rate (1 tick = 1 in-game minute)
- Seasonal temperature shifts affect reproduction and activity
- Real-time persistent: ecosystem keeps running conceptually even when tab is closed
- On reopen: fetch last saved state, fast-forward the gap, show catch-up timelapse

## Visual Strategy

### Priority Stack

**P0 — Must Nail (80% of the wow factor)**
1. **Creature animations** — each creature feels alive. 5-8 animation states per creature: idle, walk, eat, hunt/flee, sleep, die, species-specific (dig, cocoon, glow). ~130-170 unique animations total. Skeletal animation (Spine/DragonBones) for efficiency — one rig = many smooth animations from a single asset.
2. **Lighting & atmosphere** — smooth day/night transitions. Warm golden day, deep blue moonlight. Firefly glow. Dappled light through plants. Soft shadows under rocks and logs.

**P1 — High**
3. **Terrain & plants** — layered soil cross-section, moss spreading, ferns swaying, mushrooms appearing near decay, visible ant tunnels underground, plants that grow over time.
4. **Interaction moments** — gecko lunging at cricket, ants swarming dead beetle, caterpillar cocoon → butterfly emergence, snail climbing rock. The shareable moments.

**P2 — Nice to Have**
5. **Particle effects** — dust motes in light beams, water condensation on glass, soil particles when ants dig, pollen drifting, morning fog.
6. **Sound design** — cricket chirps at night, ambient rain, rustling when creatures move through leaves.

### Visual Style
- Illustrated/cute: soft rounded shapes, expressive, warm colors
- AI-generated creature base art + skeletal rigging for animation
- Tools: PixelLab/Midjourney for base assets, Spine/DragonBones for rigging

## Setup Phase (God Mode)

**Terrain building:**
- Side-view cross-section of tank
- Drag to paint soil layers, place rocks, logs, bark
- Drop in plants — they grow from placement point
- Add a small water dish
- Temperature and humidity sliders

**Creature placement:**
- Sidebar with all creatures as illustrated cards
- Drag into tank — lands where dropped
- Tooltip per creature: diet, predators, preferred environment
- Constraints: ants placed as colony (10+), max 1-2 geckos
- Population balance indicator: warns about immediate extinction scenarios

**Seal:**
- "Seal" button → glass lid animation closes
- No more changes from this point
- Timer starts: ecosystem age counter

## Observation Phase & UI

**Main view:**
- Terrarium fills most of screen — minimal UI clutter
- Glass tank border with subtle reflections/condensation
- Day/night lighting in real time

**Minimal HUD (edges only):**
- Top-left: ecosystem age ("Day 47"), time-of-day icon
- Top-right: population count per species (tiny icons + numbers)
- Bottom: temperature, humidity, O2/CO2 bars — subtle

**Catch-up replay:**
- On reopen after absence: brief timelapse of key events
- "While you were gone..." overlay
- Events log: "Day 12: Gecko caught a cricket", "Day 15: Ant colony expanded", "Day 18: First butterfly emerged"

**Camera:**
- Click any creature to follow it, see stats (energy, age, hunger)
- Pinch to zoom in/out
- Zoom into ant tunnels for underground detail

## Tech Stack

- **Renderer:** PixiJS v8 (WebGL, sprite batching, handles hundreds of animated sprites)
- **Language:** TypeScript
- **Animation:** Spine or DragonBones runtime (skeletal animation for creatures)
- **Persistence:** Supabase (tank state, creature positions, environment)
- **Hosting:** Vercel via aips.build
- **Simulation:** Pure functions, separate from rendering — testable, fast-forwardable

## Project Structure

```
ecosim/
  src/
    simulation/          — pure logic, no rendering
      environment.ts     — CA grid: moisture, nutrients, gas, light
      creatures/         — one file per species behavior tree
      genetics.ts        — trait inheritance + mutation
      food-chain.ts      — predator-prey relationships
      time.ts            — tick management, fast-forward
    rendering/           — PixiJS + animations
      tank.ts            — main container, glass border
      creatures/         — sprite/animation per species
      lighting.ts        — day/night, shadows, glow
      particles.ts       — dust, condensation, pollen
      terrain.ts         — soil layers, plants, rocks
    ui/                  — HUD, setup screen, event log
      setup.ts           — god mode interface
      hud.ts             — observation phase overlay
      replay.ts          — catch-up timelapse
    state/               — Supabase sync, save/load
      persistence.ts
      catchup.ts         — compute missed time
  assets/
    creatures/           — Spine rigs + textures per species
    terrain/             — soil, rocks, plants, water
    effects/             — particles, lighting textures
    ui/                  — icons, buttons, cards
```

## Reference Codebases

- **[Orb.Farm](https://github.com/MaxBittker/orb.farm)** — sealed aquatic ecosystem, CA simulation with O2/CO2/light cycles. Primary design reference for simulation model. Rust/WASM.
- **[terra.js](https://github.com/rileyjshaw/terra)** — creature registration framework, pure JS. Reference for species API pattern.
- **[Sandboxels](https://github.com/R74nCom/sandboxels)** — falling-sand CA with mod API. Reference for terrain physics.
- **[predator-flocks](https://github.com/decentralion/predator-flocks)** — boids + genetics + predator-prey. Reference for creature AI.

## Phasing

### Wave 1 — The Tank Lives (MVP)
- 6-8 core creatures: gecko, ants, snail, cricket, beetle, caterpillar/butterfly, firefly, earthworm
- Basic terrain: soil, rocks, one plant type, log
- Day/night lighting cycle
- Setup phase + seal
- Creatures move, eat, hunt, die, reproduce
- Hosted on aips.build

### Wave 2 — Full Ecosystem
- All 22 creatures
- Full plant variety, mushrooms, moss spreading
- Environmental feedback (O2/CO2, moisture, nutrients)
- Genetic variation in offspring
- Particle effects

### Wave 3 — Persistence & Polish
- Supabase save/load
- Catch-up replay ("while you were gone...")
- Event log
- Sound design
- Zoom/follow creature
