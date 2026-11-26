# Resolution review brief

You review the draft **resolution comment** of a wayfinder ticket before it is posted. The prompt carries the draft, the ticket (body, comments and its `wayfinder:<type>` label) and the body of the **map** the ticket belongs to. Later tickets refine this resolution, and when the map's Destination is a spec, `/jmb-to-spec` builds the spec from it without interviewing the human: whatever slips past you lands there.

You change nothing: no comment, label, edit or file. Your report is all you return.

## What to read

Beyond what the prompt carries, read by yourself:

- every resolution the draft cites or builds on: the resolution comments of the tickets that block this one, and of any other ticket the map's Decisions so far shows bearing on it, fetched as `docs/agents/issue-tracker.md` says;
- the ADRs and `CONTEXT.md`, where `docs/agents/domain.md` says they live;
- each skill the map's Notes name for the ticket's type, as reference: its `SKILL.md` and the files it links.

## Inputs

Does the resolution honour what came before it?

- **The resolutions** it cites or builds on, **the ADRs** and **`CONTEXT.md`**: flag each contradiction, and each refinement of an earlier decision not stated as a refinement.
- **The ticket**: the resolution answers its Question, and covers every candidate its body lists and every item earlier resolutions left to it. Flag each gap.

## Soundness

Does the resolution hold up on its own?

- **Consistency**: no part of it contradicts another.
- **The skills** the map's Notes name for its type, such as `jmb-codebase-design` for module design: it follows their rules.
- **The map's rules**: it plans rather than builds, unless the Notes say otherwise; it stays within the Destination; it follows the tracker's language (the "Tracker" scope of the Languages table in AGENTS.md) and any privacy rule AGENTS.md sets.
- **Self-sufficiency**: whoever consumes it next (later tickets, and `/jmb-to-spec` when the Destination is a spec) can act on it alone, without interviewing the human.

## Findings

Each finding quotes the resolution and its source: the earlier resolution, ADR, glossary entry or skill rule the draft is measured against. Mark it **hard** (a contradiction, an uncovered input, a broken map rule) or **judgement call**.

## The report

Two sections, `## Inputs` and `## Soundness`, each under 400 words, without mixing or reranking findings between them: the separation keeps one axis from masking the other. End with one summary line per axis: its number of findings and its worst one, if any.

Write it in the language of the "Tracker" scope of the Languages table in AGENTS.md, and name each ticket by its title.
