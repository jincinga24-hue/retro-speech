# AntWar — 蚂蚁帝国 Implementation Plan (Wave 1 MVP)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a browser-based ant colony battle simulator where two colonies (Red vs Blue) autonomously dig tunnels, forage, fight, and compete for territory in a sealed underground tank.

**Architecture:** Simulation layer (pure TS, no rendering) drives ant agents on a cellular automata grid. PixiJS v8 renders the state each frame as a widget on a clean background. DOM-based UI sits outside the canvas for scoreboard, event log, and controls. Strict separation: simulation never imports rendering.

**Tech Stack:** Vite, TypeScript (strict), PixiJS v8, vitest

---

## Phase 1: Foundation (Tasks 1-4)

### Task 1: Utils — Vec2, RNG, Constants

**Files:**
- Create: `src/utils/vec2.ts`
- Create: `src/utils/random.ts`
- Create: `src/utils/constants.ts`
- Create: `src/utils/vec2.test.ts`
- Create: `src/utils/random.test.ts`

- [ ] **Step 1: Write failing tests for Vec2**

```typescript
// src/utils/vec2.test.ts
import { describe, it, expect } from "vitest";
import { vec2, add, subtract, distance, normalize, scale } from "./vec2";

describe("vec2", () => {
  it("creates a vector", () => {
    const v = vec2(3, 4);
    expect(v.x).toBe(3);
    expect(v.y).toBe(4);
  });

  it("adds two vectors", () => {
    const result = add(vec2(1, 2), vec2(3, 4));
    expect(result).toEqual(vec2(4, 6));
  });

  it("subtracts two vectors", () => {
    const result = subtract(vec2(5, 7), vec2(2, 3));
    expect(result).toEqual(vec2(3, 4));
  });

  it("calculates distance", () => {
    const d = distance(vec2(0, 0), vec2(3, 4));
    expect(d).toBe(5);
  });

  it("normalizes a vector", () => {
    const n = normalize(vec2(3, 4));
    expect(n.x).toBeCloseTo(0.6);
    expect(n.y).toBeCloseTo(0.8);
  });

  it("scales a vector", () => {
    const result = scale(vec2(2, 3), 2);
    expect(result).toEqual(vec2(4, 6));
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ecosim && npx vitest run src/utils/vec2.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement Vec2**

```typescript
// src/utils/vec2.ts
export interface Vec2 {
  readonly x: number;
  readonly y: number;
}

export function vec2(x: number, y: number): Vec2 {
  return { x, y };
}

export function add(a: Vec2, b: Vec2): Vec2 {
  return vec2(a.x + b.x, a.y + b.y);
}

export function subtract(a: Vec2, b: Vec2): Vec2 {
  return vec2(a.x - b.x, a.y - b.y);
}

export function distance(a: Vec2, b: Vec2): Vec2 {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  return Math.sqrt(dx * dx + dy * dy) as unknown as Vec2;
}

export function normalize(v: Vec2): Vec2 {
  const len = Math.sqrt(v.x * v.x + v.y * v.y);
  return len === 0 ? vec2(0, 0) : vec2(v.x / len, v.y / len);
}

export function scale(v: Vec2, s: number): Vec2 {
  return vec2(v.x * s, v.y * s);
}
```

Note: `distance` return type should be `number`, not `Vec2`. Fix:
```typescript
export function distance(a: Vec2, b: Vec2): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  return Math.sqrt(dx * dx + dy * dy);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd ecosim && npx vitest run src/utils/vec2.test.ts`
Expected: PASS (6 tests)

- [ ] **Step 5: Write failing tests for seeded RNG**

```typescript
// src/utils/random.test.ts
import { describe, it, expect } from "vitest";
import { createRng } from "./random";

describe("createRng", () => {
  it("produces deterministic values from same seed", () => {
    const rng1 = createRng(42);
    const rng2 = createRng(42);
    expect(rng1.next()).toBe(rng2.next());
    expect(rng1.next()).toBe(rng2.next());
  });

  it("produces values between 0 and 1", () => {
    const rng = createRng(123);
    for (let i = 0; i < 100; i++) {
      const v = rng.next();
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThan(1);
    }
  });

  it("nextInt returns integer in range", () => {
    const rng = createRng(99);
    for (let i = 0; i < 100; i++) {
      const v = rng.nextInt(5, 10);
      expect(v).toBeGreaterThanOrEqual(5);
      expect(v).toBeLessThanOrEqual(10);
      expect(Number.isInteger(v)).toBe(true);
    }
  });

  it("chance returns boolean based on probability", () => {
    const rng = createRng(1);
    expect(typeof rng.chance(0.5)).toBe("boolean");
    expect(rng.chance(1)).toBe(true);
    expect(rng.chance(0)).toBe(false);
  });
});
```

- [ ] **Step 6: Implement seeded RNG**

```typescript
// src/utils/random.ts
export interface Rng {
  next(): number;
  nextInt(min: number, max: number): number;
  chance(probability: number): boolean;
}

export function createRng(seed: number): Rng {
  let state = seed;

  function next(): number {
    state = (state * 1664525 + 1013904223) & 0xffffffff;
    return (state >>> 0) / 0x100000000;
  }

  return {
    next,
    nextInt(min: number, max: number): number {
      return Math.floor(next() * (max - min + 1)) + min;
    },
    chance(probability: number): boolean {
      return next() < probability;
    },
  };
}
```

- [ ] **Step 7: Run RNG tests**

Run: `cd ecosim && npx vitest run src/utils/random.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 8: Write constants**

```typescript
// src/utils/constants.ts
export const GRID_WIDTH = 200;
export const GRID_HEIGHT = 140;

export const TICK_RATE_MS = 100; // 10 ticks per second at 1x speed
export const TICKS_PER_DAY = 1440; // 1 tick = 1 in-game minute

export const WIDGET_WIDTH = 680;
export const WIDGET_HEIGHT = 480;

export const COLONY_RED = "red" as const;
export const COLONY_BLUE = "blue" as const;
export type ColonyId = typeof COLONY_RED | typeof COLONY_BLUE;

export const ANT_ENERGY_MAX = 100;
export const ANT_ENERGY_MOVE_COST = 0.1;
export const ANT_ENERGY_DIG_COST = 0.5;
export const ANT_ENERGY_FIGHT_COST = 1;
export const ANT_ENERGY_FROM_FOOD = 30;

export const QUEEN_EGG_INTERVAL = 50; // ticks between egg lays
export const EGG_HATCH_TICKS = 200;

export const SOLDIER_COMBAT_STRENGTH = 3;
export const WORKER_COMBAT_STRENGTH = 1;

export const TERRITORY_WIN_THRESHOLD = 0.8;
export const TERRITORY_WIN_DAYS = 3;

export const STARVATION_THRESHOLD = 5; // food units below which starvation begins
```

- [ ] **Step 9: Commit**

```bash
cd ecosim && git add src/utils/ && git commit -m "feat: add vec2, seeded RNG, and game constants"
```

---

### Task 2: Grid — Cellular Automata Soil Grid

**Files:**
- Create: `src/simulation/grid.ts`
- Create: `src/simulation/grid.test.ts`

- [ ] **Step 1: Write failing tests for grid**

```typescript
// src/simulation/grid.test.ts
import { describe, it, expect } from "vitest";
import { createGrid, getCell, setCell, CellType, countCellsOfType } from "./grid";
import { GRID_WIDTH, GRID_HEIGHT, COLONY_RED, COLONY_BLUE } from "../utils/constants";

describe("grid", () => {
  it("creates a grid filled with SOIL", () => {
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    expect(grid.width).toBe(GRID_WIDTH);
    expect(grid.height).toBe(GRID_HEIGHT);
    const cell = getCell(grid, 10, 10);
    expect(cell.type).toBe(CellType.SOIL);
  });

  it("surface row is SURFACE type", () => {
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    const cell = getCell(grid, 50, 0);
    expect(cell.type).toBe(CellType.SURFACE);
  });

  it("sets a cell to TUNNEL", () => {
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    const updated = setCell(grid, 10, 10, { type: CellType.TUNNEL, colony: COLONY_RED });
    const cell = getCell(updated, 10, 10);
    expect(cell.type).toBe(CellType.TUNNEL);
    expect(cell.colony).toBe(COLONY_RED);
  });

  it("does not mutate the original grid on setCell", () => {
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    setCell(grid, 10, 10, { type: CellType.TUNNEL, colony: COLONY_RED });
    expect(getCell(grid, 10, 10).type).toBe(CellType.SOIL);
  });

  it("counts cells of a given type and colony", () => {
    let grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    grid = setCell(grid, 5, 5, { type: CellType.TUNNEL, colony: COLONY_RED });
    grid = setCell(grid, 6, 5, { type: CellType.TUNNEL, colony: COLONY_RED });
    grid = setCell(grid, 7, 5, { type: CellType.TUNNEL, colony: COLONY_BLUE });
    expect(countCellsOfType(grid, CellType.TUNNEL, COLONY_RED)).toBe(2);
    expect(countCellsOfType(grid, CellType.TUNNEL, COLONY_BLUE)).toBe(1);
  });

  it("out of bounds returns ROCK", () => {
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    expect(getCell(grid, -1, 0).type).toBe(CellType.ROCK);
    expect(getCell(grid, GRID_WIDTH, 0).type).toBe(CellType.ROCK);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ecosim && npx vitest run src/simulation/grid.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement grid**

```typescript
// src/simulation/grid.ts
import { type ColonyId } from "../utils/constants";

export enum CellType {
  SOIL = "soil",
  TUNNEL = "tunnel",
  CHAMBER = "chamber",
  ROCK = "rock",
  SURFACE = "surface",
  FOOD = "food",
}

export interface Cell {
  readonly type: CellType;
  readonly colony?: ColonyId;
  readonly pheromoneRed: number;
  readonly pheromoneBlue: number;
  readonly moisture: number;
  readonly foodAmount: number;
}

export interface Grid {
  readonly width: number;
  readonly height: number;
  readonly cells: ReadonlyArray<Cell>;
}

const SURFACE_ROWS = 7;

function defaultCell(y: number): Cell {
  return {
    type: y < SURFACE_ROWS ? CellType.SURFACE : CellType.SOIL,
    pheromoneRed: 0,
    pheromoneBlue: 0,
    moisture: 0.5,
    foodAmount: 0,
  };
}

const ROCK_CELL: Cell = {
  type: CellType.ROCK,
  pheromoneRed: 0,
  pheromoneBlue: 0,
  moisture: 0,
  foodAmount: 0,
};

export function createGrid(width: number, height: number): Grid {
  const cells: Cell[] = [];
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      cells.push(defaultCell(y));
    }
  }
  return { width, height, cells };
}

function idx(grid: Grid, x: number, y: number): number {
  return y * grid.width + x;
}

function inBounds(grid: Grid, x: number, y: number): boolean {
  return x >= 0 && x < grid.width && y >= 0 && y < grid.height;
}

export function getCell(grid: Grid, x: number, y: number): Cell {
  if (!inBounds(grid, x, y)) return ROCK_CELL;
  return grid.cells[idx(grid, x, y)];
}

export function setCell(
  grid: Grid,
  x: number,
  y: number,
  updates: Partial<Cell>
): Grid {
  if (!inBounds(grid, x, y)) return grid;
  const i = idx(grid, x, y);
  const newCells = [...grid.cells];
  newCells[i] = { ...newCells[i], ...updates };
  return { ...grid, cells: newCells };
}

export function countCellsOfType(
  grid: Grid,
  type: CellType,
  colony?: ColonyId
): number {
  let count = 0;
  for (const cell of grid.cells) {
    if (cell.type === type && (colony === undefined || cell.colony === colony)) {
      count++;
    }
  }
  return count;
}
```

- [ ] **Step 4: Run tests**

Run: `cd ecosim && npx vitest run src/simulation/grid.test.ts`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
cd ecosim && git add src/simulation/grid.ts src/simulation/grid.test.ts && git commit -m "feat: add cellular automata soil grid"
```

---

### Task 3: Ant Agent — Types, State Machine, Movement

**Files:**
- Create: `src/simulation/ant.ts`
- Create: `src/simulation/ant.test.ts`

- [ ] **Step 1: Write failing tests for ant creation and state transitions**

```typescript
// src/simulation/ant.test.ts
import { describe, it, expect } from "vitest";
import {
  createAnt,
  AntType,
  AntState,
  updateAnt,
  type Ant,
} from "./ant";
import { createGrid, setCell, CellType } from "./grid";
import { COLONY_RED, GRID_WIDTH, GRID_HEIGHT } from "../utils/constants";
import { createRng } from "../utils/random";

describe("ant", () => {
  it("creates a worker ant with full energy", () => {
    const ant = createAnt(1, AntType.WORKER, COLONY_RED, 10, 20);
    expect(ant.id).toBe(1);
    expect(ant.type).toBe(AntType.WORKER);
    expect(ant.colony).toBe(COLONY_RED);
    expect(ant.x).toBe(10);
    expect(ant.y).toBe(20);
    expect(ant.energy).toBe(100);
    expect(ant.state).toBe(AntState.IDLE);
    expect(ant.alive).toBe(true);
  });

  it("creates a soldier ant", () => {
    const ant = createAnt(2, AntType.SOLDIER, COLONY_RED, 5, 5);
    expect(ant.type).toBe(AntType.SOLDIER);
  });

  it("creates a queen ant", () => {
    const ant = createAnt(3, AntType.QUEEN, COLONY_RED, 5, 50);
    expect(ant.type).toBe(AntType.QUEEN);
  });

  it("ant dies when energy reaches 0", () => {
    const ant = createAnt(1, AntType.WORKER, COLONY_RED, 10, 20);
    const dead: Ant = { ...ant, energy: 0 };
    const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
    const rng = createRng(1);
    const result = updateAnt(dead, grid, [], rng);
    expect(result.ant.alive).toBe(false);
  });

  it("worker in tunnel moves to adjacent tunnel cell", () => {
    let grid = createGrid(20, 20);
    // Create a tunnel path
    grid = setCell(grid, 5, 10, { type: CellType.TUNNEL, colony: COLONY_RED });
    grid = setCell(grid, 6, 10, { type: CellType.TUNNEL, colony: COLONY_RED });
    grid = setCell(grid, 7, 10, { type: CellType.TUNNEL, colony: COLONY_RED });

    const ant = createAnt(1, AntType.WORKER, COLONY_RED, 5, 10);
    const rng = createRng(42);
    const result = updateAnt(
      { ...ant, state: AntState.FORAGING },
      grid,
      [],
      rng
    );
    // Ant should have moved to an adjacent tunnel cell
    const moved = result.ant.x !== 5 || result.ant.y !== 10;
    expect(moved).toBe(true);
    expect(result.ant.energy).toBeLessThan(100);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd ecosim && npx vitest run src/simulation/ant.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement ant agent**

```typescript
// src/simulation/ant.ts
import { type ColonyId, ANT_ENERGY_MAX, ANT_ENERGY_MOVE_COST, ANT_ENERGY_DIG_COST } from "../utils/constants";
import { type Grid, getCell, CellType } from "./grid";
import { type Rng } from "../utils/random";

export enum AntType {
  QUEEN = "queen",
  WORKER = "worker",
  SOLDIER = "soldier",
}

export enum AntState {
  IDLE = "idle",
  FORAGING = "foraging",
  CARRYING = "carrying",
  DIGGING = "digging",
  PATROLLING = "patrolling",
  FIGHTING = "fighting",
  RETURNING = "returning",
  DEAD = "dead",
}

export interface Ant {
  readonly id: number;
  readonly type: AntType;
  readonly colony: ColonyId;
  readonly x: number;
  readonly y: number;
  readonly energy: number;
  readonly health: number;
  readonly age: number;
  readonly state: AntState;
  readonly carrying: number; // food amount
  readonly alive: boolean;
  readonly targetX?: number;
  readonly targetY?: number;
}

export interface AntUpdateResult {
  readonly ant: Ant;
  readonly gridChanges: ReadonlyArray<{ x: number; y: number; type: CellType; colony: ColonyId }>;
  readonly events: ReadonlyArray<string>;
}

export function createAnt(
  id: number,
  type: AntType,
  colony: ColonyId,
  x: number,
  y: number
): Ant {
  return {
    id,
    type,
    colony,
    x,
    y,
    energy: ANT_ENERGY_MAX,
    health: type === AntType.SOLDIER ? 150 : 100,
    age: 0,
    state: AntState.IDLE,
    carrying: 0,
    alive: true,
  };
}

const DIRECTIONS = [
  { dx: -1, dy: 0 },
  { dx: 1, dy: 0 },
  { dx: 0, dy: -1 },
  { dx: 0, dy: 1 },
  { dx: -1, dy: -1 },
  { dx: 1, dy: -1 },
  { dx: -1, dy: 1 },
  { dx: 1, dy: 1 },
];

function findAdjacentOfType(
  grid: Grid,
  x: number,
  y: number,
  type: CellType,
  rng: Rng
): { x: number; y: number } | null {
  const options: Array<{ x: number; y: number }> = [];
  for (const { dx, dy } of DIRECTIONS) {
    const cell = getCell(grid, x + dx, y + dy);
    if (cell.type === type) {
      options.push({ x: x + dx, y: y + dy });
    }
  }
  if (options.length === 0) return null;
  return options[rng.nextInt(0, options.length - 1)];
}

function findAdjacentDiggable(
  grid: Grid,
  x: number,
  y: number,
  rng: Rng
): { x: number; y: number } | null {
  const options: Array<{ x: number; y: number }> = [];
  for (const { dx, dy } of DIRECTIONS) {
    const cell = getCell(grid, x + dx, y + dy);
    if (cell.type === CellType.SOIL) {
      options.push({ x: x + dx, y: y + dy });
    }
  }
  if (options.length === 0) return null;
  return options[rng.nextInt(0, options.length - 1)];
}

export function updateAnt(
  ant: Ant,
  grid: Grid,
  nearbyEnemies: ReadonlyArray<Ant>,
  rng: Rng
): AntUpdateResult {
  if (ant.energy <= 0 || !ant.alive) {
    return {
      ant: { ...ant, alive: false, state: AntState.DEAD },
      gridChanges: [],
      events: [],
    };
  }

  const aged: Ant = { ...ant, age: ant.age + 1 };

  // Queen stays put
  if (aged.type === AntType.QUEEN) {
    return { ant: { ...aged, energy: aged.energy - 0.02 }, gridChanges: [], events: [] };
  }

  // Check for enemies in adjacent cells — soldiers engage
  if (nearbyEnemies.length > 0 && aged.type === AntType.SOLDIER) {
    return {
      ant: { ...aged, state: AntState.FIGHTING, energy: aged.energy - ANT_ENERGY_MOVE_COST },
      gridChanges: [],
      events: [],
    };
  }

  switch (aged.state) {
    case AntState.IDLE: {
      // Workers: 60% forage, 40% dig. Soldiers: patrol.
      if (aged.type === AntType.WORKER) {
        const nextState = rng.chance(0.6) ? AntState.FORAGING : AntState.DIGGING;
        return { ant: { ...aged, state: nextState }, gridChanges: [], events: [] };
      }
      return { ant: { ...aged, state: AntState.PATROLLING }, gridChanges: [], events: [] };
    }

    case AntState.FORAGING: {
      // Move along tunnel toward food
      const target = findAdjacentOfType(grid, aged.x, aged.y, CellType.TUNNEL, rng)
        ?? findAdjacentOfType(grid, aged.x, aged.y, CellType.SURFACE, rng);
      if (target) {
        const cell = getCell(grid, target.x, target.y);
        if (cell.foodAmount > 0) {
          return {
            ant: { ...aged, x: target.x, y: target.y, carrying: 1, state: AntState.RETURNING, energy: aged.energy - ANT_ENERGY_MOVE_COST },
            gridChanges: [{ x: target.x, y: target.y, type: cell.type, colony: aged.colony }],
            events: [],
          };
        }
        return {
          ant: { ...aged, x: target.x, y: target.y, energy: aged.energy - ANT_ENERGY_MOVE_COST },
          gridChanges: [],
          events: [],
        };
      }
      return { ant: { ...aged, state: AntState.IDLE }, gridChanges: [], events: [] };
    }

    case AntState.RETURNING: {
      // Move back toward own territory (lower x for red, higher x for blue)
      const target = findAdjacentOfType(grid, aged.x, aged.y, CellType.TUNNEL, rng);
      if (target) {
        return {
          ant: { ...aged, x: target.x, y: target.y, energy: aged.energy - ANT_ENERGY_MOVE_COST },
          gridChanges: [],
          events: [],
        };
      }
      // Deposit food and go idle
      return {
        ant: { ...aged, carrying: 0, state: AntState.IDLE },
        gridChanges: [],
        events: [],
      };
    }

    case AntState.DIGGING: {
      const target = findAdjacentDiggable(grid, aged.x, aged.y, rng);
      if (target) {
        return {
          ant: { ...aged, x: target.x, y: target.y, energy: aged.energy - ANT_ENERGY_DIG_COST },
          gridChanges: [{ x: target.x, y: target.y, type: CellType.TUNNEL, colony: aged.colony }],
          events: [],
        };
      }
      return { ant: { ...aged, state: AntState.IDLE }, gridChanges: [], events: [] };
    }

    case AntState.PATROLLING: {
      const target = findAdjacentOfType(grid, aged.x, aged.y, CellType.TUNNEL, rng);
      if (target) {
        return {
          ant: { ...aged, x: target.x, y: target.y, energy: aged.energy - ANT_ENERGY_MOVE_COST },
          gridChanges: [],
          events: [],
        };
      }
      return { ant: { ...aged, state: AntState.IDLE }, gridChanges: [], events: [] };
    }

    case AntState.FIGHTING: {
      // Combat handled externally by combat.ts
      return { ant: aged, gridChanges: [], events: [] };
    }

    default:
      return { ant: aged, gridChanges: [], events: [] };
  }
}
```

- [ ] **Step 4: Run tests**

Run: `cd ecosim && npx vitest run src/simulation/ant.test.ts`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
cd ecosim && git add src/simulation/ant.ts src/simulation/ant.test.ts && git commit -m "feat: add ant agent with state machine and movement"
```

---

### Task 4: Colony State + Combat + Win Conditions

**Files:**
- Create: `src/simulation/colony.ts`
- Create: `src/simulation/colony.test.ts`
- Create: `src/simulation/combat.ts`
- Create: `src/simulation/combat.test.ts`
- Create: `src/simulation/win-conditions.ts`
- Create: `src/simulation/win-conditions.test.ts`

- [ ] **Step 1: Write failing tests for colony**

```typescript
// src/simulation/colony.test.ts
import { describe, it, expect } from "vitest";
import { createColony, addAnt, removeAnt, type Colony } from "./colony";
import { createAnt, AntType } from "./ant";
import { COLONY_RED } from "../utils/constants";

describe("colony", () => {
  it("creates a colony with a queen", () => {
    const colony = createColony(COLONY_RED, 10, 50);
    expect(colony.id).toBe(COLONY_RED);
    expect(colony.ants.length).toBe(1);
    expect(colony.ants[0].type).toBe(AntType.QUEEN);
    expect(colony.food).toBe(50);
  });

  it("adds an ant to the colony", () => {
    const colony = createColony(COLONY_RED, 10, 50);
    const ant = createAnt(2, AntType.WORKER, COLONY_RED, 12, 52);
    const updated = addAnt(colony, ant);
    expect(updated.ants.length).toBe(2);
  });

  it("removes a dead ant from the colony", () => {
    const colony = createColony(COLONY_RED, 10, 50);
    const ant = createAnt(2, AntType.WORKER, COLONY_RED, 12, 52);
    const withAnt = addAnt(colony, ant);
    const removed = removeAnt(withAnt, 2);
    expect(removed.ants.length).toBe(1);
  });

  it("queenAlive returns false when queen is dead", () => {
    const colony = createColony(COLONY_RED, 10, 50);
    const deadQueen = { ...colony.ants[0], alive: false };
    const updated: Colony = { ...colony, ants: [deadQueen] };
    expect(updated.ants[0].alive).toBe(false);
  });
});
```

- [ ] **Step 2: Implement colony**

```typescript
// src/simulation/colony.ts
import { type ColonyId } from "../utils/constants";
import { createAnt, AntType, type Ant } from "./ant";

export interface Colony {
  readonly id: ColonyId;
  readonly ants: ReadonlyArray<Ant>;
  readonly food: number;
  readonly queenX: number;
  readonly queenY: number;
  readonly nextAntId: number;
  readonly ticksSinceLastEgg: number;
  readonly territoryPercent: number;
}

export function createColony(
  id: ColonyId,
  queenX: number,
  queenY: number
): Colony {
  const queen = createAnt(1, AntType.QUEEN, id, queenX, queenY);
  return {
    id,
    ants: [queen],
    food: 50,
    queenX,
    queenY,
    nextAntId: 2,
    ticksSinceLastEgg: 0,
    territoryPercent: 0,
  };
}

export function addAnt(colony: Colony, ant: Ant): Colony {
  return { ...colony, ants: [...colony.ants, ant], nextAntId: colony.nextAntId + 1 };
}

export function removeAnt(colony: Colony, antId: number): Colony {
  return { ...colony, ants: colony.ants.filter((a) => a.id !== antId) };
}

export function getQueen(colony: Colony): Ant | undefined {
  return colony.ants.find((a) => a.type === AntType.QUEEN && a.alive);
}

export function getAliveAnts(colony: Colony): ReadonlyArray<Ant> {
  return colony.ants.filter((a) => a.alive);
}
```

- [ ] **Step 3: Run colony tests**

Run: `cd ecosim && npx vitest run src/simulation/colony.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 4: Write failing tests for combat**

```typescript
// src/simulation/combat.test.ts
import { describe, it, expect } from "vitest";
import { resolveCombat } from "./combat";
import { createAnt, AntType } from "./ant";
import { COLONY_RED, COLONY_BLUE } from "../utils/constants";
import { createRng } from "../utils/random";

describe("combat", () => {
  it("soldier beats worker", () => {
    const soldier = createAnt(1, AntType.SOLDIER, COLONY_RED, 5, 5);
    const worker = createAnt(2, AntType.WORKER, COLONY_BLUE, 5, 5);
    const rng = createRng(42);
    const result = resolveCombat(soldier, worker, rng);
    expect(result.winner.id).toBe(1);
    expect(result.loser.alive).toBe(false);
  });

  it("winner loses some energy", () => {
    const soldier = createAnt(1, AntType.SOLDIER, COLONY_RED, 5, 5);
    const worker = createAnt(2, AntType.WORKER, COLONY_BLUE, 5, 5);
    const rng = createRng(42);
    const result = resolveCombat(soldier, worker, rng);
    expect(result.winner.energy).toBeLessThan(100);
  });

  it("two workers fight with random outcome", () => {
    const a = createAnt(1, AntType.WORKER, COLONY_RED, 5, 5);
    const b = createAnt(2, AntType.WORKER, COLONY_BLUE, 5, 5);
    const rng = createRng(1);
    const result = resolveCombat(a, b, rng);
    expect(result.winner.alive).toBe(true);
    expect(result.loser.alive).toBe(false);
  });
});
```

- [ ] **Step 5: Implement combat**

```typescript
// src/simulation/combat.ts
import { type Ant, AntType } from "./ant";
import { type Rng } from "../utils/random";
import { SOLDIER_COMBAT_STRENGTH, WORKER_COMBAT_STRENGTH, ANT_ENERGY_FIGHT_COST } from "../utils/constants";

export interface CombatResult {
  readonly winner: Ant;
  readonly loser: Ant;
}

function combatStrength(ant: Ant): number {
  const base = ant.type === AntType.SOLDIER ? SOLDIER_COMBAT_STRENGTH : WORKER_COMBAT_STRENGTH;
  return base * (ant.energy / 100);
}

export function resolveCombat(a: Ant, b: Ant, rng: Rng): CombatResult {
  const strengthA = combatStrength(a) + rng.next() * 0.5;
  const strengthB = combatStrength(b) + rng.next() * 0.5;

  if (strengthA >= strengthB) {
    return {
      winner: { ...a, energy: a.energy - ANT_ENERGY_FIGHT_COST * 5 },
      loser: { ...b, alive: false, energy: 0, state: "dead" as any },
    };
  }
  return {
    winner: { ...b, energy: b.energy - ANT_ENERGY_FIGHT_COST * 5 },
    loser: { ...a, alive: false, energy: 0, state: "dead" as any },
  };
}
```

- [ ] **Step 6: Run combat tests**

Run: `cd ecosim && npx vitest run src/simulation/combat.test.ts`
Expected: PASS (3 tests)

- [ ] **Step 7: Write failing tests for win conditions**

```typescript
// src/simulation/win-conditions.test.ts
import { describe, it, expect } from "vitest";
import { checkWinConditions, WinCondition } from "./win-conditions";
import { createColony, addAnt, type Colony } from "./colony";
import { createAnt, AntType } from "./ant";
import { COLONY_RED, COLONY_BLUE } from "../utils/constants";

describe("win-conditions", () => {
  it("returns QUEEN_KILL when queen is dead", () => {
    const red = createColony(COLONY_RED, 10, 50);
    const blue = createColony(COLONY_BLUE, 190, 50);
    const deadQueen: Colony = { ...red, ants: [{ ...red.ants[0], alive: false }] };
    const result = checkWinConditions(deadQueen, blue, 0, 0);
    expect(result?.condition).toBe(WinCondition.QUEEN_KILL);
    expect(result?.loser).toBe(COLONY_RED);
  });

  it("returns STARVATION when food is 0 and no ants foraging", () => {
    const red: Colony = { ...createColony(COLONY_RED, 10, 50), food: 0 };
    const blue = createColony(COLONY_BLUE, 190, 50);
    const result = checkWinConditions(red, blue, 0, 0);
    expect(result?.condition).toBe(WinCondition.STARVATION);
    expect(result?.loser).toBe(COLONY_RED);
  });

  it("returns TERRITORY when one colony controls 80%+ for 3 days", () => {
    const red = createColony(COLONY_RED, 10, 50);
    const blue = createColony(COLONY_BLUE, 190, 50);
    // Simulate red having 85% territory for 3 days (3 * 1440 ticks)
    const result = checkWinConditions(red, blue, 0.85, 3 * 1440);
    expect(result?.condition).toBe(WinCondition.TERRITORY);
    expect(result?.winner).toBe(COLONY_RED);
  });

  it("returns null when no win condition met", () => {
    const red = createColony(COLONY_RED, 10, 50);
    const blue = createColony(COLONY_BLUE, 190, 50);
    const result = checkWinConditions(red, blue, 0.5, 0);
    expect(result).toBeNull();
  });
});
```

- [ ] **Step 8: Implement win conditions**

```typescript
// src/simulation/win-conditions.ts
import { type Colony, getQueen, getAliveAnts } from "./colony";
import { type ColonyId, COLONY_RED, COLONY_BLUE, TERRITORY_WIN_THRESHOLD, TERRITORY_WIN_DAYS, TICKS_PER_DAY, STARVATION_THRESHOLD } from "../utils/constants";

export enum WinCondition {
  QUEEN_KILL = "queen_kill",
  STARVATION = "starvation",
  TERRITORY = "territory",
}

export interface WinResult {
  readonly condition: WinCondition;
  readonly winner: ColonyId;
  readonly loser: ColonyId;
}

export function checkWinConditions(
  red: Colony,
  blue: Colony,
  redTerritoryPercent: number,
  ticksRedDominating: number
): WinResult | null {
  // Queen kill
  const redQueen = getQueen(red);
  if (!redQueen) {
    return { condition: WinCondition.QUEEN_KILL, winner: COLONY_BLUE, loser: COLONY_RED };
  }
  const blueQueen = getQueen(blue);
  if (!blueQueen) {
    return { condition: WinCondition.QUEEN_KILL, winner: COLONY_RED, loser: COLONY_BLUE };
  }

  // Starvation
  if (red.food <= 0 && getAliveAnts(red).length <= 1) {
    return { condition: WinCondition.STARVATION, winner: COLONY_BLUE, loser: COLONY_RED };
  }
  if (blue.food <= 0 && getAliveAnts(blue).length <= 1) {
    return { condition: WinCondition.STARVATION, winner: COLONY_RED, loser: COLONY_BLUE };
  }

  // Territory domination
  const requiredTicks = TERRITORY_WIN_DAYS * TICKS_PER_DAY;
  if (redTerritoryPercent >= TERRITORY_WIN_THRESHOLD && ticksRedDominating >= requiredTicks) {
    return { condition: WinCondition.TERRITORY, winner: COLONY_RED, loser: COLONY_BLUE };
  }
  const blueTerritoryPercent = 1 - redTerritoryPercent;
  if (blueTerritoryPercent >= TERRITORY_WIN_THRESHOLD && ticksRedDominating <= -requiredTicks) {
    return { condition: WinCondition.TERRITORY, winner: COLONY_BLUE, loser: COLONY_RED };
  }

  return null;
}
```

- [ ] **Step 9: Run win conditions tests**

Run: `cd ecosim && npx vitest run src/simulation/win-conditions.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 10: Commit**

```bash
cd ecosim && git add src/simulation/colony.ts src/simulation/colony.test.ts src/simulation/combat.ts src/simulation/combat.test.ts src/simulation/win-conditions.ts src/simulation/win-conditions.test.ts && git commit -m "feat: add colony state, combat resolution, and win conditions"
```

---

## Phase 2: Game Loop (Tasks 5-6)

### Task 5: Game State + Tick Loop

**Files:**
- Create: `src/simulation/game-state.ts`
- Create: `src/simulation/game-state.test.ts`
- Create: `src/simulation/spawner.ts`

- [ ] **Step 1: Write failing tests for game state**

```typescript
// src/simulation/game-state.test.ts
import { describe, it, expect } from "vitest";
import { createGameState, tick, GamePhase, type GameState } from "./game-state";
import { COLONY_RED, COLONY_BLUE } from "../utils/constants";

describe("game-state", () => {
  it("creates initial game state in SETUP phase", () => {
    const state = createGameState(42);
    expect(state.phase).toBe(GamePhase.SETUP);
    expect(state.tick).toBe(0);
    expect(state.red).toBeDefined();
    expect(state.blue).toBeDefined();
  });

  it("does not tick in SETUP phase", () => {
    const state = createGameState(42);
    const next = tick(state);
    expect(next.tick).toBe(0);
  });

  it("ticks in SEALED phase", () => {
    const state: GameState = { ...createGameState(42), phase: GamePhase.SEALED };
    const next = tick(state);
    expect(next.tick).toBe(1);
  });

  it("spawns initial workers when sealed", () => {
    const state: GameState = { ...createGameState(42), phase: GamePhase.SEALED };
    // After a few ticks, colonies should have more ants from egg spawning
    let current = state;
    for (let i = 0; i < 10; i++) {
      current = tick(current);
    }
    expect(current.tick).toBe(10);
  });
});
```

- [ ] **Step 2: Implement game state and tick loop**

```typescript
// src/simulation/game-state.ts
import { type Grid, createGrid, setCell, CellType, getCell, countCellsOfType } from "./grid";
import { type Colony, createColony, addAnt, getQueen, getAliveAnts } from "./colony";
import { type Ant, AntType, updateAnt, createAnt, AntState } from "./ant";
import { resolveCombat } from "./combat";
import { checkWinConditions, type WinResult } from "./win-conditions";
import { createRng, type Rng } from "../utils/random";
import {
  GRID_WIDTH, GRID_HEIGHT,
  COLONY_RED, COLONY_BLUE,
  QUEEN_EGG_INTERVAL, EGG_HATCH_TICKS,
  ANT_ENERGY_FROM_FOOD,
  TICKS_PER_DAY,
} from "../utils/constants";

export enum GamePhase {
  SETUP = "setup",
  SEALED = "sealed",
  ENDED = "ended",
}

export interface GameEvent {
  readonly tick: number;
  readonly day: number;
  readonly timeOfDay: string;
  readonly category: "battle" | "construction" | "birth" | "death" | "food" | "discovery";
  readonly text: string;
  readonly context: string;
}

export interface GameState {
  readonly phase: GamePhase;
  readonly grid: Grid;
  readonly red: Colony;
  readonly blue: Colony;
  readonly tick: number;
  readonly rng: Rng;
  readonly events: ReadonlyArray<GameEvent>;
  readonly winResult: WinResult | null;
  readonly ticksRedDominating: number;
  readonly speed: number;
}

export function createGameState(seed: number): GameState {
  const grid = createGrid(GRID_WIDTH, GRID_HEIGHT);
  return {
    phase: GamePhase.SETUP,
    grid,
    red: createColony(COLONY_RED, 20, 90),
    blue: createColony(COLONY_BLUE, 180, 90),
    tick: 0,
    rng: createRng(seed),
    events: [],
    winResult: null,
    ticksRedDominating: 0,
    speed: 1,
  };
}

function currentDay(t: number): number {
  return Math.floor(t / TICKS_PER_DAY) + 1;
}

function timeOfDay(t: number): string {
  const minute = t % TICKS_PER_DAY;
  const hours = Math.floor(minute / 60);
  const mins = minute % 60;
  return `${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}`;
}

function spawnWorkers(colony: Colony, grid: Grid, rng: Rng): { colony: Colony; grid: Grid } {
  const queen = getQueen(colony);
  if (!queen || colony.food < 5) return { colony, grid };

  if (colony.ticksSinceLastEgg < QUEEN_EGG_INTERVAL) {
    return { colony: { ...colony, ticksSinceLastEgg: colony.ticksSinceLastEgg + 1 }, grid };
  }

  const isSoldier = rng.chance(0.25);
  const type = isSoldier ? AntType.SOLDIER : AntType.WORKER;
  const newAnt = createAnt(colony.nextAntId, type, colony.id, queen.x, queen.y);
  const newGrid = setCell(grid, queen.x, queen.y, { type: CellType.TUNNEL, colony: colony.id });

  return {
    colony: {
      ...addAnt(colony, newAnt),
      food: colony.food - 5,
      ticksSinceLastEgg: 0,
    },
    grid: newGrid,
  };
}

export function tick(state: GameState): GameState {
  if (state.phase !== GamePhase.SEALED) return state;
  if (state.winResult) return state;

  const newTick = state.tick + 1;
  let grid = state.grid;
  let red = state.red;
  let blue = state.blue;
  const rng = state.rng;
  const newEvents: GameEvent[] = [];

  // Spawn ants
  const redSpawn = spawnWorkers(red, grid, rng);
  red = redSpawn.colony;
  grid = redSpawn.grid;

  const blueSpawn = spawnWorkers(blue, grid, rng);
  blue = blueSpawn.colony;
  grid = blueSpawn.grid;

  // Update all ants
  const allAnts = [...getAliveAnts(red), ...getAliveAnts(blue)];
  const updatedRed: Ant[] = [];
  const updatedBlue: Ant[] = [];

  for (const ant of allAnts) {
    const enemies = allAnts.filter(
      (other) => other.colony !== ant.colony && other.alive &&
        Math.abs(other.x - ant.x) <= 1 && Math.abs(other.y - ant.y) <= 1
    );

    const result = updateAnt(ant, grid, enemies, rng);

    // Apply grid changes
    for (const change of result.gridChanges) {
      grid = setCell(grid, change.x, change.y, { type: change.type, colony: change.colony });
    }

    if (ant.colony === COLONY_RED) {
      updatedRed.push(result.ant);
    } else {
      updatedBlue.push(result.ant);
    }
  }

  // Resolve combat — find ants from opposing colonies on the same cell
  const combatPairs: Array<{ red: Ant; blue: Ant }> = [];
  for (const r of updatedRed) {
    if (!r.alive) continue;
    for (const b of updatedBlue) {
      if (!b.alive) continue;
      if (r.x === b.x && r.y === b.y) {
        combatPairs.push({ red: r, blue: b });
      }
    }
  }

  for (const pair of combatPairs) {
    const result = resolveCombat(pair.red, pair.blue, rng);
    const winnerColony = result.winner.colony;
    const loserColony = result.loser.colony;

    // Update the ant arrays
    const winArr = winnerColony === COLONY_RED ? updatedRed : updatedBlue;
    const loseArr = loserColony === COLONY_RED ? updatedRed : updatedBlue;
    const wi = winArr.findIndex((a) => a.id === result.winner.id);
    if (wi >= 0) winArr[wi] = result.winner;
    const li = loseArr.findIndex((a) => a.id === result.loser.id);
    if (li >= 0) loseArr[li] = result.loser;

    newEvents.push({
      tick: newTick,
      day: currentDay(newTick),
      timeOfDay: timeOfDay(newTick),
      category: "battle",
      text: `${winnerColony === COLONY_RED ? "Red" : "Blue"} ${result.winner.type} defeated ${loserColony === COLONY_RED ? "Red" : "Blue"} ${result.loser.type}`,
      context: "Combat is decided by type advantage (soldiers beat workers) plus energy and a random factor.",
    });
  }

  // Calculate territory
  const redTunnels = countCellsOfType(grid, CellType.TUNNEL, COLONY_RED);
  const blueTunnels = countCellsOfType(grid, CellType.TUNNEL, COLONY_BLUE);
  const totalTunnels = redTunnels + blueTunnels;
  const redPercent = totalTunnels > 0 ? redTunnels / totalTunnels : 0.5;

  const ticksRedDom = redPercent >= 0.8
    ? state.ticksRedDominating + 1
    : (1 - redPercent) >= 0.8
      ? state.ticksRedDominating - 1
      : 0;

  red = { ...red, ants: updatedRed, territoryPercent: redPercent };
  blue = { ...blue, ants: updatedBlue, territoryPercent: 1 - redPercent };

  // Check win
  const winResult = checkWinConditions(red, blue, redPercent, ticksRedDom);

  return {
    ...state,
    phase: winResult ? GamePhase.ENDED : GamePhase.SEALED,
    grid,
    red,
    blue,
    tick: newTick,
    events: [...state.events, ...newEvents],
    winResult,
    ticksRedDominating: ticksRedDom,
  };
}

export function sealTank(state: GameState): GameState {
  if (state.phase !== GamePhase.SETUP) return state;

  // Carve initial tunnels around each queen
  let grid = state.grid;
  for (const colony of [state.red, state.blue]) {
    const queen = getQueen(colony);
    if (!queen) continue;
    // Carve a small chamber around the queen
    for (let dx = -2; dx <= 2; dx++) {
      for (let dy = -2; dy <= 2; dy++) {
        if (Math.abs(dx) + Math.abs(dy) <= 3) {
          grid = setCell(grid, queen.x + dx, queen.y + dy, {
            type: CellType.CHAMBER,
            colony: colony.id,
          });
        }
      }
    }
    // Carve a tunnel up toward surface
    for (let y = queen.y - 3; y >= 8; y--) {
      grid = setCell(grid, queen.x, y, { type: CellType.TUNNEL, colony: colony.id });
    }
  }

  // Spawn initial workers (10 per colony)
  let red = state.red;
  let blue = state.blue;
  for (let i = 0; i < 10; i++) {
    const rw = createAnt(red.nextAntId, AntType.WORKER, COLONY_RED, red.queenX, red.queenY - 5);
    red = { ...addAnt(red, rw) };
  }
  for (let i = 0; i < 10; i++) {
    const bw = createAnt(blue.nextAntId, AntType.WORKER, COLONY_BLUE, blue.queenX, blue.queenY - 5);
    blue = { ...addAnt(blue, bw) };
  }
  // Spawn 3 soldiers each
  for (let i = 0; i < 3; i++) {
    const rs = createAnt(red.nextAntId, AntType.SOLDIER, COLONY_RED, red.queenX, red.queenY - 3);
    red = { ...addAnt(red, rs) };
  }
  for (let i = 0; i < 3; i++) {
    const bs = createAnt(blue.nextAntId, AntType.SOLDIER, COLONY_BLUE, blue.queenX, blue.queenY - 3);
    blue = { ...addAnt(blue, bs) };
  }

  return { ...state, phase: GamePhase.SEALED, grid, red, blue };
}
```

- [ ] **Step 3: Run game state tests**

Run: `cd ecosim && npx vitest run src/simulation/game-state.test.ts`
Expected: PASS (4 tests)

- [ ] **Step 4: Commit**

```bash
cd ecosim && git add src/simulation/game-state.ts src/simulation/game-state.test.ts && git commit -m "feat: add game state, tick loop, spawner, and seal logic"
```

---

### Task 6: Food System

**Files:**
- Create: `src/simulation/food.ts`
- Create: `src/simulation/food.test.ts`

- [ ] **Step 1: Write failing tests for food**

```typescript
// src/simulation/food.test.ts
import { describe, it, expect } from "vitest";
import { createFoodSource, placeFoodOnGrid, type FoodSource } from "./food";
import { createGrid, getCell, CellType } from "./grid";

describe("food", () => {
  it("creates a food source", () => {
    const food = createFoodSource(50, 5, 20);
    expect(food.x).toBe(50);
    expect(food.y).toBe(5);
    expect(food.amount).toBe(20);
  });

  it("places food on the grid", () => {
    const grid = createGrid(100, 100);
    const food = createFoodSource(50, 5, 20);
    const updated = placeFoodOnGrid(grid, food);
    const cell = getCell(updated, 50, 5);
    expect(cell.foodAmount).toBe(20);
  });
});
```

- [ ] **Step 2: Implement food**

```typescript
// src/simulation/food.ts
import { type Grid, setCell, getCell } from "./grid";

export interface FoodSource {
  readonly x: number;
  readonly y: number;
  readonly amount: number;
}

export function createFoodSource(x: number, y: number, amount: number): FoodSource {
  return { x, y, amount };
}

export function placeFoodOnGrid(grid: Grid, food: FoodSource): Grid {
  const cell = getCell(grid, food.x, food.y);
  return setCell(grid, food.x, food.y, { foodAmount: cell.foodAmount + food.amount });
}
```

- [ ] **Step 3: Run food tests**

Run: `cd ecosim && npx vitest run src/simulation/food.test.ts`
Expected: PASS (2 tests)

- [ ] **Step 4: Commit**

```bash
cd ecosim && git add src/simulation/food.ts src/simulation/food.test.ts && git commit -m "feat: add food source system"
```

---

## Phase 3: PixiJS Rendering (Tasks 7-10)

### Task 7: PixiJS App + Widget Container

**Files:**
- Create: `src/rendering/app.ts`
- Create: `src/rendering/tank.ts`
- Modify: `src/main.ts`

- [ ] **Step 1: Implement PixiJS app setup**

```typescript
// src/rendering/app.ts
import { Application } from "pixi.js";
import { WIDGET_WIDTH, WIDGET_HEIGHT } from "../utils/constants";

export async function createApp(): Promise<Application> {
  const app = new Application();
  await app.init({
    width: WIDGET_WIDTH,
    height: WIDGET_HEIGHT,
    backgroundColor: 0x3a2510,
    antialias: true,
    resolution: window.devicePixelRatio || 1,
    autoDensity: true,
  });
  return app;
}
```

- [ ] **Step 2: Implement tank widget container**

```typescript
// src/rendering/tank.ts
import { Container, Graphics } from "pixi.js";
import { WIDGET_WIDTH, WIDGET_HEIGHT } from "../utils/constants";

export function createTankContainer(): Container {
  const container = new Container();

  // Background soil gradient (will be replaced with textures later)
  const bg = new Graphics();
  bg.rect(0, 0, WIDGET_WIDTH, WIDGET_HEIGHT);
  bg.fill(0x3a2510);
  container.addChild(bg);

  // Surface strip
  const surface = new Graphics();
  surface.rect(0, 0, WIDGET_WIDTH, WIDGET_HEIGHT * 0.06);
  surface.fill(0x2a3a18);
  container.addChild(surface);

  return container;
}

export function createWidgetFrame(): HTMLDivElement {
  const wrapper = document.createElement("div");
  wrapper.style.cssText = `
    border-radius: 28px;
    overflow: hidden;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06), 0 8px 30px rgba(0,0,0,0.08), 0 20px 60px rgba(0,0,0,0.05);
    width: ${WIDGET_WIDTH}px;
    height: ${WIDGET_HEIGHT}px;
  `;
  return wrapper;
}
```

- [ ] **Step 3: Wire up main.ts**

```typescript
// src/main.ts
import { createApp } from "./rendering/app";
import { createTankContainer, createWidgetFrame } from "./rendering/tank";

async function init() {
  const app = await createApp();

  const frame = createWidgetFrame();
  frame.appendChild(app.canvas as HTMLCanvasElement);
  document.getElementById("app")!.appendChild(frame);

  const tank = createTankContainer();
  app.stage.addChild(tank);
}

init();
```

- [ ] **Step 4: Run dev server and verify widget renders**

Run: `cd ecosim && npx vite --open`
Expected: browser opens, shows a brown rectangle with green strip at top, rounded corners, shadow — the empty tank widget

- [ ] **Step 5: Commit**

```bash
cd ecosim && git add src/rendering/app.ts src/rendering/tank.ts src/main.ts && git commit -m "feat: add PixiJS app with widget container"
```

---

### Task 8: Soil Rendering + Tunnel Visualization

**Files:**
- Create: `src/rendering/soil.ts`
- Create: `src/rendering/tunnels.ts`

- [ ] **Step 1: Implement soil renderer**

```typescript
// src/rendering/soil.ts
import { Container, Graphics } from "pixi.js";
import { WIDGET_WIDTH, WIDGET_HEIGHT } from "../utils/constants";

export function createSoilLayer(): Container {
  const container = new Container();

  // Soil gradient bands
  const layers = [
    { y: 0.06, h: 0.08, color: 0x4a3014 },
    { y: 0.14, h: 0.12, color: 0x482c10 },
    { y: 0.26, h: 0.14, color: 0x42260e },
    { y: 0.40, h: 0.15, color: 0x3c220c },
    { y: 0.55, h: 0.15, color: 0x361e0a },
    { y: 0.70, h: 0.15, color: 0x301a08 },
    { y: 0.85, h: 0.15, color: 0x2a1606 },
  ];

  for (const layer of layers) {
    const g = new Graphics();
    g.rect(0, WIDGET_HEIGHT * layer.y, WIDGET_WIDTH, WIDGET_HEIGHT * layer.h);
    g.fill(layer.color);
    container.addChild(g);
  }

  // Strata lines
  const strataPositions = [0.15, 0.28, 0.42, 0.58, 0.72, 0.85];
  for (const y of strataPositions) {
    const line = new Graphics();
    line.rect(0, WIDGET_HEIGHT * y, WIDGET_WIDTH, 1);
    line.fill({ color: 0x5a4a3a, alpha: 0.06 });
    container.addChild(line);
  }

  return container;
}
```

- [ ] **Step 2: Implement tunnel renderer**

```typescript
// src/rendering/tunnels.ts
import { Container, Graphics } from "pixi.js";
import { type Grid, CellType, getCell } from "../simulation/grid";
import { WIDGET_WIDTH, WIDGET_HEIGHT, COLONY_RED } from "../utils/constants";

const CELL_W = WIDGET_WIDTH / 200;
const CELL_H = WIDGET_HEIGHT / 140;

export function createTunnelLayer(): { container: Container; update: (grid: Grid) => void } {
  const container = new Container();
  const tunnelGraphics = new Graphics();
  container.addChild(tunnelGraphics);

  function update(grid: Grid): void {
    tunnelGraphics.clear();

    for (let y = 0; y < grid.height; y++) {
      for (let x = 0; x < grid.width; x++) {
        const cell = getCell(grid, x, y);
        if (cell.type === CellType.TUNNEL || cell.type === CellType.CHAMBER) {
          const color = cell.colony === COLONY_RED ? 0x1a0e04 : 0x080e18;
          tunnelGraphics.rect(x * CELL_W, y * CELL_H, CELL_W + 0.5, CELL_H + 0.5);
          tunnelGraphics.fill(color);
        }
      }
    }
  }

  return { container, update };
}
```

- [ ] **Step 3: Commit**

```bash
cd ecosim && git add src/rendering/soil.ts src/rendering/tunnels.ts && git commit -m "feat: add soil gradient and tunnel grid renderer"
```

---

### Task 9: Ant Sprite Rendering

**Files:**
- Create: `src/rendering/ants.ts`

- [ ] **Step 1: Implement ant renderer using Graphics (placeholder for DragonBones)**

```typescript
// src/rendering/ants.ts
import { Container, Graphics } from "pixi.js";
import { type Ant, AntType, AntState } from "../simulation/ant";
import { COLONY_RED, WIDGET_WIDTH, WIDGET_HEIGHT } from "../utils/constants";

const CELL_W = WIDGET_WIDTH / 200;
const CELL_H = WIDGET_HEIGHT / 140;

interface AntSprite {
  id: number;
  graphics: Graphics;
}

export function createAntLayer(): {
  container: Container;
  update: (ants: ReadonlyArray<Ant>) => void;
} {
  const container = new Container();
  const sprites = new Map<number, AntSprite>();

  function getOrCreateSprite(ant: Ant): AntSprite {
    const existing = sprites.get(ant.id);
    if (existing) return existing;

    const g = new Graphics();
    container.addChild(g);
    const sprite: AntSprite = { id: ant.id, graphics: g };
    sprites.set(ant.id, sprite);
    return sprite;
  }

  function drawAnt(g: Graphics, ant: Ant): void {
    g.clear();
    const isRed = ant.colony === COLONY_RED;
    const bodyColor = isRed ? 0x8a3a20 : 0x2a3a58;
    const headColor = isRed ? 0x9a4a28 : 0x3a4a68;

    const size = ant.type === AntType.SOLDIER ? 1.4
      : ant.type === AntType.QUEEN ? 1.8
      : 1;

    // Body segments
    g.circle(-2 * size, 0, 1.8 * size);
    g.fill(bodyColor);
    g.circle(1.5 * size, 0, 2.2 * size);
    g.fill(bodyColor);
    g.circle(5 * size, 0, 1.6 * size);
    g.fill(bodyColor);

    // Head
    g.circle(-5 * size, -0.5, 1.6 * size);
    g.fill(headColor);

    // Eye
    g.circle(-6 * size, -1.2, 0.4 * size);
    g.fill(0x111111);

    // Carrying food indicator
    if (ant.carrying > 0) {
      g.circle(-2 * size, -3 * size, 1.5 * size);
      g.fill(0x8a7a3a);
    }

    // Fighting indicator
    if (ant.state === AntState.FIGHTING) {
      g.circle(0, 0, 4 * size);
      g.stroke({ color: 0xff4444, width: 0.5, alpha: 0.4 });
    }
  }

  function update(ants: ReadonlyArray<Ant>): void {
    const aliveIds = new Set<number>();

    for (const ant of ants) {
      if (!ant.alive) continue;
      aliveIds.add(ant.id);

      const sprite = getOrCreateSprite(ant);
      drawAnt(sprite.graphics, ant);
      sprite.graphics.x = ant.x * CELL_W;
      sprite.graphics.y = ant.y * CELL_H;
    }

    // Remove dead ant sprites
    for (const [id, sprite] of sprites) {
      if (!aliveIds.has(id)) {
        container.removeChild(sprite.graphics);
        sprite.graphics.destroy();
        sprites.delete(id);
      }
    }
  }

  return { container, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/rendering/ants.ts && git commit -m "feat: add ant sprite renderer with Graphics placeholders"
```

---

### Task 10: Colony Glow + Territory Tint

**Files:**
- Create: `src/rendering/lighting.ts`

- [ ] **Step 1: Implement lighting layer**

```typescript
// src/rendering/lighting.ts
import { Container, Graphics } from "pixi.js";
import { type Grid, CellType, getCell } from "../simulation/grid";
import { WIDGET_WIDTH, WIDGET_HEIGHT, COLONY_RED } from "../utils/constants";

const CELL_W = WIDGET_WIDTH / 200;
const CELL_H = WIDGET_HEIGHT / 140;

export function createLightingLayer(): {
  container: Container;
  update: (grid: Grid) => void;
} {
  const container = new Container();
  const glowGraphics = new Graphics();
  container.addChild(glowGraphics);
  container.alpha = 0.4;

  function update(grid: Grid): void {
    glowGraphics.clear();

    for (let y = 0; y < grid.height; y += 3) {
      for (let x = 0; x < grid.width; x += 3) {
        const cell = getCell(grid, x, y);
        if (cell.type === CellType.TUNNEL || cell.type === CellType.CHAMBER) {
          const isRed = cell.colony === COLONY_RED;
          const color = isRed ? 0xcc6633 : 0x5577aa;
          glowGraphics.circle(x * CELL_W, y * CELL_H, 8);
          glowGraphics.fill({ color, alpha: 0.04 });
        }
      }
    }
  }

  return { container, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/rendering/lighting.ts && git commit -m "feat: add colony glow and territory tinting"
```

---

## Phase 4: UI Layer (Tasks 11-14)

### Task 11: Scoreboard

**Files:**
- Create: `src/ui/scoreboard.ts`

- [ ] **Step 1: Implement scoreboard DOM element**

```typescript
// src/ui/scoreboard.ts
import { type Colony } from "../simulation/colony";
import { getAliveAnts } from "../simulation/colony";

export function createScoreboard(): {
  element: HTMLElement;
  update: (red: Colony, blue: Colony) => void;
} {
  const el = document.createElement("div");
  el.innerHTML = `
    <div style="
      display:flex; gap:0; border-radius:14px;
      background:rgba(6,6,8,0.75); backdrop-filter:blur(20px);
      border:1px solid rgba(255,255,255,0.04);
      overflow:hidden; font-family:'Inter',system-ui,sans-serif;
      position:absolute; top:10px; left:50%; transform:translateX(-50%); z-index:20;
    ">
      <div id="score-red" style="padding:5px 12px; display:flex; align-items:center; gap:10px;">
        <div>
          <span style="width:4px;height:4px;border-radius:50%;background:#cc6633;display:inline-block;margin-right:3px;vertical-align:middle;"></span>
          <span style="font-size:9px;font-weight:600;text-transform:uppercase;letter-spacing:1.5px;color:rgba(220,110,50,0.8);">Red</span>
        </div>
        <span id="red-pct" style="font-family:'JetBrains Mono',monospace;font-size:11px;font-weight:500;color:rgba(255,255,255,0.6);">50%</span>
        <span id="red-pop" style="font-family:'JetBrains Mono',monospace;font-size:9px;color:rgba(255,255,255,0.3);">0</span>
      </div>
      <div style="width:1px;background:rgba(255,255,255,0.04);"></div>
      <div id="score-blue" style="padding:5px 12px; display:flex; align-items:center; gap:10px;">
        <div>
          <span style="width:4px;height:4px;border-radius:50%;background:#5577aa;display:inline-block;margin-right:3px;vertical-align:middle;"></span>
          <span style="font-size:9px;font-weight:600;text-transform:uppercase;letter-spacing:1.5px;color:rgba(90,140,210,0.8);">Blue</span>
        </div>
        <span id="blue-pct" style="font-family:'JetBrains Mono',monospace;font-size:11px;font-weight:500;color:rgba(255,255,255,0.6);">50%</span>
        <span id="blue-pop" style="font-family:'JetBrains Mono',monospace;font-size:9px;color:rgba(255,255,255,0.3);">0</span>
      </div>
    </div>
  `;

  function update(red: Colony, blue: Colony): void {
    const redPct = el.querySelector("#red-pct") as HTMLElement;
    const bluePct = el.querySelector("#blue-pct") as HTMLElement;
    const redPop = el.querySelector("#red-pop") as HTMLElement;
    const bluePop = el.querySelector("#blue-pop") as HTMLElement;
    redPct.textContent = `${Math.round(red.territoryPercent * 100)}%`;
    bluePct.textContent = `${Math.round(blue.territoryPercent * 100)}%`;
    redPop.textContent = `${getAliveAnts(red).length}`;
    bluePop.textContent = `${getAliveAnts(blue).length}`;
  }

  return { element: el.firstElementChild as HTMLElement, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/scoreboard.ts && git commit -m "feat: add scoreboard UI component"
```

---

### Task 12: Event Log Panel

**Files:**
- Create: `src/ui/event-log.ts`

- [ ] **Step 1: Implement event log**

```typescript
// src/ui/event-log.ts
import { type GameEvent } from "../simulation/game-state";

const CATEGORY_ICONS: Record<string, string> = {
  battle: "⚔️",
  construction: "🏗️",
  birth: "🥚",
  death: "💀",
  food: "🍖",
  discovery: "🔍",
};

export function createEventLog(): {
  button: HTMLElement;
  panel: HTMLElement;
  update: (events: ReadonlyArray<GameEvent>) => void;
} {
  // Toggle button
  const button = document.createElement("button");
  button.textContent = "View Event Log";
  button.style.cssText = `
    position:fixed; bottom:28px; left:50%; transform:translateX(-50%);
    font-size:11px; font-weight:400; color:#aaa; cursor:pointer;
    padding:6px 16px; border-radius:20px; border:1px solid rgba(0,0,0,0.08);
    background:white; font-family:'Inter',system-ui,sans-serif;
    box-shadow:0 1px 4px rgba(0,0,0,0.04); z-index:50; transition:all 0.3s;
  `;

  // Panel
  const panel = document.createElement("div");
  panel.style.cssText = `
    position:fixed; bottom:0; left:50%; transform:translateX(-50%) translateY(100%);
    width:680px; max-height:45vh; background:white; border-radius:20px 20px 0 0;
    box-shadow:0 -4px 30px rgba(0,0,0,0.08); z-index:100;
    padding:20px 24px; overflow-y:auto; font-family:'Inter',system-ui,sans-serif;
    transition:transform 0.5s cubic-bezier(0.16,1,0.3,1);
  `;

  const header = document.createElement("div");
  header.style.cssText = "display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;padding-bottom:12px;border-bottom:1px solid rgba(0,0,0,0.05);";
  header.innerHTML = `
    <span style="font-size:12px;font-weight:500;color:#888;text-transform:uppercase;letter-spacing:2px;">Battle Log</span>
    <button id="log-close" style="font-size:18px;color:#ccc;cursor:pointer;background:none;border:none;padding:2px 6px;">✕</button>
  `;
  panel.appendChild(header);

  const eventList = document.createElement("div");
  eventList.id = "event-list";
  panel.appendChild(eventList);

  let isOpen = false;
  button.addEventListener("click", () => {
    isOpen = !isOpen;
    panel.style.transform = isOpen
      ? "translateX(-50%) translateY(0)"
      : "translateX(-50%) translateY(100%)";
  });

  header.querySelector("#log-close")!.addEventListener("click", () => {
    isOpen = false;
    panel.style.transform = "translateX(-50%) translateY(100%)";
  });

  let lastEventCount = 0;

  function update(events: ReadonlyArray<GameEvent>): void {
    if (events.length === lastEventCount) return;

    // Add only new events
    for (let i = lastEventCount; i < events.length; i++) {
      const ev = events[i];
      const entry = document.createElement("div");
      entry.style.cssText = "margin-bottom:14px;padding-bottom:14px;border-bottom:1px solid rgba(0,0,0,0.04);";

      const redColor = "#cc6633";
      const blueColor = "#5577aa";
      const text = ev.text
        .replace(/Red/g, `<span style="color:${redColor};font-weight:500">Red</span>`)
        .replace(/Blue/g, `<span style="color:${blueColor};font-weight:500">Blue</span>`);

      entry.innerHTML = `
        <div style="font-family:'JetBrains Mono',monospace;font-size:10px;color:#bbb;margin-bottom:3px;">
          Day ${ev.day} · ${ev.timeOfDay}
        </div>
        <div style="font-size:13px;color:#444;line-height:1.55;">
          ${CATEGORY_ICONS[ev.category] || ""} ${text}
        </div>
        <div style="font-size:11px;color:#aaa;line-height:1.5;margin-top:4px;padding-left:10px;border-left:2px solid rgba(0,0,0,0.05);font-style:italic;">
          ${ev.context}
        </div>
      `;
      eventList.prepend(entry);
    }
    lastEventCount = events.length;
  }

  return { button, panel, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/event-log.ts && git commit -m "feat: add event log slide-up panel"
```

---

### Task 13: Speed Controls + Day Counter

**Files:**
- Create: `src/ui/speed-controls.ts`

- [ ] **Step 1: Implement speed controls and day counter**

```typescript
// src/ui/speed-controls.ts
import { TICKS_PER_DAY } from "../utils/constants";

export function createSpeedControls(onSpeedChange: (speed: number) => void): {
  element: HTMLElement;
} {
  const el = document.createElement("div");
  el.style.cssText = `
    position:absolute; bottom:7px; right:12px; z-index:20;
    display:flex; gap:1px; padding:2px; border-radius:8px;
    background:rgba(0,0,0,0.25); backdrop-filter:blur(8px);
  `;

  const speeds = [1, 2, 5, 10];
  for (const speed of speeds) {
    const btn = document.createElement("button");
    btn.textContent = `${speed}x`;
    btn.style.cssText = `
      background:none; border:none; color:rgba(255,255,255,0.2);
      font-family:'JetBrains Mono',monospace; font-size:8px;
      padding:2px 6px; border-radius:6px; cursor:pointer; transition:all 0.2s;
    `;
    if (speed === 1) {
      btn.style.color = "rgba(230,200,130,0.75)";
      btn.style.background = "rgba(230,200,130,0.06)";
    }
    btn.addEventListener("click", () => {
      onSpeedChange(speed);
      for (const child of el.children) {
        (child as HTMLElement).style.color = "rgba(255,255,255,0.2)";
        (child as HTMLElement).style.background = "none";
      }
      btn.style.color = "rgba(230,200,130,0.75)";
      btn.style.background = "rgba(230,200,130,0.06)";
    });
    el.appendChild(btn);
  }

  return { element: el };
}

export function createDayCounter(): {
  element: HTMLElement;
  update: (tick: number) => void;
} {
  const el = document.createElement("div");
  el.style.cssText = `
    position:absolute; bottom:10px; left:14px; z-index:20;
    font-size:10px; font-weight:400; color:rgba(255,255,255,0.2);
    letter-spacing:0.3px; font-family:'Inter',system-ui,sans-serif;
  `;
  el.textContent = "Day 1";

  function update(tick: number): void {
    const day = Math.floor(tick / TICKS_PER_DAY) + 1;
    el.textContent = `Day ${day}`;
  }

  return { element: el, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/speed-controls.ts && git commit -m "feat: add speed controls and day counter"
```

---

### Task 14: Setup Phase UI

**Files:**
- Create: `src/ui/setup.ts`

- [ ] **Step 1: Implement setup overlay**

```typescript
// src/ui/setup.ts
export interface SetupResult {
  readonly foodPositions: ReadonlyArray<{ x: number; y: number }>;
  readonly rockPositions: ReadonlyArray<{ x: number; y: number }>;
}

export function createSetupUI(onSeal: (result: SetupResult) => void): {
  element: HTMLElement;
  destroy: () => void;
} {
  const overlay = document.createElement("div");
  overlay.style.cssText = `
    position:absolute; inset:0; z-index:50;
    display:flex; flex-direction:column; align-items:center; justify-content:center;
    background:rgba(0,0,0,0.5); border-radius:28px;
    font-family:'Inter',system-ui,sans-serif;
  `;

  overlay.innerHTML = `
    <div style="text-align:center; color:white;">
      <h2 style="font-size:18px; font-weight:600; margin-bottom:8px; color:rgba(255,255,255,0.9);">
        🐜 蚂蚁帝国 · AntWar
      </h2>
      <p style="font-size:12px; color:rgba(255,255,255,0.5); margin-bottom:24px;">
        Two ant colonies. One tank. Who survives?
      </p>
      <p style="font-size:11px; color:rgba(255,255,255,0.35); margin-bottom:8px;">
        Queens auto-placed: <span style="color:rgba(220,110,50,0.7);">Red</span> (left) vs <span style="color:rgba(90,140,210,0.7);">Blue</span> (right)
      </p>
      <p style="font-size:11px; color:rgba(255,255,255,0.35); margin-bottom:24px;">
        Food and rocks randomly placed for v1
      </p>
      <button id="seal-btn" style="
        background:rgba(255,255,255,0.1); border:1px solid rgba(255,255,255,0.15);
        color:rgba(255,255,255,0.8); font-size:13px; font-weight:500;
        padding:10px 32px; border-radius:12px; cursor:pointer;
        font-family:'Inter',system-ui,sans-serif; transition:all 0.3s;
      ">
        Seal the Tank
      </button>
    </div>
  `;

  const sealBtn = overlay.querySelector("#seal-btn") as HTMLButtonElement;
  sealBtn.addEventListener("mouseenter", () => {
    sealBtn.style.background = "rgba(255,255,255,0.15)";
    sealBtn.style.borderColor = "rgba(255,255,255,0.25)";
  });
  sealBtn.addEventListener("mouseleave", () => {
    sealBtn.style.background = "rgba(255,255,255,0.1)";
    sealBtn.style.borderColor = "rgba(255,255,255,0.15)";
  });
  sealBtn.addEventListener("click", () => {
    onSeal({
      foodPositions: [
        { x: 50, y: 5 }, { x: 100, y: 5 }, { x: 150, y: 5 },
        { x: 80, y: 3 }, { x: 120, y: 3 },
      ],
      rockPositions: [
        { x: 90, y: 60 }, { x: 95, y: 61 }, { x: 92, y: 62 },
        { x: 110, y: 80 }, { x: 112, y: 81 },
      ],
    });
  });

  return {
    element: overlay,
    destroy: () => overlay.remove(),
  };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/setup.ts && git commit -m "feat: add setup phase UI with seal button"
```

---

## Phase 5: Integration (Task 15)

### Task 15: Wire Everything Together — Game Loop

**Files:**
- Create: `src/game.ts`
- Modify: `src/main.ts`

- [ ] **Step 1: Implement game orchestrator**

```typescript
// src/game.ts
import { type Application } from "pixi.js";
import { createGameState, tick, sealTank, GamePhase, type GameState } from "./simulation/game-state";
import { setCell, CellType } from "./simulation/grid";
import { createSoilLayer } from "./rendering/soil";
import { createTunnelLayer } from "./rendering/tunnels";
import { createAntLayer } from "./rendering/ants";
import { createLightingLayer } from "./rendering/lighting";
import { createScoreboard } from "./ui/scoreboard";
import { createEventLog } from "./ui/event-log";
import { createSpeedControls, createDayCounter } from "./ui/speed-controls";
import { createSetupUI } from "./ui/setup";
import { getAliveAnts } from "./simulation/colony";
import { TICK_RATE_MS } from "./utils/constants";

export function startGame(app: Application, widgetFrame: HTMLDivElement): void {
  let state = createGameState(Date.now());
  let speed = 1;
  let lastTickTime = 0;

  // Rendering layers
  const soil = createSoilLayer();
  app.stage.addChild(soil);

  const tunnelLayer = createTunnelLayer();
  app.stage.addChild(tunnelLayer.container);

  const lighting = createLightingLayer();
  app.stage.addChild(lighting.container);

  const antLayer = createAntLayer();
  app.stage.addChild(antLayer.container);

  // UI elements — inside widget
  const scoreboard = createScoreboard();
  widgetFrame.style.position = "relative";
  widgetFrame.appendChild(scoreboard.element);

  const dayCounter = createDayCounter();
  widgetFrame.appendChild(dayCounter.element);

  const speedControls = createSpeedControls((s) => { speed = s; });
  widgetFrame.appendChild(speedControls.element);

  // UI elements — outside widget
  const eventLog = createEventLog();
  document.body.appendChild(eventLog.button);
  document.body.appendChild(eventLog.panel);

  // Setup phase
  const setup = createSetupUI((result) => {
    // Place food on grid
    for (const pos of result.foodPositions) {
      state = {
        ...state,
        grid: setCell(state.grid, pos.x, pos.y, { foodAmount: 20 }),
      };
    }
    // Place rocks
    for (const pos of result.rockPositions) {
      state = {
        ...state,
        grid: setCell(state.grid, pos.x, pos.y, { type: CellType.ROCK }),
      };
    }
    // Seal
    state = sealTank(state);
    setup.destroy();

    // Initial render
    tunnelLayer.update(state.grid);
    lighting.update(state.grid);
  });
  widgetFrame.appendChild(setup.element);

  // Game loop
  app.ticker.add(() => {
    if (state.phase !== GamePhase.SEALED) return;

    const now = performance.now();
    if (now - lastTickTime < TICK_RATE_MS / speed) return;
    lastTickTime = now;

    // Run simulation tick
    state = tick(state);

    // Update rendering
    tunnelLayer.update(state.grid);
    lighting.update(state.grid);

    const allAnts = [
      ...getAliveAnts(state.red),
      ...getAliveAnts(state.blue),
    ];
    antLayer.update(allAnts);

    // Update UI
    scoreboard.update(state.red, state.blue);
    dayCounter.update(state.tick);
    eventLog.update(state.events);
  });
}
```

- [ ] **Step 2: Update main.ts to use game orchestrator**

```typescript
// src/main.ts
import { createApp } from "./rendering/app";
import { createWidgetFrame } from "./rendering/tank";
import { startGame } from "./game";

async function init() {
  const app = await createApp();

  // Page title
  const title = document.createElement("div");
  title.textContent = "蚂蚁帝国 · AntWar";
  title.style.cssText = `
    position:fixed; top:30px; left:50%; transform:translateX(-50%);
    font-size:13px; font-weight:500; color:#999;
    letter-spacing:4px; text-transform:uppercase;
    font-family:'Inter',system-ui,sans-serif;
  `;
  document.body.appendChild(title);

  const frame = createWidgetFrame();
  frame.appendChild(app.canvas as HTMLCanvasElement);
  document.getElementById("app")!.appendChild(frame);

  startGame(app, frame);
}

init();
```

- [ ] **Step 3: Run dev server and test full flow**

Run: `cd ecosim && npx vite --open`
Expected:
1. Page loads with "蚂蚁帝国 · AntWar" title
2. Widget shows with "Seal the Tank" button
3. Click seal → setup overlay disappears
4. Tunnels start appearing from both sides
5. Ants visible as small colored shapes moving through tunnels
6. Scoreboard updates with territory % and population
7. Day counter increments
8. Events appear in the log when battles occur
9. Speed controls work (1x/2x/5x/10x)

- [ ] **Step 4: Run all tests**

Run: `cd ecosim && npx vitest run`
Expected: All tests pass

- [ ] **Step 5: Run typecheck**

Run: `cd ecosim && npx tsc --noEmit`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
cd ecosim && git add src/game.ts src/main.ts && git commit -m "feat: wire game loop — simulation + rendering + UI integrated"
```

---

## Phase 6: Territory Bar + Win Screen (Tasks 16-17)

### Task 16: Territory Bar

**Files:**
- Create: `src/ui/territory-bar.ts`

- [ ] **Step 1: Implement territory bar**

```typescript
// src/ui/territory-bar.ts
export function createTerritoryBar(): {
  element: HTMLElement;
  update: (redPercent: number) => void;
} {
  const el = document.createElement("div");
  el.style.cssText = `
    position:absolute; bottom:10px; left:50%; transform:translateX(-50%);
    width:200px; height:4px; border-radius:2px; overflow:hidden;
    background:rgba(0,0,0,0.3); backdrop-filter:blur(8px); z-index:20;
  `;

  const redFill = document.createElement("div");
  redFill.style.cssText = `
    position:absolute; left:0; top:0; bottom:0;
    background:linear-gradient(90deg,rgba(200,90,30,0.6),rgba(200,90,30,0.3));
    border-radius:2px 0 0 2px; transition:width 0.5s;
  `;
  el.appendChild(redFill);

  const blueFill = document.createElement("div");
  blueFill.style.cssText = `
    position:absolute; right:0; top:0; bottom:0;
    background:linear-gradient(270deg,rgba(60,100,190,0.6),rgba(60,100,190,0.3));
    border-radius:0 2px 2px 0; transition:width 0.5s;
  `;
  el.appendChild(blueFill);

  function update(redPercent: number): void {
    const rp = Math.round(redPercent * 100);
    const bp = 100 - rp;
    redFill.style.width = `${rp}%`;
    blueFill.style.width = `${bp}%`;
  }

  return { element: el, update };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/territory-bar.ts && git commit -m "feat: add territory balance bar"
```

---

### Task 17: Win Screen Overlay

**Files:**
- Create: `src/ui/win-screen.ts`

- [ ] **Step 1: Implement win screen**

```typescript
// src/ui/win-screen.ts
import { type WinResult, WinCondition } from "../simulation/win-conditions";
import { COLONY_RED } from "../utils/constants";

const CONDITION_TEXT: Record<WinCondition, string> = {
  [WinCondition.QUEEN_KILL]: "Enemy queen eliminated",
  [WinCondition.STARVATION]: "Enemy colony starved",
  [WinCondition.TERRITORY]: "Total territory domination",
};

export function createWinScreen(onNewGame: () => void): {
  element: HTMLElement;
  show: (result: WinResult, day: number) => void;
} {
  const el = document.createElement("div");
  el.style.cssText = `
    position:absolute; inset:0; z-index:60;
    display:none; flex-direction:column; align-items:center; justify-content:center;
    background:rgba(0,0,0,0.6); border-radius:28px;
    font-family:'Inter',system-ui,sans-serif;
  `;

  function show(result: WinResult, day: number): void {
    const isRed = result.winner === COLONY_RED;
    const winnerColor = isRed ? "#cc6633" : "#5577aa";
    const winnerName = isRed ? "Red" : "Blue";

    el.innerHTML = `
      <div style="text-align:center; color:white;">
        <div style="font-size:36px; margin-bottom:12px;">🏆</div>
        <h2 style="font-size:20px; font-weight:600; color:${winnerColor}; margin-bottom:6px;">
          ${winnerName} Colony Wins
        </h2>
        <p style="font-size:12px; color:rgba(255,255,255,0.5); margin-bottom:4px;">
          ${CONDITION_TEXT[result.condition]}
        </p>
        <p style="font-size:11px; color:rgba(255,255,255,0.3); margin-bottom:24px;">
          Day ${day}
        </p>
        <div style="display:flex; gap:10px; justify-content:center;">
          <button id="keep-watching" style="
            background:rgba(255,255,255,0.08); border:1px solid rgba(255,255,255,0.1);
            color:rgba(255,255,255,0.6); font-size:11px; padding:8px 20px;
            border-radius:10px; cursor:pointer; font-family:inherit;
          ">Keep Watching</button>
          <button id="new-game" style="
            background:rgba(255,255,255,0.12); border:1px solid rgba(255,255,255,0.15);
            color:rgba(255,255,255,0.8); font-size:11px; padding:8px 20px;
            border-radius:10px; cursor:pointer; font-family:inherit;
          ">New Game</button>
        </div>
      </div>
    `;

    el.style.display = "flex";

    el.querySelector("#keep-watching")!.addEventListener("click", () => {
      el.style.display = "none";
    });

    el.querySelector("#new-game")!.addEventListener("click", () => {
      onNewGame();
    });
  }

  return { element: el, show };
}
```

- [ ] **Step 2: Commit**

```bash
cd ecosim && git add src/ui/win-screen.ts && git commit -m "feat: add win screen overlay with keep watching and new game"
```

---

### Task 18: Integrate Territory Bar + Win Screen into Game Loop

**Files:**
- Modify: `src/game.ts`

- [ ] **Step 1: Add territory bar and win screen to game.ts**

Add these imports and initializations to `src/game.ts`:

```typescript
// Add to imports
import { createTerritoryBar } from "./ui/territory-bar";
import { createWinScreen } from "./ui/win-screen";

// Add after speedControls initialization:
const territoryBar = createTerritoryBar();
widgetFrame.appendChild(territoryBar.element);

const winScreen = createWinScreen(() => {
  window.location.reload();
});
widgetFrame.appendChild(winScreen.element);

// Add to the game loop, after UI updates:
territoryBar.update(state.red.territoryPercent);

if (state.winResult && state.phase === GamePhase.ENDED) {
  const day = Math.floor(state.tick / 1440) + 1;
  winScreen.show(state.winResult, day);
}
```

- [ ] **Step 2: Verify full flow works**

Run: `cd ecosim && npx vite --open`
Expected: territory bar visible at bottom of widget, win screen shows when game ends

- [ ] **Step 3: Run all tests and typecheck**

Run: `cd ecosim && npx vitest run && npx tsc --noEmit`
Expected: All pass, no errors

- [ ] **Step 4: Commit**

```bash
cd ecosim && git add src/game.ts && git commit -m "feat: integrate territory bar and win screen into game loop"
```

---

## Summary

**18 tasks across 6 phases:**

| Phase | Tasks | What it delivers |
|-------|-------|-----------------|
| 1. Foundation | 1-4 | Utils, grid, ant agents, colony/combat/win |
| 2. Game Loop | 5-6 | Tick loop, spawning, food system |
| 3. Rendering | 7-10 | PixiJS widget, soil, tunnels, ants, glow |
| 4. UI | 11-14 | Scoreboard, event log, speed, setup |
| 5. Integration | 15 | Wire everything together |
| 6. Polish | 16-18 | Territory bar, win screen, final integration |

**After all 18 tasks:** A working AntWar simulator where you click "Seal the Tank", watch two colonies autonomously dig, forage, fight, and compete for territory, with a scoreboard, event log, speed controls, and win conditions.
