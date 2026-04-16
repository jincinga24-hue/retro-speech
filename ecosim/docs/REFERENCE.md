# Development Standards: AntWar

## File Naming
- kebab-case for all files: `win-conditions.ts`, `event-log.ts`
- PascalCase for classes/types: `AntAgent`, `ColonyState`
- camelCase for functions/variables: `resolvesCombat`, `pheromoneStrength`

## File Size Limits
- Max 300 lines per file
- If a file exceeds the limit, split into smaller modules

## Code Style
- Strict TypeScript: `strict: true` in tsconfig
- No `any` types — use proper interfaces
- Immutable patterns: create new objects, never mutate
- Pure functions for simulation logic — no side effects
- Const by default, let only when reassignment needed

## Module Patterns
- One export per file when possible
- Named exports over default exports
- Barrel exports (`index.ts`) only for public API boundaries

## Import Order
1. External packages (pixi.js, dragonbones)
2. Simulation modules
3. Rendering modules
4. UI modules
5. Utils

## Simulation Rules
- Simulation code must NEVER import from rendering/ or ui/
- Rendering code reads simulation state, never writes to it
- UI code reads simulation state, never writes to it
- Only game.ts orchestrates the tick loop and bridges layers
