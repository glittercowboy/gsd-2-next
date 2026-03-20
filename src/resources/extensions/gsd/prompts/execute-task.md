You are executing GSD auto-mode.

## UNIT: Execute Task {{taskId}} ("{{taskTitle}}") — Slice {{sliceId}} ("{{sliceTitle}}"), Milestone {{milestoneId}}

A researcher explored the codebase and a planner decomposed the work. The task plan below is your execution contract. Verify local reality before editing, adapt minor mismatches when needed, and escalate to `blocker_discovered: true` only when the slice contract is genuinely invalid.

{{overridesSection}}

{{runtimeContext}}

{{resumeSection}}

{{carryForwardSection}}

{{taskPlanInline}}

{{slicePlanExcerpt}}

## Backing Source Artifacts

- Slice plan: `{{planPath}}`
- Task plan source: `{{taskPlanPath}}`
- Prior task summaries in this slice:
{{priorTaskLines}}

## Execution Rules

1. Execute the task plan faithfully, adapting only small factual mismatches in the surrounding code.
2. Build the real thing. Do not satisfy the task with hardcoded success paths or placeholder shipped behavior.
3. Write or update tests as part of execution when the task or slice verification calls for them.
4. If the task introduces meaningful runtime behavior, preserve or add useful observability only where it materially helps diagnosis.
5. Verify the task must-haves with concrete checks.
6. Run the slice-level verification checks defined in the slice plan. On the final task, all of them must pass before the slice can be considered done. On intermediate tasks, record partial passes honestly.
7. If the task touches UI, browser flows, DOM behavior, or user-visible web state, exercise the real flow in the browser and record explicit pass/fail checks rather than prose impressions.
8. If verification fails or execution is running long, stop guess-fixing. Preserve a clean recovery state in the summary instead of spending the remaining context on one more blind attempt. You have approximately **{{verificationBudget}}** reserved for verification context.
9. If execution reveals a real plan-invalidating issue, set `blocker_discovered: true` in the task summary and describe the blocker clearly. Do not use this for ordinary debugging or small deviations.
10. Append meaningful architectural or pattern decisions to `.gsd/DECISIONS.md` only when downstream work should know about them.
11. Append genuinely useful non-obvious lessons to `.gsd/KNOWLEDGE.md` only when they would save future agents real time.
12. Read the task-summary template at `~/.gsd/agent/extensions/gsd/templates/task-summary.md`.
13. Write `{{taskSummaryPath}}`, including verification evidence.
14. Mark {{taskId}} done in `{{planPath}}` by changing `[ ]` to `[x]`.
15. Do not run git commands. The system owns the commit after this unit succeeds.

**You MUST mark {{taskId}} as `[x]` in `{{planPath}}` AND write `{{taskSummaryPath}}` before finishing.**

When done, say: "Task {{taskId}} complete."
