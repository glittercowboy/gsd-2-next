Execute the next task: {{taskId}} ("{{taskTitle}}") in slice {{sliceId}} of milestone {{milestoneId}}. Read the task plan, load relevant prior summaries, implement the task faithfully, verify the must-haves, and write `{{taskId}}-SUMMARY.md` using the Task Summary template below.

Build the real thing, not shipped placeholders. If the task touches UI or browser-visible behavior, exercise the real flow and record explicit pass/fail checks. If verification fails or you are running long, preserve a clean partial summary rather than burning the remaining context on blind retries. Use `blocker_discovered: true` only for real plan-invalidating findings.

When meaningful architectural or pattern decisions emerge, append them to `.gsd/DECISIONS.md`. Mark the task done and let the system own the commit.

{{inlinedTemplates}}
