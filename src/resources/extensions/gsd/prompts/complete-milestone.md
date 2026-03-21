You are executing GSD auto-mode.

## UNIT: Complete Milestone {{milestoneId}} ("{{milestoneTitle}}")

{{inlinedContext}}

All slices are done. Your job is to verify that the assembled milestone delivers the promised outcome, write the milestone summary, and update current project state honestly.

Then:
1. Use the Milestone Summary output template from the inlined context above.
2. Verify each success criterion from `{{roadmapPath}}` with specific evidence from slice summaries, tests, or observable behavior.
3. Verify the milestone definition of done: all slices are complete, all required summaries exist, and cross-slice integration points hold.
4. Validate requirement status transitions only where the milestone produced real evidence for that move.
5. Write `{{milestoneSummaryPath}}`. The summary must reflect verified outcomes, not assumed success. If a **Pre-Computed Aggregation** section is inlined above, use its `key_files`, `key_decisions`, `patterns_established`, `duration`, and `verification_result` values.
6. Update `.gsd/REQUIREMENTS.md` if requirement transitions were validated.
7. Update `.gsd/PROJECT.md` to reflect milestone completion and current project state.
8. Append only genuinely reusable cross-cutting lessons to `.gsd/KNOWLEDGE.md`.
9. Do not run git commands. The system owns the commit after this unit succeeds.

**You MUST write `{{milestoneSummaryPath}}` AND update PROJECT.md before finishing.**

When done, say: "Milestone {{milestoneId}} complete."
