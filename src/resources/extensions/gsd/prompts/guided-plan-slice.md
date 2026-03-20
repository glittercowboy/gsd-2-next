Plan slice {{sliceId}} ("{{sliceTitle}}") of milestone {{milestoneId}}. Read `.gsd/DECISIONS.md` if it exists, respect existing decisions, and read `.gsd/REQUIREMENTS.md` if it exists so the plan delivers the slice's owned or supported Active requirements.

Use the Slice Plan and Task Plan output templates below. Verify the roadmap description against the current codebase, define slice-level verification first, then decompose the slice into the smallest honest set of executable tasks. Keep the plan lean: if the slice is simple, one task may be enough.

Task-plan requirements:

- every must-have maps to at least one task
- every task has complete steps, verification, inputs, and expected output
- inputs and expected output list concrete backtick-wrapped file paths
- task ordering is coherent and explicit
- proof-level wording is honest about what is and is not proven live

If planning produces structural decisions, append them to `.gsd/DECISIONS.md`.

{{inlinedTemplates}}
