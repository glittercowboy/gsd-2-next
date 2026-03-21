---
version: 1
token_profile: balanced
budget_ceiling: 3.00
budget_enforcement: halt
verification_commands: ["npm test"]
verification_auto_fix: true
verification_max_retries: 1
auto_report: false
auto_visualize: false
git:
  isolation: none
  auto_push: false
---
