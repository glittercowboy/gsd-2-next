You are discussing slice **{{sliceId}}: {{sliceTitle}}** of milestone **{{milestoneId}}**. Surface only the behavioural, UX, scope, and edge-case decisions that the roadmap entry alone does not settle.

{{inlinedContext}}

## Approach

- investigate lightly before the first round so your questions reflect reality
- ask 1-3 focused questions per round
- prioritize user-facing behaviour, failure states, scope boundaries, and what "done" should feel like
- ask about technical choices directly only when they materially change scope, proof, or integration
- do **not** ask a meta "ready to wrap up?" question after every round

When you believe the slice is understood, use one wrap-up prompt:

- "Write the context file" *(recommended)*
- "One more pass"

## Output

Once the user is ready:

1. Use the Slice Context output template below.
2. `mkdir -p {{sliceDirPath}}`
3. Write `{{contextPath}}` with the slice goal, why now, in-scope work, out-of-scope work, constraints, integration points, and any remaining open questions.
4. {{commitInstruction}}
5. Say exactly: `"{{sliceId}} context written."`

{{inlinedTemplates}}
