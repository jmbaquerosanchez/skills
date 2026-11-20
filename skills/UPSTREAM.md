# Upstream of the copies

The skills in the table are copies from [mattpocock/skills](https://github.com/mattpocock/skills); the others in this folder are the kit's own. The table gives, for each copy, the path and the commit of his repo it came from, and what has been changed from that commit. A change to a copy is noted in its row. Some files of the own skills derive from his too: they are in [Derived files](#derived-files).

Porting a later change of Matt's is a separate, deliberate decision. In a clone of his repo, what has changed since the copy is:

```sh
git diff <commit>..main -- <path>
```

The path is the one the skill had in that commit. If Matt moved or deleted it later, that diff shows it as deleted whole; `git diff -M --name-status <commit> main | grep <name>` tells where it went (`R`) or whether it no longer exists (`D`), with the name it had in his repo.

## How the commit was pinned

The copies came from a single install of 20 of his skills with `npx skills` in the project the kit comes from, on 2026-09-12, and arrived here byte for byte. Their commit is the one that was the tip of Matt's `main` that day, `3cca18b`, from 2026-09-04 to 2026-09-15. It is also the last commit of his `main` in which the 20 trees match those of the copies (`git rev-parse <commit>:<path>`); the next one, `959a8e9`, changes `retro`. Matching trees means that no copy carried edits from that project, not even an executable bit. Two of the 20 left the kit later: `diagnosing-bugs`, which was not used, and `setup-matt-pocock-skills`, whose work `jmb-setup` took over.

## Table

Every copy carries the kit's `jmb-` prefix in its folder and its `name:` ("the prefix" in the last column), and a `LICENSE` with Matt's notice, which his folders do not have ("the `LICENSE`"); [licenses.py](../scripts/licenses.py) says why and checks it. Some mentions of copies, a copy's mentions of itself included, carry it too, and the last column names them.

| Copy | Path in Matt's repo | Commit | Changes from the commit |
|---|---|---|---|
| `jmb-code-review` | `skills/engineering/code-review` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix; the frontmatter adds `disable-model-invocation: true`; `setup-matt-pocock-skills` becomes `jmb-setup` in `SKILL.md` |
| `jmb-codebase-design` | `skills/engineering/codebase-design` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-domain-modeling` | `skills/engineering/domain-modeling` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-grill-with-docs` | `skills/engineering/grill-with-docs` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `grilling` and `domain-modeling` in `SKILL.md` |
| `jmb-grilling` | `skills/productivity/grilling` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-improve-codebase-architecture` | `skills/engineering/improve-codebase-architecture` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `codebase-design`, `grilling` and `domain-modeling` in `SKILL.md`, and on `codebase-design` in `HTML-REPORT.md` |
| `jmb-prototype` | `skills/engineering/prototype` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-research` | `skills/engineering/research` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix; in `SKILL.md`, the findings become a research report: the description says so, and the body gives its default `docs/research/`, its dated name, its folder form when scripts back its numbers, its language, its snapshot line and the "Superseded by" rule, and adds "Landing the report": the researcher writes nothing to git and the session that launched it opens a flow PR per report, on `<n>-<slug>` or `docs-<slug>`. Upstream's `8295b8e` makes the opposite explicit for `wayfinder` (a research branch is pushed with no PR and never merged); the kit departs because such a branch sits outside the flow's single path to `main`, keeps the report out of sight from `main` and breaks its links when it goes |
| `jmb-resolving-merge-conflicts` | `skills/engineering/resolving-merge-conflicts` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-retro` | `skills/in-progress/retro` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `writing-for-agents` in `SKILL.md` |
| `jmb-tdd` | `skills/engineering/tdd` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `codebase-design` in `SKILL.md`; "the `code-review` skill" becomes "the `jmb-code-review` skill" in `SKILL.md` |
| `jmb-to-questionnaire` | `skills/productivity/to-questionnaire` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix |
| `jmb-to-spec` | `skills/engineering/to-spec` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix; `setup-matt-pocock-skills` becomes `jmb-setup` in `SKILL.md` |
| `jmb-to-tickets` | `skills/engineering/to-tickets` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix; `setup-matt-pocock-skills` becomes `jmb-setup` twice in `SKILL.md` |
| `jmb-triage` | `skills/engineering/triage` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `triage` itself, `grilling` and `domain-modeling` in `SKILL.md`; `setup-matt-pocock-skills` becomes `jmb-setup` in `SKILL.md` |
| `jmb-wayfinder` | `skills/engineering/wayfinder` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `research`, `prototype`, `grilling` and `domain-modeling` in `SKILL.md`; `setup-matt-pocock-skills` becomes `jmb-setup` in `SKILL.md`; in `SKILL.md`, research reports land on `main` instead of a throwaway `research/<name>` branch: the Research bullet of Ticket Types says that whoever fires a subagent claims its ticket first, while charting too, that the subagents write nothing to git, that the launching session lands each report on the ticket's `<n>-<slug>` branch and PR in turn, and that it records the resolution when the PR opens and leaves the close to the merge; charting step 5 and step 4 of working the map refer to it; the map body lists resolved tickets, not closed ones, because a research ticket stays open until its merge. Upstream's `8295b8e` goes the other way ("Push the branch but open no PR: it is never merged"); the kit departs for the reasons in the row of `jmb-research`, and porting that commit leaves this part out |
| `jmb-wizard` | `skills/engineering/wizard` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `wizard` itself in `template.sh` |
| `jmb-writing-for-agents` | `skills/productivity/writing-for-agents` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `LICENSE`; the prefix, also on `writing-for-agents` itself in `SKILL-MECHANICS.md` |

## Derived files

Files of the own skills that come from Matt's. The kit maintains them as its own, but a later change of his to the source may be worth porting, from the commit of its row, as with a copy. Their sources, as they were installed in the project the kit comes from, have the trees of that commit. An own skill with a row here carries Matt's notice in its `LICENSE`, after the kit's.

`jmb-wayfinder` and the "Wayfinding operations" section of `issue-tracker.md` go together: porting a change of Matt's to one asks for looking at the other in the same diff.

| File | Path in Matt's repo | Commit | Changes from the commit |
|---|---|---|---|
| [jmb-setup/templates/issue-tracker.md](jmb-setup/templates/issue-tracker.md) | `skills/engineering/setup-matt-pocock-skills/issue-tracker-github.md` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `jmb-setup` markers; the prefix on `triage` and `wayfinder`; the spec goes to a file of the repo, in the opening sentence, in the section on publishing to the tracker and in a section of its own, "When `/jmb-to-spec` publishes a spec" |
| [jmb-setup/templates/triage-labels.md](jmb-setup/templates/triage-labels.md) | `skills/engineering/setup-matt-pocock-skills/triage-labels.md` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `jmb-setup` markers |
| [jmb-setup/templates/domain.md](jmb-setup/templates/domain.md) | `skills/engineering/setup-matt-pocock-skills/domain.md` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The `jmb-setup` markers; the prefix on `domain-modeling`; without the list of skills that reach `domain-modeling`, which left some out |
| [jmb-setup/block-dangerous-git.sh](jmb-setup/block-dangerous-git.sh) | `skills/misc/git-guardrails-claude-code/scripts/block-dangerous-git.sh` | `3cca18b368ae95cdbdebbff572ccafa662551015` | The five its header lists |
