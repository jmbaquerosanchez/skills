---
name: jmb-implement-ticket
description: "Implement a flow ticket by its number (§ Tickets of `docs/agents/flow.md`) up to a PR ready for the human, and fix its review once the PR has one. Use when asked to implement or fix a ticket by number, or when `jmb-implement-frontier` or `jmb-sync` launch you on one."
---

# jmb-implement-ticket `<n>`

Take ticket `<n>` to a green, ready PR, or to a draft PR with a report that says why. Work **where you are invoked** and only there:

- **No path in the prompt**: the checkout you are in (its resources, those of the "Main checkout" column of *Isolated resources* in § Worktree if `flow.md` has it; the "Sequential flow" section of AGENTS.md). You create the branch, in place.
- **With a path** (a worktree that `jmb-implement-frontier` prepared, with its branch and its isolated resources already set up: *Prepare* of § Worktree, "Worktree for ticket `<n>`" column of *Isolated resources*): all git goes through `git -C <path>` and everything else through `cd <path> && …` **in the same Bash call**; files, by absolute path. In a subagent thread the cwd does not survive from one call to the next, and the git hook judges the call's directory: a `git commit` without `-C` would be judged against the main checkout, on `main`, and blocked. The path goes **literal** in every `-C`: the hook reads the line before the shell expands it, so a `git -C $W commit` is blocked all the same.

What is specific to the project comes from `docs/agents/flow.md`: each § is one of its headings, and each *italic* is the label of one of its fields. If the project does not have it, stop and ask for `jmb-setup` to be run.

## Steps

1. **Context.** The ticket (`gh issue view <n> --comments`), the spec sections it cites (*Path* of § Spec) and the ADRs of the area you are going to touch (where they live, in `docs/agents/domain.md`). Done when you can list the ticket's acceptance criteria and say which seam tests each one.
2. **State.** With `git branch --show-current`, `gh pr list --head <n>-<slug> --state open` and, if there is a PR, whether it has a pending review: [pending-review.sh](../jmb-review-pr/pending-review.sh) decides it (see [../jmb-review-pr/protocol.md](../jmb-review-pr/protocol.md#pending-review)), and you do not read the comments yourself. Run it as `bash <this skill's base directory>/../jmb-review-pr/pending-review.sh <pr>`, by absolute path, which works from the main checkout and from a worktree alike. Exit `0` is the first case below; `1`, the cases after it; `2`, it could not answer: stop and report. The first case that matches:
   - **PR with a pending review**: the script exited `0`, and what it printed is the review comment. Jump to [Fixes after review](#fixes-after-review).
   - **No branch**, meaning `<n>-<slug>` exists neither locally nor on `origin`: `git checkout -b <n>-<slug>` (the slug comes from the title, without accents; in its own Bash call). Continue at 3.
   - **Branch created and you are not on it**, the main checkout's case: `git checkout <n>-<slug>` with a clean tree (`git status --porcelain` empty, or stop) and `git pull --ff-only` to bring in what was pushed. Continue at whichever case applies.
   - **Branch without a PR**: continue at 3.
   - **Open PR**: check the acceptance criteria against the branch; those missing, step 3; if they are all there, jump to 6 (you were relaunched because `main` moved).

   Done when you are on branch `<n>-<slug>` and know which step you continue at.
3. **Implement** with `/jmb-tdd` at the ticket's seams, from the table in § Test seams. *Quick* of § Verification and the test file you touch (with its seam's "Command for one file" column), often; *Full*, at the end. **The criteria in the "Cross-cutting criteria" section of AGENTS.md apply even when the ticket does not name them**. If the prompt names **neighbors** (tickets running at the same time), in shared files add at the end and keep the order and the names of what is already there. Done when each criterion of the ticket has a test that proves it, the cross-cutting ones are covered and everything passes.
4. **Schema.** If `flow.md` has § Schema and you touched its *Source*: *Generate*, with a `<name>` that says what changes. A migration already on `main` is not edited; yours is regenerated, never retouched by hand. When **regenerating** a migration you had already applied, reset the database before testing again, with *Reset the database* for where you work. Done when *Check* passes and *Migrations* holds a single migration of yours.
5. **Commits and PR.** Commits with the why (they are the squash body), in the tracker's language per the "Languages" table of AGENTS.md; if pre-commit rewrites what you commit, reread before editing again. `git push -u origin HEAD`. `gh pr create --draft` with a conventional commit title ending in `(#<n>)` and `Closes #<n>` in the body, in that language. Done when `gh pr view` shows the PR in draft with everything on the branch pushed.
6. **Sync.** `git fetch origin && git merge origin/main` (merge, never rebase). A conflict in *Migrations* of § Schema: whatever *Conflict* says, and go back to 4, which generates the next migration with only your changes. All other conflicts are of the "both added at the end" kind: keep both sides. Then *Before pushing* of § Verification, and push. Done when the branch contains `origin/main` and everything passes.
7. **CI.** `gh pr checks --watch`. Red: fix and push, twice at most; on the third red stop and leave the PR in draft. Green: if you come from fixes, first post the fixes comment (exact form in [../jmb-review-pr/protocol.md](../jmb-review-pr/protocol.md)), and then `gh pr ready`. If `main` moves while you wait, go back to 6. Done when the PR is ready with green CI, or in draft after the third red.
8. **Report**, ≤ 10 lines, and nothing else: PR (number and URL); status (ready, or draft and why); criteria left out and why; what syncing cost, if it cost anything. If you come from fixes, instead of the criteria: how many findings fixed, how many with no change and how many out of scope.

## Fixes after review

The human launched `jmb-review-pr <n>` and the PR has a **pending review**. Address each **finding** of the comment and return the PR to ready.

1. **To draft.** `gh pr ready --undo`. While you fix, "ready" cannot keep meaning "waiting for the human", and `jmb-review-pr` refuses to review a draft PR: that way nobody reviews a half-fixed branch.
2. **Get your bearings**, always, whether you are the first or the one taking over from one that died:
   - the review comment, which `pending-review.sh` printed in step 2 → the findings, in their order, and the `<reviewed head>` of its first line;
   - `git log <reviewed head>..HEAD --oneline` → what has been done since the review;
   - `git status --porcelain` → what was left uncommitted.

   For each finding: a commit names it → done; uncommitted changes touch it → finish it and commit it; none of that → do it. **What is uncommitted is kept**, because it is the trail of how far the work had got: `git stash` and `git checkout --` erase it. The acceptance criteria are not checked again; the review made that comparison. Done when each finding has its status.
3. **One outcome per finding**, and none in silence:
   - **Fixed**, which is the default. One commit per finding (or per group of findings in the same file) with its gist in the subject and the type that fits the change (`test:`, `refactor:`, `docs:`…): that subject is what makes step 2's `git log` readable on the next relaunch.
   - **No change**, with an argument of one of these three kinds: **the ticket** excludes it or asks for the opposite; **the branch's spec** asks for it that way; or **the cost**, because it costs more than it removes or reshapes a shared type that a neighbor is absorbing.
   - **Out of scope**: it needs a decision the ticket did not make (a new entry in *Analogies* of § Spec) or belongs to another ticket. It is neither done nor rebutted: it is named, and you say whose it is, `#m` or the maintainer.

   When they clash, **the ticket wins**: no change, citing it; and if the reviewer is right that the ticket is wrong, out of scope → maintainer. Against the spec, the branch's spec is the one that binds; but if the code is the one that is right, edit the spec with the why in the commit message and list it as a decision (in *Analogies* of § Spec if it goes by analogy). Outside the findings, touch only what turns CI red for a reason foreign to the branch, and it goes under "Also" with its why. Done when each finding has an outcome and everything fixed is committed.
4. **Close.** Continue with step 6 (sync and pass everything) and step 7, which posts the fixes comment before the ready. Done when the PR is ready with green CI and its comment posted.

## Limits

- The human asks for the review with `jmb-review-pr <n>` after the ready; you do not launch it. Nor do you merge.
- `main` and the other worktrees are not touched. If the git hook blocks you, stop and say so in the report.
