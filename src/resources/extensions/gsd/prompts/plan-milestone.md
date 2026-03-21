You are executing GSD auto-mode.

## UNIT: Plan Milestone {{milestoneId}} ("{{milestoneTitle}}")

{{inlinedContext}}

You are planning the milestone roadmap. Explore enough of the codebase and surrounding context to ground the roadmap in reality, then write a roadmap another unit can execute without guessing.

## Focus

- verify what already exists before planning around it
- reuse existing patterns and seams where they fit
- identify the hardest risks or integration points early
- sequence slices so the milestone outcome becomes true at the proof level claimed
- map relevant Active requirements to slices, defer them explicitly, or surface them as blocked/out of scope

### Source Files

{{sourceFilePaths}}

If milestone research is already inlined above, trust it and skip redundant exploration. If you discover important landscape facts and no research artifact exists yet, write `{{researchOutputPath}}`.

## Roadmap Rules

- Write success criteria as observable truths, not implementation tasks.
- Order slices by risk and dependency, not by arbitrary chronology.
- Prefer slices that retire a meaningful risk or deliver a meaningful capability.
- Avoid fake proof. If a slice only proves a contract or fixture path, say so honestly.
- Avoid fake verticality. Enabling or platform slices are valid when they create a real dependency or retire a real risk, but the roadmap as a whole must still make the milestone outcome true.
- Keep slice count proportional to the work. If the milestone is small enough to build and verify in one pass, it may be one slice.
- Dependency format is comma-separated, never range syntax. Write `depends:[S01,S02]`, not `depends:[S01-S02]`.
- Surface orphaned Active requirements instead of silently ignoring them.

## Output

1. Use the Roadmap output template from the inlined context above.
2. Write `{{outputPath}}` with slices, risk, dependencies, demo lines, proof strategy where needed, verification classes, milestone definition of done, requirement coverage, and a boundary map.
3. If planning produced structural decisions, append them to `.gsd/DECISIONS.md`.

## Single-Slice Fast Path

If the roadmap honestly has one slice, also write the slice plan and task plans in this unit:

1. Use the Slice Plan and Task Plan templates from the inlined context above.
2. `mkdir -p {{milestonePath}}/slices/S01/tasks`
3. Write the slice plan at `{{milestonePath}}/slices/S01/S01-PLAN.md`.
4. Write the task plans in `{{milestonePath}}/slices/S01/tasks/`.
5. Keep the plan lean. Omit proof/integration/observability sections when they would add no information.

## Secret Forecasting

After writing the roadmap, inspect the slices for external service dependencies. If the milestone requires external credentials, write `{{secretsOutputPath}}` using the Secrets Manifest template below. If not, skip it.

**You MUST write `{{outputPath}}` before finishing.**

When done, say: "Milestone {{milestoneId}} planned."
