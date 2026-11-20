---
name: jmb-sync
description: "Bring what is running up to date: relaunch the PRs that fell behind, clean up the worktrees that landed and summarize what is waiting for the human. Use after every merge, before launching anything new."
disable-model-invocation: true
---

# jmb-sync

Leave the board up to date after a merge: every live PR is back on top of `main`, the worktrees that landed disappear and the human sees in a table what is waiting for them. Orchestrate from the main checkout, on `main`, and **nothing is committed here**: every commit is made by a subagent in its worktree.

**New tickets are launched by [`jmb-implement-frontier`](../jmb-implement-frontier/SKILL.md)**, not by this skill. The boundary between the two: here you touch what already has a branch; what has no branch is a launch.

**Launch it with no subagents running.** A live fixer and a dead one leave the same trace on the PR (draft with a pending review), and no lock file tells them apart: the one that dies does not delete it. Whoever launches the skill knows what they have running, and two subagents in the same worktree step on each other's commits.

It is idempotent: two runs in a row do not relaunch anything twice.

What is specific to the project comes from `docs/agents/flow.md`: each § is one of its headings, and each *italic* is the label of one of its fields. If the project does not have it, stop and ask for `jmb-setup` to be run. This skill belongs to parallel mode, which § Worktree turns on: if `flow.md` does not have it, stop and say that the project's flow is sequential only.

## Steps

1. **Place.** `git branch --show-current` gives `main`, `git status --porcelain` is empty, `git pull --ff-only origin main` brings `main` up to date and `git fetch origin` brings in the other branches. If anything fails, stop and say so. Done when `main` is the head of `origin/main` with a clean tree.
2. **Inventory.** `gh pr list --state open --json number,headRefName,isDraft,url` (those on an `<n>-<slug>` branch whose `<n>` is a flow ticket, with *Label* of § Tickets: a research report's PR has that branch too, and `jmb-implement-ticket` does not carry it), `git worktree list` and the flow tickets (§ Tickets) assigned to you. Each one falls into the **first** case that matches, and the order matters: a PR under fixes is in draft, so the review case goes before the draft one.
   1. **Worktree whose branch has a merged PR** (`gh pr list --state merged --head <branch>`): it landed → cleanup (step 3).
   2. **PR with a pending review**, per the signal in [../jmb-review-pr/protocol.md](../jmb-review-pr/protocol.md) → relaunch (step 4). If its base also moved, the same relaunch syncs it.
   3. **PR whose base moved**: `git rev-list --count origin/<branch>..origin/main` > 0 → relaunch.
   4. **PR up to date and in draft**: it gave up in an earlier batch, or a fixer died after posting its fixes → to the summary; it is relaunched only if the human names it.
   5. **PR up to date and ready**: waiting for the human → to the summary.
   6. **Worktree whose branch has no PR**, neither open nor merged (`gh pr list --state all --head <branch>`): the subagent died before opening it → relaunch.
   7. **Ticket assigned to you without a branch**: the launch got lost → to the summary, so the human relaunches it with `jmb-implement-frontier <n>`; without a branch there is nothing to sync.

   Done when each open PR, each worktree and each assigned ticket is in a case.
3. **Cleanup.** For each worktree of case 1: `git worktree remove .claude/worktrees/<branch>` and *Teardown* of § Worktree. The local branch stays, like the others. A worktree that resists is left alone and mentioned in the summary. Done when `git worktree list` shows only the main checkout and worktrees with an open PR.
4. **Relaunch**, for each PR of cases 2, 3 and 6, plus those of case 4 that the human names:
   1. If the worktree does not exist: `git worktree add .claude/worktrees/<branch> <branch>` and *Prepare* of § Worktree with `(cd .claude/worktrees/<branch> && …)`, in a subshell so the cwd stays in the main checkout.
   2. A subagent (`general-purpose`, in the background) with this prompt and nothing else:

      > Invoke the `jmb-implement-ticket` skill with number `<n>`; your worktree is `<absolute path>` and the skill says how to work in it. These PRs are still alive at the same time: #`<m>` (`<branch>`)…; in shared files add at the end, without reordering or renaming what is already there. When you finish, return only the report the skill asks for.

   The prompt does not say which state applies: the skill gets its own bearings from the PR (fix the review, sync or keep implementing), and saying it here would be guessing from outside. Done when each relaunched PR has its subagent running.
5. **Collect.** Wait for every report and summarize in a table: ticket, PR, status (ready; draft and why), findings fixed if it came from a review, and what syncing cost. Below it, what is waiting for the human: ready PRs, drafts that gave up, tickets without a branch, worktrees that could not be cleaned up, and the frontier that opens when each PR is merged. No reviewing and no merging: `jmb-review-pr` and the squash belong to the human. Done when each PR of the inventory has its row.
