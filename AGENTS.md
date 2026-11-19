# skills

Flow kit: the skills, the hook and the conventions with which a project takes its tickets to a reviewed PR from day one. This repo works with the kit itself, set up by `jmb-setup` like any project.

## Structure

- `skills/<name>/`: each skill of the kit, flat and without a group folder, as it ends up installed in a project: a `../<skill>/…` link resolves the same here as there. `jmb-setup/templates/` holds what that skill writes in a project.
- `skills/UPSTREAM.md`: which skills are copies of Matt Pocock's. A copy is one with a row in its table, and the rest are own skills. Copies are touched only where they clash with the flow; whatever is agnostic is worked on in the own skills. The row gives Matt's commit the copy came from and its changes: a change to a copy is noted in its row, and porting one of Matt's starts from that commit. Its "Derived files" section does the same for the files of own skills that come from his, such as `jmb-setup`'s hook and three of its templates.
- `LICENSE`: the kit's MIT. Each skill folder carries a `LICENSE` of its own too, because a project receives only the folder: a new skill is born with one. Which notice goes in each is said by [licenses.py](scripts/licenses.py), which CI runs.
- `docs/agents/`: what `jmb-setup` writes in any project; here, the same. Its `flow.md` lists the checks and the seams.
- `CONTEXT.md`: the kit's terms in English, for the skills and the documentation. It does not travel to projects.
- `user/CLAUDE.md`: the personal preferences, which `~/.claude/CLAUDE.md` imports in every session of every project, so each line costs context in all of them. It is a real file and not this repo's CLAUDE.md. Its installation is in [user/README.md](user/README.md).
- `.claude/skills/<name>`: a relative symlink to `../../skills/<name>` for each skill of the kit, which this repo's sessions load. All of them, without `npx skills add`, so that what loads is what gets edited: the source, in `skills/`.
- `.claude/settings.json`: hooks two hooks on Bash and removes Claude's attribution (`attribution`). The kit's, through `.claude/skills/jmb-setup/`, the same path as in a project; and the leaks one, [leaks.py](scripts/leaks.py), which does not travel: it blocks a commit, a push or a write of `gh` that would publish a value of the source project. The list of values lives outside the repo, as [user/README.md](user/README.md#leaks-list) tells. **If the leaks hook blocks you, stop and report it**; it says where it found a value, never which, and what matched is not written anywhere, your report included.

## The contract

The flow skills cite by name the headings and labels of the [flow.md template](skills/jmb-setup/templates/flow.md), and from the project's AGENTS.md the "Languages" table and "Sequential flow", from [agents-md-block.md](skills/jmb-setup/templates/agents-md-block.md), and "Cross-cutting criteria", from [cross-cutting-criteria.md](skills/jmb-setup/templates/cross-cutting-criteria.md): renaming one forces changing the skills that cite it. CI watches over this with [citations.py](scripts/citations.py), which only reads the forms in its header: a new citation is written in one of them.

## Decisions

The kit's hard-to-reverse decisions live in [docs/adr/](docs/adr/), with their why and what was ruled out. An ADR is not reopened in a PR: changing one takes a new ADR that supersedes it, decided in an issue.

## Cross-cutting criteria

What every ticket meets even when it does not name it: `jmb-implement-ticket` covers them in each one.

- A heading, label or marker that a skill cites is renamed, in the same PR, in every file that cites it and in `CONTEXT.md`.
- The kit carries no data of a specific project; the review watches over it.
- Every change to a copy is noted in its row of `skills/UPSTREAM.md`.
- A PR that changes a `jmb-setup` template reruns `jmb-setup` on this repo in the same PR, so that this AGENTS.md and `docs/agents/` do not fall behind.
- A PR that changes what `jmb-setup` does carries its rehearsal (`jmb-setup` run on a throwaway copy of a project, with the same answers as the last rehearsal, compared with it), and tells the result without the values of the source project.

<!-- jmb-setup:start -->
<!-- Written by jmb-setup, which on a rerun rewrites it whole and keeps the values of the "Languages" table and the rows the project has added to it. Everything else of the project goes outside these markers. -->

## Flow

**Every change goes through a branch and a PR, and `main` only advances through a squash-merge of a PR, which the human does.** The flow skills carry it (`jmb-implement-ticket`, `jmb-review-pr`, `jmb-sync` and `jmb-implement-frontier`); what is specific to this project (which tickets, the spec, the verification, the test seams) is in `docs/agents/flow.md`.

### Sequential flow

1. **Issue first, if there is something to decide.** Its number names the branch: `<n>-<slug>`, without accents. Without an issue (a typo, a change that only writes down a decision already made), the branch is `<type>-<slug>` and the PR goes without an issue.
2. **The agent commits and pushes to its branch**, never to `main`, and does not merge. It creates the branch and commits in separate Bash calls (see "The hook"), and adds each file by name with `git add`, so nothing local slips in. If pre-commit rewrites what you commit, your copy of the file is no longer valid: reread it before editing it again.
3. **Draft PR**, with title and body in the tracker's language and the title in conventional commit format. With an issue, the title ends in `(#<n>)` and the body carries `Closes #<n>`.
4. **Green CI → the agent marks the PR ready.** It is the signal that it is the human's turn.
5. **`/jmb-review-pr <n>` after the ready**, always at the human's request. It is the flow's only review, and it leaves its report as a comment on the PR.
6. **The fixes, with `/jmb-implement-ticket <n>`**, which recognizes the pending review, gives each finding an outcome (fixed, no change with an argument, or out of scope) and returns the PR to ready with its fixes comment.
7. **Squash-merge, by the human.** The remote branch is deleted automatically on merge.

A PR is one commit on `main` and a complete, verified change; an issue may need several.

**What lands on `main`.** The squash commit takes the PR title as its subject and the branch's commit messages as its body; the PR body is discarded. That is why the why of a change goes in the commit message, which is what stays in `git log`, and the PR body is for whoever reviews. `Closes #<n>` closes the issue on merge, whether it comes from the PR body or from a commit: to keep it from closing the issue, remove it from both places.

**The spec follows reasoned code.** If the code departs from the spec for a reason (*Path* of § Spec in `docs/agents/flow.md`), the spec is corrected in the same PR, with the why in the commit message. What is resolved by analogy with something already decided goes to *Analogies*.

### Parallel mode

Only if `docs/agents/flow.md` has § Worktree. Without it, the flow is sequential only; it is turned on by running `/jmb-setup` again.

It is the same flow, several times over. `/jmb-implement-frontier` launches a **batch** of tickets from the **frontier** (the flow tickets with no open blocker and no assignee), each with its subagent in its worktree, `.claude/worktrees/<n>-<slug>`, and its PR against `main`. Each subagent **syncs** its branch (`git merge origin/main`, never rebase) before the ready and again every time `main` moves. After every merge, `/jmb-sync` brings the live PRs up to date, relaunches what died and cleans up the worktrees that landed. The orchestrator stays in the main checkout, on `main`, and does not commit: every commit is made by a subagent in its worktree.

### The hook

`block-dangerous-git.sh`, from the `jmb-setup` skill and hooked in `.claude/settings.json`, blocks destructive git commands and every commit or push that lands on `main`. **If it blocks you, rightly or by mistake, stop, report it and ask for instructions**: stopping and asking is a correct answer.

- **Branch and commit, in separate Bash calls.** The hook looks at the branch before the call runs: in `git switch -c <branch> && git commit` it judges the commit against `main` and blocks it.
- **`git -C <path>` is fine**, and it is the normal way to work in a worktree from a shell anchored elsewhere, but with the literal path: the hook reads the line before the shell expands it, so a `git -C $W commit` is blocked.
- **An indirection it does not detect is not permission**: `command git`, the path to the binary, `sh -c` or prefixing `CLAUDE_PROJECT_DIR=<path>`. Its blind spot is documented in its header and kept on purpose.

Why this way:

- **One single path.** With a direct path to `main` for small things, the local `main` drifts from `origin/main`, and a commit that also lives in a PR is reapplied on the squash and clashes with identical code. With one single path, the local `main` always advances by fast-forward.
- **Squash and not rebase.** CI runs on the head of the PR, not on each intermediate commit: with rebase, `main` would carry commits that never passed the tests.
- **The hook is the guard on the agent's side**, and the only one if the GitHub plan does not allow protecting `main`.

## Languages

| Scope | Language |
|---|---|
| Conversation | Spanish |
| Code: identifiers, comments, messages | English |
| Documentation: README, `docs/`, spec, glossary | English |
| Tracker: issues, PRs, commits | English |
| Conventional commit prefix, `Closes #N` and whatever the framework imposes | Set by their syntax or the framework |
| Skills, own and copies | English |

## Agent skills

- **Issue tracker**: `docs/agents/issue-tracker.md`, before creating, reading, labelling or closing an issue or a PR, and before publishing a spec.
- **Triage labels**: `docs/agents/triage-labels.md`, before applying or looking for a triage label.
- **Domain docs**: `docs/agents/domain.md`, before exploring the codebase or naming a domain concept.

<!-- jmb-setup:end -->
