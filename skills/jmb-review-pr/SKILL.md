---
name: jmb-review-pr
description: "Review a ticket's PR along two axes and post the report as a comment on it. Use when asked to review a PR, by its number or by its ticket's."
disable-model-invocation: true
---

# jmb-review-pr `<n>`

Review the PR of ticket `<n>` along the two axes of `jmb-code-review` (Standards and Spec) and leave the report as a comment on the PR. It is **the flow's only review**, sequential and parallel alike, and the human launches it after the ready.

Orchestrate from any checkout, and **the working tree stays as it is**: everything is read from `origin/<branch>`. That is why the ticket's worktree is not needed, which may also be half done if a fixer lives in it.

What is specific to the project comes from `docs/agents/flow.md`: each § is one of its headings, and each *italic* is the label of one of its fields. If the project does not have it, stop and ask for `jmb-setup` to be run.

## Steps

1. **The PR.** GitHub shares the number space, so `<n>` works as a PR and as a ticket: `gh pr view <n>` succeeds → that PR; it fails → the open PR whose branch starts with `<n>-` (`gh pr list --state open --json number,headRefName,isDraft`). Without a PR, stop and say so. Done when you have the PR number, the branch and the ticket of the `Closes #<t>` in its body, if it has one.
2. **Guards.** In draft: stop, "come back when it is ready". CI pending or red (`gh pr checks`): stop. Reviewing a branch that is still going to change is wasted quota; the human decides whether to wait for green or take it out of draft. Done when the PR is ready and green.
3. **The fixed point.** `git fetch origin`, and from there:

   ```bash
   git merge-base origin/main origin/<branch>      # the fixed point
   git diff origin/main...origin/<branch>          # the diff (three dots: against the merge-base)
   git log origin/main..origin/<branch> --oneline  # the commits
   ```

   A ref that does not resolve or an empty diff stops here, not inside the two subagents. Done when you have the merge-base, the head (`git rev-parse origin/<branch>`) and the list of commits.
4. **The axes.** Read [../jmb-code-review/SKILL.md](../jmb-code-review/SKILL.md) (installed with the kit: it is read, not edited or copied) and paste into each prompt what belongs to it, since the subagent has no other way to see it: Fowler's smell baseline and the Standards brief in one, the Spec brief in the other, each with its 400-word cap. Two `general-purpose` subagents in parallel, `model: "sonnet"`, and in both prompts:
   - The three commands of step 3, literal, and the rule that goes with them: **every file is read in the branch's version** (`git show origin/<branch>:<path>`, `git grep -n <pattern> origin/<branch> -- <path>`). The working tree is another commit, and reading it would give `main`'s spec.
   - The report in the tracker's language per the "Languages" table of AGENTS.md, with references as `path:line` in backticks; the kit's briefs are in English.
   - **Standards**, its sources: `AGENTS.md`, the glossary and the ADRs (where they live, in `docs/agents/domain.md`) **in the branch's version** (a PR can change them), the PR's title and body (`gh pr view <pr> --json title,body`) and the commit messages: conventional commit ending in `(#<t>)`, `Closes #<t>`, in the tracker's language, without attribution.
   - **Spec**, its source: the ticket with its comments (`gh issue view <t> --comments`) and the spec sections (*Path* of § Spec) that its `Spec:` line cites, read from the branch. Without a ticket, the spec is the PR body. And three rules that the kit's brief does not bring:
     1. **The spec follows reasoned code**: the code is compared with the spec **of the branch**, not with `main`'s; each hunk of the spec carries its why in a commit message or in the PR body, and one that does not is a finding.
     2. What the branch resolves **by analogy** goes to *Analogies* of § Spec, not to `AGENTS.md`.
     3. An edit to the spec **is checked against the sections that cite it**.

   Done when both axes have returned their report.
5. **The comment.** The two reports under `## Standards` and `## Spec` as they are, without mixing or reordering findings between axes (the separation is what keeps one axis from covering up the other), and the kit's summary line. The first line and the exact format are in [protocol.md](protocol.md). Post it with `gh pr comment <pr> --body-file` and show the report in the terminal too. Done when the comment is on the PR.

## Limits

- **No state between reviews.** Relaunched on a PR already reviewed and fixed, it reviews the whole PR against the same merge-base and without passing the earlier comments to the axes: what was fixed disappears by itself, what was not reappears, and the earlier context would bias the reviewer toward confirming what it already saw. The human compares the two comments.
- The fixes belong to `jmb-implement-ticket <n>`, which recognizes this comment and makes them on the branch. You fix nothing, push nothing and merge nothing.
