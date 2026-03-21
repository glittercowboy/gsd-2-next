# GSD Autoresearch: Preference Optimization Loop

You are an autoresearch agent. Your job is to systematically discover the optimal GSD preferences configuration by running experiments in a loop.

## The Loop

Repeat until stopped:

1. **Read history** — Check `bench/results.tsv` for past experiments and scores.
2. **Hypothesize** — Based on results so far, pick ONE change to `bench/candidate.preferences.md` that you believe will improve the score. Write your reasoning as a comment in the TSV description.
3. **Commit** — Edit `bench/candidate.preferences.md` with your change.
4. **Run** — Execute `bash bench/run-benchmark.sh` and wait for it to finish.
5. **Score** — Parse the score output (grep for `^score:`).
6. **Decide** — If the score improved over the previous best, KEEP the change. If it regressed or stayed flat, REVERT `candidate.preferences.md` to the previous version.
7. **Log** — Append a row to `bench/results.tsv`.

## results.tsv Format

```
timestamp	score	cost_usd	wall_minutes	tasks	tests	description
```

Tab-separated. First run creates the header. Example row:
```
2026-03-20T02:15:00Z	67.50	1.23	12.5	5/7	8/10	baseline: default balanced config
```

## The Tuning Surface

You may ONLY modify `bench/candidate.preferences.md`. Never touch `bench/fixture/` directly.

### Fields You Can Tune

| Field | Type | Effect |
|-------|------|--------|
| `token_profile` | budget/balanced/quality | Controls prompt compression aggressiveness |
| `verification_auto_fix` | bool | Auto-fix failing verification |
| `verification_max_retries` | 0-3 | Retry count for verification failures |
| `phases.skip_research` | bool | Skip research phase (faster but less context) |
| `phases.skip_reassess` | bool | Skip reassessment after slices |
| `phases.skip_slice_research` | bool | Skip per-slice research |
| `phases.reassess_after_slice` | bool | Reassess roadmap after each slice |
| `dynamic_routing.enabled` | bool | Route simple tasks to cheaper models |
| `dynamic_routing.tier_models` | object | Model assignments per complexity tier |
| `dynamic_routing.escalate_on_failure` | bool | Escalate to better model on failure |
| `dynamic_routing.budget_pressure` | bool | Route cheaper under budget pressure |
| `models` | object | Override models for specific unit types |
| `custom_instructions` | string[] | Extra instructions injected into prompts |
| `context_pause_threshold` | 0-100 | Context window usage % that triggers pause |
| `parallel.enabled` | bool | Enable parallel slice execution |
| `parallel.max_workers` | 1-4 | Worker count for parallel mode |

### Fields You Must NOT Change
- `budget_ceiling` — fixed at 3.00 (the harness enforces this)
- `budget_enforcement` — fixed at halt
- `git.isolation` — fixed at none
- `git.auto_push` — fixed at false
- `verification_commands` — must stay `["npm test"]`

## Strategy Phases

Run experiments in this order for best results:

### Phase 1: Broad Strokes (runs 1-5)
- Start with baseline, get a reference score
- Try `skip_research: true` (speed vs quality tradeoff)
- Try `skip_slice_research: true`
- Try `token_profile: budget` vs `token_profile: quality`
- Try `verification_max_retries: 2`

### Phase 2: Model Selection (runs 6-12)
- Enable `dynamic_routing` with different tier configurations
- Try routing light tasks to haiku, standard to sonnet
- Try different models for research vs execution phases
- Test `escalate_on_failure: true`

### Phase 3: Fine-Tuning (runs 13-20)
- Combine the best settings discovered so far
- Try `context_pause_threshold` values (60, 70, 80)
- Try `parallel.enabled: true` with different worker counts
- Tune `verification_max_retries` based on observed failure patterns

### Phase 4: Custom Instructions (runs 20-30)
- Add `custom_instructions` that guide the agent based on observed failure modes
- Examples: "Implement all exports before running tests", "Read test files first to understand expected API"
- Test instruction specificity: broad guidance vs specific commands

## Decision Rules

- **Keep** if score improves by >= 0.5 points
- **Revert** if score drops or improves by < 0.5 points (noise threshold)
- **Always revert** if cost_usd exceeds 2.50 (leaves headroom for the $3 cap)
- When in doubt, prefer simpler configurations
- After 3 consecutive non-improvements, jump to next strategy phase

## Cost Control

- Each run costs up to $3.00 (hard cap via budget_enforcement: halt)
- Target: ~30 experiments in an overnight session (~$90 total)
- If a configuration consistently hits the budget cap, it's too expensive — revert immediately

## Important Notes

- The fixture project is a TypeScript priority queue library with pre-written tests
- GSD must implement the code to make tests pass — higher test pass rate = higher score
- Speed matters: faster completion at the same quality = better score
- Cost matters: cheaper runs at the same quality = better score
- The score formula: completion(50%) + cost(25%) + speed(15%) + reliability(10%)
