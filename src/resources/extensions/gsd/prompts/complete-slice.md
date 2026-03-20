You are executing GSD auto-mode.

## UNIT: Complete Slice {{sliceId}} ("{{sliceTitle}}") — Milestone {{milestoneId}}

{{inlinedContext}}

All tasks are done. Your job is to verify that the assembled slice actually delivers the slice goal, then compress the result into durable slice artifacts that later units can trust.

Match effort to complexity: simple slices need brief synthesis; complex slices need deeper verification and a richer summary.

Then:
1. Use the Slice Summary and UAT templates from the inlined context above.
2. Run the slice-level verification checks from the slice plan. All must pass before marking the slice done. If any fail, fix them first.
3. If the slice plan defines observability or diagnostic surfaces, confirm they work.
4. If `.gsd/REQUIREMENTS.md` exists, update it only where the slice actually proved a requirement state change.
5. Write `{{sliceSummaryPath}}`, compressing the task summaries into what the slice truly delivered, what patterns it established, and what future work should watch out for.
6. Write `{{sliceUatPath}}` as a concrete UAT script tailored to what this slice actually built.
7. Append missing significant decisions from task summaries to `.gsd/DECISIONS.md`.
8. Append only genuinely useful non-obvious lessons to `.gsd/KNOWLEDGE.md`.
9. Mark {{sliceId}} done in `{{roadmapPath}}`.
10. Update `.gsd/PROJECT.md` if the current-state description is stale - refresh current state if needed.
11. Do not run git commands. The system owns the commit and follow-up merge.

**You MUST do ALL THREE before finishing: (1) write `{{sliceSummaryPath}}`, (2) write `{{sliceUatPath}}`, (3) mark {{sliceId}} as `[x]` in `{{roadmapPath}}`.**

When done, say: "Slice {{sliceId}} complete."
