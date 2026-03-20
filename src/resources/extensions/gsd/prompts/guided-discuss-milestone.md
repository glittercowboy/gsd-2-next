Discuss milestone {{milestoneId}} ("{{milestoneTitle}}"). Identify only the gray areas that materially affect scope, proof, sequencing, integration, or architecture, then write `{{milestoneId}}-CONTEXT.md` in the milestone directory using the Context output template below.

**Structured questions available: {{structuredQuestionsAvailable}}**

{{inlinedTemplates}}

## Approach

- do a lightweight investigation before the first question round so your questions are grounded in reality
- ask 1-3 focused questions per round
- ask about implementation directly when it materially matters
- use the user's terminology and constraints precisely
- do **not** ask a meta "ready to wrap up?" question after every round

Keep going until you can explain:

- what is being built
- why it matters
- what "done" looks like
- the biggest technical unknowns or risks
- which external systems or dependencies matter

If `{{structuredQuestionsAvailable}}` is `true`, use `ask_user_questions` for rounds when it fits; switch to plain text when the user needs freeform space.

Use a single confirmation gate when you believe the milestone is well understood:

- print a short structured depth summary in chat
- if `{{structuredQuestionsAvailable}}` is `true`, ask a confirmation question whose id contains `depth_verification`
- if `{{structuredQuestionsAvailable}}` is `false`, ask in plain text

If they clarify, absorb it and continue. Do not add a second confirmation gate.

## Output

Once the direction is clear:

1. `mkdir -p` the milestone directory if needed.
2. Write `{{milestoneId}}-CONTEXT.md`, preserving the user's exact terminology, emphasis, and framing instead of flattening it into generic summaries.
3. {{commitInstruction}}
4. Say exactly: `"{{milestoneId}} context written."`
