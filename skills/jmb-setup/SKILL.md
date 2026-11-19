---
name: jmb-setup
description: "Set up the kit's flow in a project, or bring it up to date: docs/agents/ (flow.md, the issue tracker, the triage labels and the domain docs), the AGENTS.md block with its Languages table, the hook and the settings, the repo's merge settings included. Rerun it to turn on parallel mode."
disable-model-invocation: true
---

# jmb-setup

Leave in the project what the kit's skills expect from it, or bring it up to date. Everything goes into files of the repo, so that the flow works the same on another machine, in the cloud or for another person. It is a guided skill, not a script: it explores, shows what it finds, asks what is missing and writes when the human confirms.

| Piece | Where | Comes from |
|---|---|---|
| The project's data | `docs/agents/flow.md` | [templates/flow.md](templates/flow.md) |
| The flow, the "Languages" table and the "Agent skills" section | `AGENTS.md`, between the `jmb-setup` markers | [templates/agents-md-block.md](templates/agents-md-block.md) |
| The cross-cutting criteria | `AGENTS.md`, right before the markers | [templates/cross-cutting-criteria.md](templates/cross-cutting-criteria.md) |
| How to use the tracker, where the spec goes and the "Wayfinding operations" section | `docs/agents/issue-tracker.md`, between the `jmb-setup` markers | [templates/issue-tracker.md](templates/issue-tracker.md) |
| The triage labels | `docs/agents/triage-labels.md`, between the `jmb-setup` markers | [templates/triage-labels.md](templates/triage-labels.md) |
| Where the glossary and the ADRs live | `docs/agents/domain.md`, between the `jmb-setup` markers | [templates/domain.md](templates/domain.md) |
| The git hook and `attribution` | `.claude/settings.json` | [templates/settings.json](templates/settings.json) |
| `.claude/worktrees/`, only with § Worktree | `.gitignore` | One line |
| Squash only, and the branch deleted on merge | The repo's settings on GitHub | Step 5 |

The hook, [block-dangerous-git.sh](block-dangerous-git.sh), lives in this folder, and `settings.json` hooks it here: `npx skills update` brings it up to date along with the skills. Everything else is brought up to date by rerunning this skill.

**It is idempotent**: rerun on a project that has not changed, it changes nothing. What is already written is not asked again, and a file is written only if its content changes. In the project's files it rewrites what belongs to this skill: what is between its markers, keeping the project's values (those of the "Languages" table and the rows the project has added to it, the "Label in our tracker" column and "PRs as a request surface"), and its entries in `settings.json`. Outside that, only what the human confirms changes. Rerunning it is also the way to add a section of the contract that is missing, such as § Worktree, which turns on parallel mode.

## Steps

1. **Explore.** Read what is there, without assuming:
   - The remote, with `git remote -v`. If it is not on GitHub, stop: the flow skills use `gh`, step 5 changes the repo's settings on GitHub and `jmb-review-pr` counts on issues and PRs sharing one numbering.
   - The hook, installed in the project at the path that [templates/settings.json](templates/settings.json) hooks. If it is not there, the hook would fail on startup and guard nothing: stop and ask for the kit to be installed in the project with `npx skills add`, not only at user level.
   - `AGENTS.md` and `CLAUDE.md`: which one exists, whether `CLAUDE.md` is a symlink to `AGENTS.md`, whether the markers are already there, whether there is a "Cross-cutting criteria" section and whether there are, outside the markers, a languages table, an "Agent skills" section or a section that already describes the flow. That last one has no fixed name: it is recognized by its content (branches, PRs, commits, merge).
   - `docs/agents/issue-tracker.md`, `triage-labels.md` and `domain.md`: whether each one exists, whether it has the markers and, outside them, which sections share a heading with its template. `setup-matt-pocock-skills`, from Matt's kit, wrote them without markers.
   - The repo's labels, with `gh label list`, if `triage-labels.md` does not exist: whether it already has labels for the five roles of the template, with the template's names or with others.
   - `docs/agents/flow.md`, if it exists, and which sections of the template it lacks.
   - For the slots of `flow.md`: the project's scripts (`package.json` or whatever it uses), the CI configuration, the tests and the spec, if there is one.
   - `.claude/settings.json` and `.gitignore`.
   - The repo's merge settings, with the read of step 5.

   Done when you know, for each row of the table above, whether it is missing, up to date or what changes.
2. **`AGENTS.md`.** The block goes in `AGENTS.md`, because the flow skills cite it by that name, and Claude Code loads `CLAUDE.md`, which is a symlink to it. Always edit `AGENTS.md`: editing tools do not write through the symlink.
   - There is only a `CLAUDE.md`, and it is a file: propose moving it to `AGENTS.md` and leaving `CLAUDE.md` as a symlink (`git mv CLAUDE.md AGENTS.md && ln -s AGENTS.md CLAUDE.md`). If the human does not accept, stop: the skills would not find the block.
   - There is an `AGENTS.md` and `CLAUDE.md` is missing: propose the symlink.

   Done when `AGENTS.md` is a file and `CLAUDE.md` a symlink to it.
3. **Ask** what step 1 did not settle, one thing at a time and with the recommended answer first, so the human can accept it in a word:
   - **Languages**, if the table is not there: one per scope of the template. Propose the one the project already uses (its README, its commits, its code). If `AGENTS.md` has a languages table outside the markers, take its values and its own rows from it, and propose removing it, so there are not two.
   - **The previous flow section**, if step 1 found it: next to the block, there would be two flows that contradict each other wherever they differ. Propose removing it, trimming it down to what is specific to the project, which is what the block leaves out (deploying on merge, an escape hatch), or leaving it. Recommend trimming it if it holds something of its own, and removing it if not.
   - **The triage labels**, only if `triage-labels.md` does not exist and the repo has labels for those roles under other names: propose the mapping, role by role, for the "Label in our tracker" column. With no labels for them, or with the template's names, the file takes the template's without asking.
   - **The slots of `flow.md`**, section by section, with the guideline each one has in the template: propose what you found and ask for the why that no file tells. *Label* comes from `triage-labels.md`, as its guideline says. If the project does not have its spec in the repo yet, *Path* is where it will live and *Analogies*, the title that section will have: `issue-tracker.md` sends the spec of `/jmb-to-spec` there.
   - **Parallel mode**, if `flow.md` does not have § Worktree: ask whether to turn it on. Turning it on means § Worktree, § Batch table axes and the `.gitignore` line.
   - **§ Schema**, only if the project generates its migrations from a schema.
   - **The cross-cutting criteria**, if `AGENTS.md` does not have their section: what every ticket meets even when it does not name it. If they already live in another section, the new one collects them or names it, as the human says.

   Done when every slot of what you are going to write has a value.
4. **Draft and write.** Show what you are going to write, as a diff against what is there or whole if it is new, let the human correct it and write:
   - **`docs/agents/flow.md`**: the template with each slot filled in, without its comments and without the optional sections that do not apply. If it already exists, keep what is written and add only the new sections.
   - **The block of `AGENTS.md`**: the template as is, with the "Languages" table filled in. If the markers are already there, replace what is between them and keep the table's values and the rows the project has added to it, after the template's; if not, add it at the end. The block brings its own "Agent skills" section: if there is one outside the markers, propose removing it, or trimming it down to what the project added to it.
   - **The cross-cutting criteria**: the template, right before the start marker, only if the section does not exist.
   - **`docs/agents/issue-tracker.md`, `triage-labels.md` and `domain.md`**: each one's template as is, opening the file, with the project's values wherever they are found: between the markers, in a section outside them with the same heading or in the answers of step 3. Outside the markers, a section with the same heading as one of the template's, the file's title included, gives way to the block, which takes its values; the other sections are the project's and stay after the end marker, in their order.
   - **`.claude/settings.json`**: the template, if it does not exist. If it exists, `attribution` stays as in the template and its handler is added to `hooks.PreToolUse` if none carries its `command`; the rest of the file is not touched.
   - **`.gitignore`**, with § Worktree: a `.claude/worktrees/` line, if it does not ignore them already. Without it, `git status` shows the batch's worktrees, and `jmb-implement-frontier` and `jmb-sync` stop at their first step.

   Done when `git status` shows only the files the draft announced.
5. **Merge settings.** Read them:

   ```bash
   gh api repos/{owner}/{repo} --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge, squash_merge_commit_title, squash_merge_commit_message}'
   ```

   The flow wants them like this: `allow_squash_merge` at `true`; `allow_merge_commit` and `allow_rebase_merge` at `false`, because with another method enabled, picking wrong in the dropdown is enough to put into `main` commits that have not passed CI; `delete_branch_on_merge` at `true`; and the squash with title `COMMIT_OR_PR_TITLE` and body `COMMIT_MESSAGES`, which makes the commit message the record that stays. If everything matches, there is nothing to apply. If not, show in a table what differs, with the current value and the flow's, ask for confirmation and, with it:

   ```bash
   gh api -X PATCH repos/{owner}/{repo} -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false -F delete_branch_on_merge=true -f squash_merge_commit_title=COMMIT_OR_PR_TITLE -f squash_merge_commit_message=COMMIT_MESSAGES
   ```

   Done when a fresh read gives the flow's values, or the human has said no.
6. **Report**: which files were written and what changed in each one, the merge settings (applied, already set or rejected) and what is left pending, such as a spec that does not exist yet. The changes stay uncommitted and reach `main` through a branch and its PR, like any other. Done when the human has the report.
