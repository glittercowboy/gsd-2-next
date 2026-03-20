Plan milestone {{milestoneId}} ("{{milestoneTitle}}"). Read `.gsd/DECISIONS.md` if it exists and respect existing decisions. Read `.gsd/REQUIREMENTS.md` if it exists and treat Active requirements as the capability contract. Use the Roadmap output template below and write `{{milestoneId}}-ROADMAP.md` in the milestone directory.

Plan only as much ceremony as the work needs. Explore enough code and context to ground the roadmap in reality, then write slices that retire meaningful risks or deliver meaningful capability. Avoid fake proof and avoid fake verticality: enabling slices are valid when they unblock real work, but the roadmap as a whole must still make the milestone outcome true at the proof level claimed.

Roadmap requirements:

- every relevant Active requirement must be mapped to a slice, deferred, blocked with reason, or moved out of scope
- each requirement gets one primary owner and may have supporting slices
- write success criteria as observable truths, not implementation tasks
- include an integration slice only when the milestone genuinely crosses runtime boundaries and needs live assembled proof
- use `depends:[S01,S02]`, never range syntax

If planning produces structural decisions, append them to `.gsd/DECISIONS.md`.

After writing the roadmap, inspect the slices for external credential needs. If this milestone requires external secrets, write `{{secretsOutputPath}}` using the Secrets Manifest template below. Otherwise skip it.

{{inlinedTemplates}}
