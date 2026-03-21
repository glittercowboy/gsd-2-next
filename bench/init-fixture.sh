#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE_DIR="$BENCH_DIR/fixture"

if [ -d "$FIXTURE_DIR/.git" ]; then
  echo "Fixture already initialized. To reinitialize, remove fixture/.git first."
  exit 1
fi

echo "=== Creating fixture project ==="
mkdir -p "$FIXTURE_DIR/src" "$FIXTURE_DIR/tests"

# --- package.json ---
cat > "$FIXTURE_DIR/package.json" << 'EOF'
{
  "name": "priority-task-queue",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "test": "vitest run",
    "start": "tsx src/cli.ts"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "vitest": "^2.0.0",
    "tsx": "^4.7.0"
  }
}
EOF

# --- tsconfig.json ---
cat > "$FIXTURE_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "outDir": "dist",
    "rootDir": "src",
    "declaration": true,
    "sourceMap": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
EOF

# --- vitest.config.ts ---
cat > "$FIXTURE_DIR/vitest.config.ts" << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/**/*.test.ts'],
  },
});
EOF

# --- src/types.ts (pre-written interfaces the agent must implement against) ---
cat > "$FIXTURE_DIR/src/types.ts" << 'EOF'
export interface QueueItem<T = unknown> {
  id: string;
  data: T;
  priority: number;
  createdAt: number;
  delayUntil?: number;
}

export interface QueueOptions {
  maxSize?: number;
  defaultPriority?: number;
}

export interface QueueEvents {
  enqueue: (item: QueueItem) => void;
  dequeue: (item: QueueItem) => void;
  empty: () => void;
}

export interface SerializedQueue<T = unknown> {
  version: 1;
  items: QueueItem<T>[];
  options: QueueOptions;
  createdAt: number;
}
EOF

# --- src/index.ts (empty barrel export — agent fills this) ---
cat > "$FIXTURE_DIR/src/index.ts" << 'EOF'
// Priority Task Queue — implement and export all public APIs here
export {};
EOF

# --- tests/queue.test.ts (pre-written tests defining expected API) ---
cat > "$FIXTURE_DIR/tests/queue.test.ts" << 'EOF'
import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  PriorityQueue,
  DelayedQueue,
  serialize,
  deserialize,
  FilePersistence,
} from '../src/index.js';
import type { QueueItem, QueueOptions } from '../src/types.js';

describe('PriorityQueue', () => {
  let queue: PriorityQueue<string>;

  beforeEach(() => {
    queue = new PriorityQueue<string>();
  });

  it('enqueues and dequeues by priority (higher first)', () => {
    queue.enqueue('low', 1);
    queue.enqueue('high', 10);
    queue.enqueue('mid', 5);

    expect(queue.dequeue()?.data).toBe('high');
    expect(queue.dequeue()?.data).toBe('mid');
    expect(queue.dequeue()?.data).toBe('low');
  });

  it('returns undefined when dequeueing empty queue', () => {
    expect(queue.dequeue()).toBeUndefined();
  });

  it('respects maxSize option', () => {
    const small = new PriorityQueue<string>({ maxSize: 2 });
    small.enqueue('a', 1);
    small.enqueue('b', 2);
    expect(() => small.enqueue('c', 3)).toThrow(/full|max|capacity/i);
  });

  it('reports correct size and isEmpty', () => {
    expect(queue.isEmpty()).toBe(true);
    expect(queue.size).toBe(0);
    queue.enqueue('x', 1);
    expect(queue.isEmpty()).toBe(false);
    expect(queue.size).toBe(1);
  });

  it('peek returns highest priority without removing', () => {
    queue.enqueue('a', 1);
    queue.enqueue('b', 5);
    expect(queue.peek()?.data).toBe('b');
    expect(queue.size).toBe(2);
  });

  it('uses defaultPriority when priority not specified', () => {
    const q = new PriorityQueue<string>({ defaultPriority: 3 });
    q.enqueue('x');
    expect(q.peek()?.priority).toBe(3);
  });
});

describe('DelayedQueue', () => {
  let queue: DelayedQueue<string>;

  beforeEach(() => {
    queue = new DelayedQueue<string>();
  });

  it('delays items until their delayUntil time', () => {
    const now = Date.now();
    queue.enqueue('future', 5, now + 60_000);
    queue.enqueue('ready', 1);

    // Only the non-delayed item should be available
    const item = queue.dequeueReady();
    expect(item?.data).toBe('ready');
  });

  it('releases delayed items once time passes', () => {
    const past = Date.now() - 1000;
    queue.enqueue('was-delayed', 5, past);

    const item = queue.dequeueReady();
    expect(item?.data).toBe('was-delayed');
  });

  it('returns count of ready items', () => {
    const now = Date.now();
    queue.enqueue('a', 1);
    queue.enqueue('b', 2, now + 60_000);
    expect(queue.readyCount).toBe(1);
  });
});

describe('Serialization', () => {
  it('serialize and deserialize roundtrips a queue', () => {
    const queue = new PriorityQueue<string>();
    queue.enqueue('alpha', 3);
    queue.enqueue('beta', 7);

    const json = serialize(queue);
    const restored = deserialize<string>(json);

    expect(restored.size).toBe(2);
    expect(restored.dequeue()?.data).toBe('beta');
    expect(restored.dequeue()?.data).toBe('alpha');
  });

  it('serialized format includes version field', () => {
    const queue = new PriorityQueue<string>();
    queue.enqueue('x', 1);
    const data = JSON.parse(serialize(queue));
    expect(data.version).toBe(1);
  });
});

describe('FilePersistence', () => {
  it('save and load roundtrips via file', async () => {
    const tmpPath = `/tmp/bench-queue-test-${Date.now()}.json`;
    const persistence = new FilePersistence(tmpPath);

    const queue = new PriorityQueue<string>();
    queue.enqueue('persisted', 5);

    await persistence.save(queue);
    const loaded = await persistence.load<string>();

    expect(loaded.size).toBe(1);
    expect(loaded.dequeue()?.data).toBe('persisted');
  });
});

describe('Events', () => {
  it('emits enqueue and dequeue events', () => {
    const queue = new PriorityQueue<string>();
    const enqueued: string[] = [];
    const dequeued: string[] = [];

    queue.on('enqueue', (item: QueueItem) => enqueued.push(item.data as string));
    queue.on('dequeue', (item: QueueItem) => dequeued.push(item.data as string));

    queue.enqueue('a', 1);
    queue.enqueue('b', 2);
    queue.dequeue();

    expect(enqueued).toEqual(['a', 'b']);
    expect(dequeued).toEqual(['b']);
  });

  it('emits empty event when last item dequeued', () => {
    const queue = new PriorityQueue<string>();
    const emptied = vi.fn();
    queue.on('empty', emptied);

    queue.enqueue('only', 1);
    queue.dequeue();

    expect(emptied).toHaveBeenCalledOnce();
  });
});
EOF

# --- .gsd/ directory structure ---
mkdir -p "$FIXTURE_DIR/.gsd/milestones/M001/slices/S01/tasks"
mkdir -p "$FIXTURE_DIR/.gsd/milestones/M001/slices/S02/tasks"
mkdir -p "$FIXTURE_DIR/.gsd/milestones/M001/slices/S03/tasks"

# --- .gsd/PROJECT.md ---
cat > "$FIXTURE_DIR/.gsd/PROJECT.md" << 'EOF'
# Project

## What This Is
A TypeScript priority task queue library with CLI interface. Supports priority ordering, delayed execution, serialization, file persistence, and event emission.

## Core Value
Provides a robust, type-safe priority queue with delayed task support and persistence — suitable as a job scheduling primitive.

## Current State
Project scaffolded with types and test suite. Implementation needed.

## Architecture / Key Patterns
- Generic TypeScript classes (`PriorityQueue<T>`, `DelayedQueue<T>`)
- Event emitter pattern for queue lifecycle events
- JSON serialization with versioned format
- File-based persistence using async I/O

## Capability Contract
- Enqueue/dequeue items by priority
- Delay items until a specified time
- Serialize/deserialize queue state
- Persist queue to filesystem
- Emit events on enqueue, dequeue, and empty

## Milestone Sequence
- [ ] M001: Implement priority task queue library
EOF

# --- .gsd/STATE.md ---
cat > "$FIXTURE_DIR/.gsd/STATE.md" << 'EOF'
# GSD State

**Active Milestone:** M001 — Implement priority task queue library
**Active Slice:** S01 — Core Queue
**Phase:** executing
**Requirements Status:** 7 active · 0 validated · 0 deferred · 0 out of scope

## Milestone Registry
- 🔄 **M001:** Implement priority task queue library

## Recent Decisions
- Pre-written test suite defines the expected API surface
- Types are provided in src/types.ts

## Blockers
(none)

## Next Action
Implement PriorityQueue class to pass core queue tests.
EOF

# --- .gsd/milestones/M001/M001-CONTEXT.md ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/M001-CONTEXT.md" << 'EOF'
# M001: Implement Priority Task Queue Library — Context

**Gathered:** 2026-03-20
**Status:** Ready for execution

## Project Description
TypeScript priority task queue with delayed execution, persistence, and events.

## Why This Milestone
This is the sole milestone — implement the complete library from scaffolded types and tests.

## User-Visible Outcome

### When this milestone is complete, the user can:
- Import and use PriorityQueue and DelayedQueue classes
- Serialize and persist queue state to disk
- Listen for queue lifecycle events

### Entry point / environment
- Entry point: `src/index.ts` barrel export
- Environment: Node.js with TypeScript
- Live dependencies involved: none (zero runtime deps)

## Completion Class
- Contract complete means: all tests in tests/queue.test.ts pass
- Integration complete means: exports work from src/index.ts
- Operational complete means: npm test exits 0

## Final Integrated Acceptance
To call this milestone complete, we must prove:
- `npm test` passes all tests

## Risks and Unknowns
(none — straightforward implementation)

## Existing Codebase / Prior Art
- `src/types.ts` defines all interfaces
- `tests/queue.test.ts` defines expected behavior

## Relevant Requirements
- PriorityQueue: enqueue, dequeue, peek, size, isEmpty, maxSize, defaultPriority
- DelayedQueue: extends PriorityQueue with delayUntil and readyCount
- serialize/deserialize: JSON roundtrip with version field
- FilePersistence: async save/load to file
- Events: enqueue, dequeue, empty

## Scope

### In Scope
- All classes and functions tested in queue.test.ts

### Out of Scope / Non-Goals
- CLI implementation (S03 handles this)
- Performance optimization
- Concurrent access

## Technical Constraints
- Must use interfaces from src/types.ts
- Must export from src/index.ts

## Integration Points
- Tests import from ../src/index.js
EOF

# --- .gsd/milestones/M001/M001-ROADMAP.md ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/M001-ROADMAP.md" << 'EOF'
# M001: Implement Priority Task Queue Library

**Vision:** A complete, tested TypeScript priority queue library with delayed execution, persistence, and events.

## Success Criteria
- All tests in tests/queue.test.ts pass
- npm test exits 0
- All public APIs exported from src/index.ts

## Key Risks / Unknowns
(none)

## Slices
- [ ] **S01: Core Queue** `risk:low` `depends:[]`
  > After this: PriorityQueue and DelayedQueue work with priority ordering and delayed execution

- [ ] **S02: Persistence & Events** `risk:low` `depends:[S01]`
  > After this: Queue state can be serialized, persisted to file, and events are emitted

- [ ] **S03: CLI & Integration** `risk:low` `depends:[S02]`
  > After this: CLI entry point works and full integration test passes

## Boundary Map

### S01
Produces:
- `src/index.ts` with PriorityQueue and DelayedQueue classes

Consumes:
- `src/types.ts` interfaces

### S02
Produces:
- serialize/deserialize functions
- FilePersistence class
- Event emission on PriorityQueue

Consumes:
- PriorityQueue from S01

### S03
Produces:
- `src/cli.ts` CLI entry point
- Integration test verification

Consumes:
- All exports from S01 and S02
EOF

# --- S01 Plan ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S01/S01-PLAN.md" << 'EOF'
# S01: Core Queue

**Goal:** Implement PriorityQueue and DelayedQueue classes that pass core tests.
**Demo:** `npm test` passes PriorityQueue and DelayedQueue test suites.

## Must-Haves
- PriorityQueue with enqueue, dequeue, peek, size, isEmpty
- maxSize enforcement with error on overflow
- defaultPriority option
- DelayedQueue extending PriorityQueue with delayUntil and readyCount

## Verification
- `npm test` — PriorityQueue and DelayedQueue describe blocks pass

## Tasks
- [ ] **T01: Implement PriorityQueue** `est:10m`
  - Why: Core data structure for the library
  - Files: `src/index.ts`
  - Do: Implement PriorityQueue<T> class using a sorted array or heap. Support enqueue(data, priority?), dequeue(), peek(), size, isEmpty(). Respect maxSize and defaultPriority from QueueOptions.
  - Verify: PriorityQueue tests pass
  - Done when: All 6 PriorityQueue tests pass

- [ ] **T02: Implement DelayedQueue** `est:5m`
  - Why: Adds time-based scheduling to the queue
  - Files: `src/index.ts`
  - Do: Implement DelayedQueue<T> extending PriorityQueue. Add enqueue(data, priority, delayUntil?) and dequeueReady() that only returns items past their delayUntil. Add readyCount getter.
  - Verify: DelayedQueue tests pass
  - Done when: All 3 DelayedQueue tests pass

## Files Likely Touched
- `src/index.ts`
EOF

# --- S01 Task Plans ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S01/tasks/T01-PLAN.md" << 'EOF'
---
estimated_steps: 3
estimated_files: 1
---

# T01: Implement PriorityQueue

**Slice:** S01 — Core Queue
**Milestone:** M001

## Description
Implement the PriorityQueue<T> class as the core data structure. Uses a sorted array internally. Supports generic item types via QueueItem<T>.

## Steps
1. Import QueueItem, QueueOptions from types.ts
2. Implement PriorityQueue<T> class with sorted array storage
3. Export from src/index.ts

## Must-Haves
- [ ] enqueue(data, priority?) adds item sorted by priority (high first)
- [ ] dequeue() removes and returns highest priority item
- [ ] peek() returns highest priority item without removing
- [ ] size getter returns item count
- [ ] isEmpty() returns true when empty
- [ ] maxSize option throws on overflow
- [ ] defaultPriority option used when priority not specified
- [ ] Each item gets unique id and createdAt timestamp

## Verification
- PriorityQueue describe block: all 6 tests pass

## Expected Output
- `src/index.ts` — PriorityQueue class implementation and export
EOF

cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S01/tasks/T02-PLAN.md" << 'EOF'
---
estimated_steps: 2
estimated_files: 1
---

# T02: Implement DelayedQueue

**Slice:** S01 — Core Queue
**Milestone:** M001

## Description
Implement DelayedQueue<T> extending PriorityQueue with time-delayed dequeue support.

## Steps
1. Implement DelayedQueue<T> extending PriorityQueue<T>
2. Add dequeueReady() and readyCount, export from index.ts

## Must-Haves
- [ ] enqueue(data, priority, delayUntil?) stores delay timestamp
- [ ] dequeueReady() only returns items where delayUntil <= Date.now()
- [ ] readyCount getter returns count of non-delayed items

## Verification
- DelayedQueue describe block: all 3 tests pass

## Expected Output
- `src/index.ts` — DelayedQueue class added and exported
EOF

# --- S02 Plan ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S02/S02-PLAN.md" << 'EOF'
# S02: Persistence & Events

**Goal:** Add serialization, file persistence, and event emission to the queue.
**Demo:** Serialization, FilePersistence, and Events test suites pass.

## Must-Haves
- serialize(queue) returns JSON string with version field
- deserialize(json) returns a PriorityQueue with items restored
- FilePersistence class with async save(queue) and load()
- Event emission: enqueue, dequeue, empty events on PriorityQueue

## Verification
- `npm test` — Serialization, FilePersistence, and Events describe blocks pass

## Tasks
- [ ] **T03: Implement serialize/deserialize** `est:5m`
  - Why: Enable queue state export/import
  - Files: `src/index.ts`
  - Do: Implement serialize(queue) → JSON string and deserialize(json) → PriorityQueue. Include version:1 in serialized format.
  - Verify: Serialization tests pass
  - Done when: Both serialization tests pass

- [ ] **T04: Implement FilePersistence** `est:5m`
  - Why: Enable durable queue storage
  - Files: `src/index.ts`
  - Do: Implement FilePersistence class with constructor(path), async save(queue), async load<T>(). Use Node.js fs/promises.
  - Verify: FilePersistence test passes
  - Done when: FilePersistence save/load roundtrip test passes

- [ ] **T05: Implement event emission** `est:5m`
  - Why: Enable reactive patterns on queue changes
  - Files: `src/index.ts`
  - Do: Add on(event, callback) to PriorityQueue. Emit 'enqueue' on enqueue, 'dequeue' on dequeue, 'empty' when last item removed.
  - Verify: Events tests pass
  - Done when: Both event tests pass

## Files Likely Touched
- `src/index.ts`
EOF

# --- S02 Task Plans ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S02/tasks/T03-PLAN.md" << 'EOF'
---
estimated_steps: 2
estimated_files: 1
---

# T03: Implement serialize/deserialize

**Slice:** S02 — Persistence & Events
**Milestone:** M001

## Description
JSON serialization with versioned format for queue state.

## Steps
1. Implement serialize(queue) using SerializedQueue interface from types.ts
2. Implement deserialize(json) that restores a PriorityQueue with items in correct order

## Must-Haves
- [ ] serialize returns JSON string
- [ ] Serialized data includes version: 1
- [ ] deserialize restores items in priority order
- [ ] Roundtrip preserves all item data

## Verification
- Serialization describe block: both tests pass

## Expected Output
- `src/index.ts` — serialize and deserialize functions exported
EOF

cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S02/tasks/T04-PLAN.md" << 'EOF'
---
estimated_steps: 2
estimated_files: 1
---

# T04: Implement FilePersistence

**Slice:** S02 — Persistence & Events
**Milestone:** M001

## Description
File-based persistence for queue state using Node.js fs/promises.

## Steps
1. Implement FilePersistence class with constructor(filePath: string)
2. Add async save(queue) and async load<T>() methods

## Must-Haves
- [ ] save writes serialized queue to file
- [ ] load reads file and returns deserialized PriorityQueue
- [ ] Roundtrip through file preserves queue state

## Verification
- FilePersistence describe block: test passes

## Expected Output
- `src/index.ts` — FilePersistence class exported
EOF

cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S02/tasks/T05-PLAN.md" << 'EOF'
---
estimated_steps: 2
estimated_files: 1
---

# T05: Implement event emission

**Slice:** S02 — Persistence & Events
**Milestone:** M001

## Description
Add event emission to PriorityQueue for lifecycle hooks.

## Steps
1. Add event listener storage and on(event, callback) method to PriorityQueue
2. Emit events in enqueue(), dequeue() methods

## Must-Haves
- [ ] on('enqueue', cb) fires when item enqueued
- [ ] on('dequeue', cb) fires when item dequeued
- [ ] on('empty', cb) fires when last item removed

## Verification
- Events describe block: both tests pass

## Expected Output
- `src/index.ts` — PriorityQueue gains on() method and event emission
EOF

# --- S03 Plan ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S03/S03-PLAN.md" << 'EOF'
# S03: CLI & Integration

**Goal:** Add CLI entry point and verify full integration.
**Demo:** Full npm test passes, CLI is runnable.

## Must-Haves
- CLI entry point at src/cli.ts
- All tests pass end-to-end

## Verification
- `npm test` — all describe blocks pass (10 tests)

## Tasks
- [ ] **T06: Implement CLI entry point** `est:5m`
  - Why: Provides interactive queue usage
  - Files: `src/cli.ts`
  - Do: Implement basic CLI that creates a queue, supports add/pop/list/save/load commands via argv.
  - Verify: `npx tsx src/cli.ts --help` works
  - Done when: CLI is functional

- [ ] **T07: Integration verification** `est:3m`
  - Why: Ensure all components work together
  - Files: (none — just run tests)
  - Do: Run full test suite, fix any remaining issues
  - Verify: npm test exits 0 with all tests passing
  - Done when: All 10 tests pass

## Files Likely Touched
- `src/cli.ts`
- `src/index.ts` (if fixes needed)
EOF

# --- S03 Task Plans ---
cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S03/tasks/T06-PLAN.md" << 'EOF'
---
estimated_steps: 2
estimated_files: 1
---

# T06: Implement CLI entry point

**Slice:** S03 — CLI & Integration
**Milestone:** M001

## Description
Basic CLI for interacting with the priority queue from the command line.

## Steps
1. Create src/cli.ts with argument parsing
2. Implement add, pop, list, save, load commands

## Must-Haves
- [ ] CLI parses commands from process.argv
- [ ] Supports basic queue operations

## Verification
- `npx tsx src/cli.ts --help` outputs usage

## Expected Output
- `src/cli.ts` — CLI entry point
EOF

cat > "$FIXTURE_DIR/.gsd/milestones/M001/slices/S03/tasks/T07-PLAN.md" << 'EOF'
---
estimated_steps: 1
estimated_files: 0
---

# T07: Integration verification

**Slice:** S03 — CLI & Integration
**Milestone:** M001

## Description
Run the full test suite and fix any remaining issues.

## Steps
1. Run npm test and verify all 10 tests pass
2. Fix any failures

## Must-Haves
- [ ] All 10 tests pass
- [ ] npm test exits 0

## Verification
- npm test — 10/10 tests pass

## Expected Output
(no new files — verification only)
EOF

# --- .gitignore for fixture ---
cat > "$FIXTURE_DIR/.gitignore" << 'EOF'
node_modules/
dist/
*.js
*.d.ts
*.js.map
!vitest.config.ts
EOF

# --- Initialize git repo and tag ---
echo "=== Initializing fixture git repo ==="
cd "$FIXTURE_DIR"
git init
git add -A
git commit -m "Initial fixture: priority task queue with tests and GSD plans"
git tag bench-v1

echo "=== Installing dependencies ==="
npm install

echo "=== Fixture initialized ==="
echo "Tag: bench-v1"
echo "Location: $FIXTURE_DIR"
echo ""
echo "To verify: cd $FIXTURE_DIR && git log --oneline && npm test"
