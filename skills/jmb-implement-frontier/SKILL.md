---
name: jmb-implement-frontier
description: "Launch flow tickets (§ Tickets of `docs/agents/flow.md`) in parallel: one subagent per ticket in its worktree, one PR per ticket. Use to start a batch; bringing what is already running up to date belongs to `jmb-sync`."
disable-model-invocation: true
---

# jmb-implement-frontier `[n…]`

Launch a **batch**: one subagent per ticket, each in its worktree with its branch `<n>-<slug>` and its isolated resources (the "Worktree for ticket `<n>`" column of *Isolated resources* in § Worktree), and each takes its ticket to its own PR against `main`. Orchestrate from the main checkout, on `main`, and **nothing is committed here**: every commit is made by a subagent in its worktree.

**What is already running belongs to [`jmb-sync`](../jmb-sync/SKILL.md)**: relaunching the PRs that fell behind, cleaning up the worktrees that landed and summarizing what is waiting. The human chains the two and sets the pace: merge, `jmb-sync`, and `jmb-implement-frontier` when they want more work running.

Vocabulary: the **frontier** is the open tickets with no open blocker and no assignee; the **batch**, those launched at once; to **sync** is to merge `origin/main` into the ticket's branch, and the subagent does it.

What is specific to the project comes from `docs/agents/flow.md`: each § is one of its headings, and each *italic* is the label of one of its fields. If the project does not have it, stop and ask for `jmb-setup` to be run. This skill belongs to parallel mode, which § Worktree turns on: if `flow.md` does not have it, stop and say that the project's flow is sequential only.

## Steps

1. **Place.** `git branch --show-current` gives `main`, `git status --porcelain` is empty and `git pull --ff-only origin main` brings `main` up to date. If anything fails, stop and say so. Done when `main` is the head of `origin/main` with a clean tree.
2. **The batch.** With numbers, **it is exactly those**: the human sets the cap by listing them, and launching costs quota out of the week in which they will merge. A ticket with an open blocker stays out and you say so; one already assigned to you without a branch goes in without claiming it again (it is a launch that got lost).

   Without numbers, the frontier and **two by default** (`<label>` is *Label* of § Tickets, and it goes in a `-f` field because that is how `gh` encodes it: it may contain spaces):

   ```bash
   gh api -X GET "repos/{owner}/{repo}/issues" -f labels='<label>' -f state=open -f per_page=100 \
     --jq '.[] | select(.issue_dependencies_summary.blocked_by == 0 and (.assignees | length) == 0) | "\(.number)\t\(.title)"'
   ```

   The **batch table** picks them: for each frontier ticket, from its body (`Spec:` line and criteria), what each row of § Batch table axes asks for in the "What is noted for each ticket" column, with the **shared types it reshapes** in the *Shared types* row. First those on different entities, and above all those that do not reshape the same type: "both added at the end" conflicts are trivial, and what is expensive is reshaping a shared type that another ticket uses. When tied, the lowest number, which is the order of the critical path. Two tickets touching the schema is no reason to separate them: whichever arrives second regenerates its migration. Done when each chosen ticket has its why written down.
3. **Launch**, for each ticket of the batch:
   1. `gh issue edit <n> --add-assignee @me`.
   2. `git worktree add --no-track -b <n>-<slug> .claude/worktrees/<n>-<slug> origin/main` (the slug from the title, without accents). You create the worktree, not the Agent tool's `isolation: "worktree"`: the ticket names the branch.
   3. *Prepare* of § Worktree with `(cd .claude/worktrees/<n>-<slug> && …)`, in a subshell so the cwd stays in the main checkout.
   4. A subagent (`general-purpose`, in the background) with this prompt and nothing else:

      > Invoke the `jmb-implement-ticket` skill with number `<n>`; your worktree is `<absolute path>` and the skill says how to work in it. These neighbors run at the same time: #`<m>` (`<what was noted about it on each axis>`)…; in shared files add at the end, without reordering or renaming what is already there. When you finish, return only the report the skill asks for.

   The **neighbors** are those of the batch plus the open PRs still alive (`gh pr list --state open --json number,headRefName`): whichever arrives second will merge the other's work. Done when each ticket of the batch has its worktree prepared and its subagent launched.
4. **Collect.** Wait for every report. Summarize in a table: ticket, PR, status (ready; draft and why), criteria left out, what syncing cost. Below it, what is waiting for the human and the frontier that opens when each PR is merged. No reviewing and no merging: `jmb-review-pr` and the squash belong to the human. Done when each launched ticket has its row.
