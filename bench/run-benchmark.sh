#!/usr/bin/env bash
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
FIXTURE_DIR="$BENCH_DIR/fixture"
CANDIDATE="$BENCH_DIR/candidate.preferences.md"
SCORE_PY="$BENCH_DIR/score.py"

# Verify fixture is initialized
if [ ! -d "$FIXTURE_DIR/.git" ]; then
  echo "ERROR: Fixture not initialized. Run: bash bench/init-fixture.sh" >&2
  exit 1
fi

# Verify candidate config exists
if [ ! -f "$CANDIDATE" ]; then
  echo "ERROR: candidate.preferences.md not found. Copy baseline first." >&2
  exit 1
fi

echo "=== Resetting fixture to bench-v1 ==="
cd "$FIXTURE_DIR"
git checkout bench-v1 -- . 2>/dev/null || git reset --hard bench-v1
git clean -fd -e node_modules -e package-lock.json

echo "=== Installing dependencies ==="
npm install --silent 2>/dev/null

echo "=== Injecting candidate preferences ==="
mkdir -p "$FIXTURE_DIR/.gsd"
cp "$CANDIDATE" "$FIXTURE_DIR/.gsd/preferences.md"

# Inject harness overrides that must not be tuned
cat >> "$FIXTURE_DIR/.gsd/preferences.md" << 'OVERRIDES'

# --- Harness overrides (do not modify) ---
# budget_ceiling: 3.00
# budget_enforcement: halt
# git.isolation: none
OVERRIDES

echo "=== Running GSD headless auto ==="
GSD_LOG="$BENCH_DIR/last-run.log"
> "$GSD_LOG"

# Stream progress: JSONL to log file, extract event summaries to terminal
set +e
gsd headless --json --timeout 1200000 auto 2>&1 | tee "$GSD_LOG" | \
  python3 -u -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        evt = json.loads(line)
    except json.JSONDecodeError:
        continue
    t = evt.get('type', '')
    if t == 'extension_ui_request' and evt.get('method') == 'notify':
        msg = evt.get('message', '')
        if not msg:
            continue
        # Highlight key events
        first_line = msg.split('\n')[0][:120]
        if 'Committed:' in msg:
            print(f'  ✓ {first_line}', flush=True)
        elif 'Budget' in msg or 'budget' in msg:
            print(f'  \$ {first_line}', flush=True)
        elif 'Verification' in msg:
            print(f'  ⧫ {first_line}', flush=True)
        elif 'Auto-mode' in msg:
            print(f'  ◆ {first_line}', flush=True)
        elif 'Health' in msg:
            print(f'  ♥ {first_line}', flush=True)
        else:
            print(f'  … {first_line}', flush=True)
    elif t == 'agent_start':
        print(f'  ▶ agent started', flush=True)
    elif t == 'agent_end':
        print(f'  ■ agent finished', flush=True)
"
GSD_EXIT=${PIPESTATUS[0]}
set -e

echo "=== GSD exited with code $GSD_EXIT ==="

echo "=== Scoring ==="
cd "$BENCH_DIR"
python3 "$SCORE_PY"

echo "=== Done ==="
