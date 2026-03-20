You are executing GSD auto-mode.

## UNIT: Plan Slice {{sliceId}} ("{{sliceTitle}}") — Milestone {{milestoneId}}

{{inlinedContext}}

### Dependency Slice Summaries

Pay particular attention to **Forward Intelligence** sections — they capture constraints, changed assumptions, and fragility that should shape this plan.

{{dependencySummaries}}

Plan this slice so an executor can act without re-exploring the whole milestone.

### Source Files

{{sourceFilePaths}}

If slice research is already inlined above, trust it and skip redundant exploration.

{{executorContextConstraints}}

## Planning Rules

- Verify the roadmap description against the current codebase state before decomposing.
- Right-size the plan. If the slice is simple enough to be one task, plan one task.
- Every owned Active requirement must map to at least one task with verification that proves it.
- Define slice-level verification before decomposing tasks.
- Use observability, proof-level, and integration-closure sections only when they add real information.
- Every task must list concrete backtick-wrapped input and output file paths. Vague prose breaks dependency inference.
- Every task must be completable in one fresh context window.

## Output

0. If `REQUIREMENTS.md` is inlined above, identify which Active requirements this slice owns or supports.
1. Read the templates:
   - `~/.gsd/agent/extensions/gsd/templates/plan.md`
   - `~/.gsd/agent/extensions/gsd/templates/task-plan.md`
2. Define slice-level verification:
   - non-trivial slices should name real test files or executable checks
   - simple slices may use executable commands or script assertions
   - if this slice establishes a boundary contract, verification must exercise it
3. Decompose into tasks. Each task needs:
   - a concrete action-oriented title
   - complete inline plan fields
   - a matching task plan file with description, steps, must-haves, verification, inputs, and expected output
   - observability impact only when runtime boundaries, async flows, or error paths make it relevant
4. Write `{{outputPath}}`.
5. Write individual task plans in `{{slicePath}}/tasks/`.
6. Self-audit before finishing:
   - if every task completed exactly as written, the slice goal/demo would be true
   - no requirement or must-have is orphaned
   - tasks are complete, ordered correctly, and explicitly wire required connections
   - task scope is reasonable for a single context window
7. If planning produced structural decisions, append them to `.gsd/DECISIONS.md`.
8. {{commitInstruction}}

The slice directory and `tasks/` subdirectory already exist. Do NOT `mkdir`.

**You MUST write `{{outputPath}}` before finishing.**

When done, say: "Slice {{sliceId}} planned."
