# One PR per ticket, also in parallel mode

In parallel mode each ticket still gets its own branch and its own PR against `main`, as in the sequential flow. Its branch is kept up to date by merging `origin/main` into it (to *sync*), never by rebasing. The how is in the flow block that `jmb-setup` writes in the project's AGENTS.md. What is recorded here is what was ruled out.

## Considered options

- **One PR per frontier**: the review, the fixes and the merge would go for the whole batch at once, and one stuck ticket would hold back the others.
- **An integration branch**, which collects the tickets' PRs and reaches `main` in a PR of its own: `Closes #N` closes an issue only when it merges into the default branch, and someone would have to merge the inner PRs. In this flow the agent never merges, so the human would merge each ticket's PR and then the integration branch's.
