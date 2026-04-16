# PRD: AntWar — 蚂蚁帝国 Ant Empire Simulator

## Problem
There's no passive-observation ant colony battle simulator. Every existing ant game makes you control the ants. The physical 蚂蚁生态箱 experience — set up two colonies, seal the tank, come back to see who's winning — doesn't exist digitally.

## Target User
Anyone fascinated by ant farms, the 上帝模拟器生态缸 TikTok trend, or nature simulations. People who want to set something up, check on it periodically, and discover what happened while they were away.

## MVP Features (v1 — Wave 1)

1. **Setup Phase (God Mode)**
   - **Acceptance criteria:** User can place two queens (Red left, Blue right), drag food sources onto the surface/underground, place rocks as obstacles. User clicks "Seal" and the tank closes. Setup takes under 2 minutes.

2. **Autonomous Colony Simulation**
   - **Acceptance criteria:** Both colonies independently dig tunnels, forage for food, reproduce (queen lays eggs → larvae → adult ants), and fight when they encounter enemy ants. Workers dig and carry food, soldiers fight and patrol. No user intervention after sealing.

3. **Tunnel Network Visualization**
   - **Acceptance criteria:** Tunnels grow organically (not grid-perfect) and are clearly visible as carved-out spaces in the soil. Red colony tunnels have warm tint, Blue has cool tint. Chambers visually distinct from passages. The tunnel growth is the core visual experience.

4. **Combat**
   - **Acceptance criteria:** When ants from opposing colonies meet in a tunnel, they fight. Outcome based on ant type (soldier > worker), energy, and numbers. Visible grappling animation. Loser dies and body remains briefly.

5. **Win Conditions**
   - **Acceptance criteria:** Game detects queen kill (attackers reach and kill queen), starvation (colony runs out of food, population crashes), or total takeover (one colony controls 80%+ territory for 3+ days). Simulation continues after win — you watch the aftermath.

6. **Event Log Sidebar**
   - **Acceptance criteria:** Slide-in sidebar with timestamped entries: "Day 12, 14:22 — Red scouts discovered Blue's food storage." Educational context included. Categories: battle, construction, birth, death, discovery, food.

7. **Territory Scoreboard**
   - **Acceptance criteria:** Top-right HUD shows Red vs Blue: territory %, population count, food reserves. Updated in real time. At a glance you can tell who's winning.

## Success Metrics
- User spends 3+ minutes watching after sealing
- User returns to check on the tank at least once
- A win condition triggers within a reasonable timeframe (not 5 minutes, not 5 hours)

## Non-Goals (out of scope for v1)
- Scouts + pheromone trail visualization (Wave 2)
- Colony trait selection (Wave 2)
- Raiding mechanics (Wave 2)
- Larvae/nursery system (Wave 2)
- Genetic variation (Wave 2)
- Sound design (Wave 3)
- Catch-up replay (Wave 3)
- Save/load persistence (Wave 3)
- Zoom/follow individual ant (Wave 3)
- Share/screenshot (Wave 3)

## Boundaries & Non-Functionals
- **Privacy:** No user data collected in v1. Everything in localStorage. No accounts, no tracking.
- **Security:** No auth. No backend. Static site on Vercel. Minimal attack surface.
- **Performance:** 60fps with 200+ ants on screen. No lag during tunnel digging or combat.
- **Scale:** Single user, single browser. No server load concerns for v1.

## Tech Stack
- **Build:** Vite + TypeScript
- **Renderer:** PixiJS v8 (WebGL, 2.5D parallax)
- **Animation:** DragonBones (free skeletal animation)
- **Persistence:** localStorage for v1
- **Hosting:** Vercel via aips.build
