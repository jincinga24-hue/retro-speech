# AntWar — 蚂蚁帝国

Two ant colonies (Red vs Blue) battle for territory in a sealed underground tank. Passive observation — you set up, seal, and watch. Inspired by physical 蚂蚁生态箱 ant farms and the 上帝模拟器 TikTok trend. Hosted on aips.build.

## Key Docs
- [PRD](docs/PRD.md) — product requirements, MVP features, acceptance criteria
- [UI Design](docs/UI-DESIGN.md) — widget layout, event log, scoreboard
- [Architecture](docs/ARCHITECTURE.md) — tech stack, folder structure, data flow
- [Dev Standards](docs/REFERENCE.md) — naming, file limits, import rules
- [Quality Gates](docs/QUALITY-GATES.md) — what must pass before shipping

## Tech Stack
- Vite + TypeScript (strict mode)
- PixiJS v8 (WebGL rendering, textures, shaders, particles)
- DragonBones (skeletal ant animations)
- localStorage (v1 persistence)
- Vercel via aips.build

## Architecture Rules
- **simulation/ must never import from rendering/ or ui/**
- Simulation is pure functions operating on data
- Rendering reads simulation state each frame, never writes
- UI reads simulation state, never writes
- Only game.ts bridges the layers

## File Rules
- kebab-case filenames
- Max 300 lines per file
- Immutable patterns — create new objects, never mutate
- No `any` types
