# skills

The kit: the skills, the hook and the templates with which a project takes its tickets to a reviewed PR from day one. This glossary fixes the English terms of the kit, for its skills and its documentation. It does not travel to projects.

## Language

### The kit

**Kit**:
The skills, the hook and the templates of this repo, installed together in a project with `npx skills`.
_Avoid_: toolkit, bundle

**Own skill**:
A skill written for the kit: `jmb-implement-ticket`, `jmb-implement-frontier`, `jmb-review-pr`, `jmb-sync` and `jmb-setup`.
_Avoid_: custom skill, native skill

**Copy**:
A skill taken from Matt Pocock's repo, with a row in `skills/UPSTREAM.md` that gives the commit it came from and what the kit changed in it.
_Avoid_: vendored skill, fork, Matt skill

**Upstream**:
Matt Pocock's repo, `mattpocock/skills`, where the copies come from.

**Flow skills**:
The four own skills that carry tickets: `jmb-implement-ticket`, `jmb-review-pr`, `jmb-sync` and `jmb-implement-frontier`. `jmb-setup` sets them up and is not one of them.

**User preferences**:
The personal instructions in `user/CLAUDE.md`, which `~/.claude/CLAUDE.md` imports in every session, and the `attribution` setting of `~/.claude/settings.json`. They are installed once per machine and are not part of the kit: the flow does not depend on them.
_Avoid_: personal part, personal config

### The contract

**Contract**:
`docs/agents/flow.md`: what the flow skills need to know about a project, written by `jmb-setup` from the template `skills/jmb-setup/templates/flow.md`. The skills cite each section by its heading (§) and each field by its label (*italic*), so renaming one breaks the skills that cite it.
_Avoid_: config, settings

**Slot**:
A `{{…}}` in a template, where the project's value goes. In the review protocol, a `<…>`.
_Avoid_: placeholder, hole

**Marker**:
One of the HTML comments `<!-- jmb-setup:start -->` and `<!-- jmb-setup:end -->`, which delimit what `jmb-setup` writes in a project file and rewrites when rerun.
_Avoid_: mark, fence, delimiter

**Languages table**:
The "Languages" section of the project's AGENTS.md: the language of each scope (conversation, code, documentation, tracker). It governs only what the agent writes for the project; the kit's own text arrives in English and stays that way.

**Cross-cutting criteria**:
What every ticket meets even when it does not name it, in the "Cross-cutting criteria" section of the project's AGENTS.md.
_Avoid_: transversal criteria, global requirements

**Analogies**:
The spec section where a branch writes down what it resolved by analogy with something already decided, for the maintainer to review.

### The flow

**Flow**:
How a project's changes reach `main`: branch, draft PR, green CI, ready, review, fixes and squash-merge by the human. The block that `jmb-setup` writes in AGENTS.md describes it.
_Avoid_: workflow, which reads as a GitHub Actions workflow

**Flow ticket**:
An open ticket carrying the *Label* of § Tickets of the contract.
_Avoid_: ready ticket, agent ticket

**Maintainer**:
The human who owns the project: decides, launches the review and merges. Where what matters is that a person acts and not an agent, the skills say "the human".
_Avoid_: owner, reviewer

**Sequential flow**:
The flow with one ticket at a time, in the main checkout.

**Parallel mode**:
The flow with several tickets at once, each in its worktree. It is on only when the contract has § Worktree.
_Avoid_: parallel flow, concurrent mode

**Main checkout**:
The repo's primary working tree, on `main`, from which the orchestrating skills run.
_Avoid_: main worktree, root checkout

**Isolated resources**:
What the tests write to or listen on that two worktrees cannot share (a database, a port, an environment file), with one value in the main checkout and another in each ticket's worktree.
_Avoid_: own resources, per-worktree resources

**Frontier**:
The flow tickets with no open blocker and no assignee. The same concept as wayfinder's frontier.

**Batch**:
The tickets `jmb-implement-frontier` launches at once, each with its subagent in its worktree.
_Avoid_: wave, round

**Batch table**:
Where `jmb-implement-frontier` notes, for each frontier ticket, what it touches on each axis, to pick the batch.

**Axis**:
A dimension along which two tickets running at once can collide, such as the shared types they reshape or the tables they touch. Listed in § Batch table axes of the contract. The review also has two axes, Standards and Spec, in the same sense of a dimension examined separately.

**Neighbor**:
A ticket that runs at the same time as another: the rest of its batch and the open PRs still alive.

**Sync**:
Merging `origin/main` into a ticket's branch, never rebasing. Also the skill `jmb-sync`, which syncs every live PR after a merge.
_Avoid_: reintegrate, rebase, update

### The review

**Review**:
The flow's only review: `jmb-review-pr` on a ready PR, at the maintainer's request, along the Standards and Spec axes. It leaves its report as a comment on the PR.

**Finding**:
One item of a review report or of a resolution review.
_Avoid_: issue, comment, remark

**Fixes comment**:
The comment `jmb-implement-ticket` posts on the PR after addressing a review: one outcome per finding.

**Outcome**:
What a finding ends as: fixed, no change (with an argument), or out of scope (named, with whose it is).
_Avoid_: resolution, verdict

**Pending review**:
The state of a PR whose last review comment has no fixes comment after it. It is the signal on which `jmb-implement-ticket` starts its fixes and `jmb-sync` relaunches the PR.

### Research

**Research report**:
The dated Markdown snapshot a research leaves in the repo, `docs/research/<YYYY-MM-DD>-<slug>.md` unless the repo already keeps such notes elsewhere. It reaches `main` through a PR of its own and is frozen there: later research supersedes it instead of editing it.
_Avoid_: findings, since a finding is an item of a review report; research note

### Wayfinding

**Map**:
The issue labelled `wayfinder:map` that indexes an effort's decision tickets. `jmb-to-spec` takes it as input when the destination is a spec.
_Avoid_: plan, roadmap

**Resolution comment**:
The comment where a map ticket leaves its answer, which prevails over the rest of its discussion.
_Avoid_: answer, decision comment

**Resolution review**:
The optional review of a resolution comment before it is recorded, by a fresh-context subagent at the maintainer's request. It is not part of the flow and leaves no comment.
_Avoid_: review alone, which is `jmb-review-pr`'s

### Building the kit

**Rehearsal**:
A run of `jmb-setup` on a throwaway clone of a real project, with fixed answers, whose result is compared with that of an earlier rehearsal.
_Avoid_: dry run, test run
