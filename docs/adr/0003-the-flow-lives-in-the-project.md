# What the flow needs is committed in the project, with the hook inside jmb-setup

Everything the flow needs is committed in the project's repo: the skills, the hook, `.claude/settings.json`, `docs/agents/flow.md` and the flow block of AGENTS.md. `~/.claude/` carries only the personal, and its absence breaks nothing. A session in the cloud, another machine or another person sees only what is committed. That is also why a rule without which the flow fails goes in a skill or in the project, even if the user preferences repeat it: `jmb-review-pr` checks the commit language that the project's "Languages" table sets, not a fixed one.

Where the flow lives and how it is updated are one decision. The hook travels inside the `jmb-setup` folder, and the project's `.claude/settings.json` hooks it from there. So `npx skills update` updates skills and hook at once, and they never drift apart. What lives in the project's own files (the block between markers, the entries of `settings.json`, a new section of `flow.md`) is updated by running `jmb-setup` again, which rewrites only what is its own. There are no versions or tags: the kit's `main` is what is published, and a project updates when someone runs the command.

## Considered options

- **The kit or the hook at user level** (`npx skills add -g`, `~/.claude/settings.json`): it works on one machine only, and "`main` only advances through a squash-merge of a PR" is a rule of the project, not of the person.
- **The hook copied into the project's files**: it drifts from the skills that count on it.
