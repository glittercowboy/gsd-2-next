#!/usr/bin/env python3
"""Score a GSD benchmark run from metrics.json and npm test output.

Outputs a greppable score block:
  score:67.50
  cost_usd:1.2340
  wall_minutes:12.5
  tasks:5/7
  tests:8/10
"""

import json
import re
import subprocess
import sys
from pathlib import Path

FIXTURE_DIR = Path(__file__).resolve().parent / "fixture"
METRICS_PATH = FIXTURE_DIR / ".gsd" / "metrics.json"
MAX_COST_USD = 3.00
MAX_WALL_MINUTES = 20.0
TOTAL_TASKS = 7


def load_metrics() -> dict:
    if not METRICS_PATH.exists():
        return {"units": [], "projectStartedAt": 0}
    with open(METRICS_PATH) as f:
        return json.load(f)


def compute_task_completion(metrics: dict) -> tuple[int, int]:
    """Count completed execute-task units."""
    completed = sum(
        1 for u in metrics.get("units", [])
        if u.get("type") == "execute-task" and u.get("finishedAt", 0) > 0
    )
    return completed, TOTAL_TASKS


def run_npm_test() -> tuple[int, int]:
    """Run npm test in fixture dir, parse test pass/fail counts."""
    try:
        result = subprocess.run(
            ["npm", "test", "--", "--reporter=verbose"],
            cwd=str(FIXTURE_DIR),
            capture_output=True,
            text=True,
            timeout=60,
        )
        output = result.stdout + result.stderr
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return 0, 1

    # vitest summary line: "      Tests  14 failed (14)" or "      Tests  3 passed | 11 failed (14)"
    passed = 0
    failed = 0

    # Match the "Tests" summary line specifically (not "Test Files")
    tests_line = re.search(r"Tests\s+.*?(\d+)\s+(passed|failed)", output)
    if tests_line:
        # Parse all numbers from the Tests line
        line_start = tests_line.start()
        line_end = output.find("\n", line_start)
        tests_summary = output[line_start:line_end] if line_end != -1 else output[line_start:]

        pass_match = re.search(r"(\d+)\s+passed", tests_summary)
        fail_match = re.search(r"(\d+)\s+failed", tests_summary)
        if pass_match:
            passed = int(pass_match.group(1))
        if fail_match:
            failed = int(fail_match.group(1))

    total = passed + failed
    if total == 0:
        # Fallback: count FAIL lines in stderr (vitest error output)
        failed = len(re.findall(r"^\s*FAIL\s+", output, re.MULTILINE))
        total = max(failed, 1)

    return passed, total


def compute_cost(metrics: dict) -> float:
    return sum(u.get("cost", 0) for u in metrics.get("units", []))


def compute_wall_minutes(metrics: dict) -> float:
    units = metrics.get("units", [])
    if not units:
        return 0.0
    started = metrics.get("projectStartedAt", 0)
    finished = max(u.get("finishedAt", 0) for u in units)
    if started == 0 or finished == 0:
        return 0.0
    return (finished - started) / 60_000


def compute_reliability(metrics: dict) -> int:
    retries = sum(1 for u in metrics.get("units", []) if u.get("continueHereFired"))
    truncations = sum(
        u.get("truncationSections", 0) for u in metrics.get("units", [])
    )
    return retries + truncations


def main():
    metrics = load_metrics()

    tasks_done, tasks_total = compute_task_completion(metrics)
    tests_passed, tests_total = run_npm_test()
    cost_usd = compute_cost(metrics)
    wall_minutes = compute_wall_minutes(metrics)
    reliability_issues = compute_reliability(metrics)

    completion_pct = tests_passed / max(tests_total, 1)
    cost_score = max(0, 100 - (cost_usd / MAX_COST_USD * 100))
    speed_score = max(0, 100 - (wall_minutes / MAX_WALL_MINUTES * 100))
    reliability_score = max(0, 100 - reliability_issues * 10)

    score = (
        completion_pct * 50
        + cost_score * 0.25
        + speed_score * 0.15
        + reliability_score * 0.10
    )

    print(f"score:{score:.2f}")
    print(f"cost_usd:{cost_usd:.4f}")
    print(f"wall_minutes:{wall_minutes:.1f}")
    print(f"tasks:{tasks_done}/{tasks_total}")
    print(f"tests:{tests_passed}/{tests_total}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
