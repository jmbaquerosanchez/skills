# skills

A flow kit for Claude Code that takes a project's tickets to a reviewed PR from day one.

## Status

Untested in real use: `jmb-setup` has passed rehearsals on a copy of a project, but no real batch of tickets has gone through the kit yet. I built it mainly for my own use, and it makes no promise of stability: skill names and files may change. `skills-lock.json` pins the commit a project installed, so each project decides when to update. Issues are open to everyone; pull requests, to collaborators only.

## What it carries

- **Five own skills**, in the order of the cycle:
  - `jmb-implement-ticket` takes a ticket to a green PR, ready for review, and fixes its review afterwards.
  - `jmb-review-pr` reviews a PR and leaves its report on it.
  - `jmb-implement-frontier` launches a batch of tickets in parallel, each in its worktree and with its own PR.
  - `jmb-sync` brings what is running up to date after each merge.
  - `jmb-setup` sets the flow up in a project, or brings it up to date.
- **The git hook**, inside `jmb-setup`: it blocks destructive commands and every commit or push that lands on `main`, which only advances through a squash-merge of a PR.
- **Copies of [Matt Pocock's skills](https://github.com/mattpocock/skills)**, pinned to the commit the flow was built against; the own skills call them. [skills/UPSTREAM.md](skills/UPSTREAM.md) says which they are, the commit each one came from and what the kit changed in it.

Every skill carries the `jmb-` prefix, the copies too, so that a name does not change when a copy is replaced or modified ([why](docs/adr/0006-jmb-prefix-on-every-skill.md)). The other whys this README leaves out are in [docs/adr/](docs/adr/).

## Installing in a project

You need Claude Code, Node.js for `npx`, and a git repo with its remote on GitHub and `gh` authenticated. At the root of the project:

1. **The kit**, at project level and whole:

   ```bash
   npx skills add jmbaquerosanchez/skills -y
   ```

   It installs every skill in `.agents/skills/`, with a symlink to each one in `.claude/skills/`, where Claude Code finds them, and records the commit in `skills-lock.json`. It goes without `-g` because the project's `.claude/settings.json` hooks the hook from the project's `.claude/skills/`, and `jmb-setup` stops if it is not there. And it is the whole kit, not a subset, because the own skills call the copies and read their files.

2. **`/jmb-setup`**, in Claude Code. It explores the project, asks what it does not find and shows what it will write before writing it:
   - in `docs/agents/`, `flow.md`, with the project's data that the flow skills read (which tickets, the spec, the verification, the test seams), and `issue-tracker.md`, `triage-labels.md` and `domain.md`;
   - in `AGENTS.md`, the flow block with the "Languages" table, and the cross-cutting criteria;
   - in `.claude/settings.json`, the hook and `attribution`;
   - on GitHub, if you confirm, the repo on squash-merge only, with the branch deleted on merge.

Everything stays uncommitted and reaches `main` through a branch and its PR, like any change.

What the kit installs arrives in English. The project's "Languages" table governs only what the agent writes for the project: code, documentation, tickets, PRs and commits. So a project in another language has some mixed files, like the flow block of its AGENTS.md ([why](docs/adr/0005-the-kit-is-in-english.md)).

## Updating

```bash
npx skills update -p
```

Then run `/jmb-setup` again and take its diff to `main` through a PR. `update` brings the skills and the hook up to date, but not what `jmb-setup` wrote in the project's files: without rerunning it, the new skills read an old `docs/agents/`.

## User preferences

My user preferences, which the kit does not need, live in [user/](user/); [user/README.md](user/README.md) tells how to install them.

## License

MIT. The own skills and the rest of the repo carry the root [LICENSE](LICENSE); the copies, Matt Pocock's MIT notice. Each skill folder carries its own `LICENSE`, so that the notice travels with the install, and `jmb-setup`'s carries both, because its hook and three of its templates derive from Matt's.
