{{preamble}}

## Queue Goal

Capture future work cleanly without turning queueing into a second full planning ceremony. Ask only the questions required to place the work correctly, avoid duplicates, and write usable context artifacts.

## Draft Awareness

Before asking about new work, check the existing milestone context below. If any milestone is marked **"Draft context available"**, surface those drafts first:

1. Briefly summarize what each draft contains.
2. Ask whether to:
   - discuss it now
   - leave it for later
3. Handle draft discussions before new queue work.

If no drafts exist, skip this section.

Say exactly: "What do you want to add?" Wait for the user's answer.

## Discussion

After the user describes the work:

- read any provided spec or document before asking follow-up questions
- investigate just enough to avoid naive assumptions
- ask only about scope boundaries, dependencies, proof expectations, or integration choices that materially affect where this work belongs

Do not ask a meta "ready to queue?" question after every round. If the user keeps adding useful detail, treat that as permission to continue.

## Existing Milestone Awareness

{{existingMilestonesContext}}

Before writing anything:

1. Check for duplicates. If the work is already covered, say so and stop.
2. Check whether it belongs as an extension to an existing pending milestone instead of a new one.
3. Check dependencies on in-progress or planned work.
4. If `.gsd/REQUIREMENTS.md` exists, identify whether this work advances unmet Active requirements, promotes Deferred work, or introduces new scope.

## Scope Decision

Decide whether the queued work is:

- a single milestone
- multiple milestones with natural boundaries

If multiple milestones are clearly needed, propose the split briefly before writing artifacts.

## Verification Before Writing

Before writing any context file:

1. Verify any concrete claims you make about the current codebase against actual code.
2. Note important unknowns honestly instead of pretending they are resolved.
3. Use a confirmation gate only when a material ambiguity remains. If the intended scope is already clear, do not force an extra write gate.

## Output

Once the direction is clear, in one pass for each new milestone:

1. Call `gsd_generate_milestone_id` and create `.gsd/milestones/<ID>/slices`.
2. Write `.gsd/milestones/<ID>/<ID>-CONTEXT.md` using the Context template below. Capture intent, scope, constraints, dependencies, and open risks. Mark the status as queued.
3. If the milestone depends on earlier milestones, add YAML frontmatter with `depends_on`.

After writing all new contexts:

4. Update `.gsd/PROJECT.md` to add the new milestones to the sequence.
5. Update `.gsd/REQUIREMENTS.md` only if the queued work changes the capability contract.
6. Append meaningful decisions to `.gsd/DECISIONS.md` if needed.
7. Append to `.gsd/QUEUE.md`.
8. Keep `.gsd/DISCUSSION-MANIFEST.json` accurate only when the surrounding multi-milestone workflow requires it.
9. {{commitInstruction}}

Do NOT write roadmaps for queued milestones.
Do NOT update `.gsd/STATE.md`.

After writing the files and committing, say exactly: "Queued N milestone(s). Auto-mode will pick them up after current work completes."

{{inlinedTemplates}}
