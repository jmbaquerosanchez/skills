---
name: jmb-research
description: Investigate a question against high-trust primary sources and capture the answer as a research report in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads. Start it with a fresh context window.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the **research report**: a single Markdown file citing each claim's source, in the language of the "Documentation" scope of the Languages table in AGENTS.md. Name it `<YYYY-MM-DD>-<slug>.md`, with today's date. When it cites numbers that helper scripts produced, make it a folder `<YYYY-MM-DD>-<slug>/` instead, with the report as `README.md` and the scripts beside it, written in the language of code.
3. Open it with its snapshot line, the first line of the file:

   > Snapshot of <YYYY-MM-DD> for [<ticket title>](<ticket URL>). Not updated: later research supersedes it.

   Without a ticket, the line drops the ticket: "Snapshot of <YYYY-MM-DD>. Not updated: later research supersedes it."
4. Save it where the repo already keeps such notes, matching the existing convention; if it keeps none, in `docs/research/`.
5. If an earlier report answers the same question, this one supersedes it: add `Superseded by <relative link to the new report>.` right after that report's snapshot line. Once a report is on `main`, that line is the only edit it ever takes.
6. Return the report's path, a one-line gist of its answer, and the path of the report it supersedes, if any.

The agent reads anything in the checkout and runs read-only commands, and leaves the report in place, uncommitted, for the session that launched it: it writes nothing to git, no branch, commit or push.

## Landing the report

A research report reaches `main` through a PR of its own, a flow PR like any other (the "Sequential flow" section of AGENTS.md). The session that launched the research lands it: when this skill is invoked on its own, that is the invoking session, which lands the report once the background agent returns it. When a subagent runs this skill for another skill, as `jmb-wayfinder`'s research subagents do, it stops at the uncommitted report and returns step 6 to the session that launched it.

That session lands its reports one after another, in its own checkout: one checkout has one HEAD, which agents committing in parallel would fight over, and preparing a worktree per report costs far more than the report. For each report:

1. From `main`, `git checkout -b <n>-<slug>` for the research ticket `<n>`, or `docs-<slug>` without a ticket, in its own Bash call.
2. `git add` by name the report (its folder, when it has scripts) and the earlier report it supersedes; commit with the why.
3. `git push -u origin HEAD` and `gh pr create --draft`, titled `docs: <what it answers> (#<n>)` with `Closes #<n>` in the body; without a ticket, the title ends at the gist and the body closes nothing.
4. `git checkout main`, ready for the next report.

Once every report has its PR, `gh pr checks <pr> --watch` on each: green, `gh pr ready <pr>`; red, fix it on its branch and return to `main`. `jmb-review-pr` runs only at the human's request, and the fixes it asks for are made in an ordinary session, not with `jmb-implement-ticket`. Done when every report has a ready PR with green CI and you are back on `main`.
