---
name: jmb-to-spec
description: "Turn the current conversation, or a finished wayfinder map, into a spec and publish it: no interview, just synthesis of what has already been decided."
disable-model-invocation: true
---

This skill takes the current conversation context and codebase understanding and produces a spec. The user may pass a wayfinder map instead (`/jmb-to-spec <map>`, its number or URL): then the map is the source, not the conversation. Do NOT interview the user; just synthesize what you already know.

The issue tracker and triage label vocabulary should have been provided to you. If not, tell the user to run `/jmb-setup`.

## Reading a map

Only with a map; without one, go to [Process](#process). A map is an index: each decision lives in its ticket's **resolution comment**, and the map holds only a one-line gist and a link, so the spec comes from the tickets. The map body's sections are those of [The map body](../jmb-wayfinder/SKILL.md#the-map-body) in `jmb-wayfinder`: Destination, Notes, Decisions so far, Not yet specified and Out of scope. The tracker doc's "Wayfinding operations" section says how this repo finds the map's child tickets.

1. **Readiness.** The map is finished when every child ticket is closed and its Not yet specified section is empty. A research ticket stays open until its PR merges, and its report is not on `main` until then. If the map is not finished, stop before writing anything and name, by title, the open tickets and the fog left in Not yet specified.
2. **Read.** From the map: Destination and Notes, which bind the spec as constraints; Decisions so far; Out of scope. For each ticket listed in Decisions so far: its body (the question), all its comments, and whatever its resolution comment links (the research report on `main`, a prototype's assets). The resolution comment prevails over the rest of the ticket's discussion.
3. **Contradictions.** If two resolutions contradict each other, stop and name both tickets by title. Fixing that is map work, for another `/jmb-wayfinder` session, not spec work.

Done when you hold the resolution of every ticket in Decisions so far, with what it links, and no two contradict each other.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

Check with the user that these seams match their expectations.

3. Write the spec using the template below, then publish it where the tracker doc says a spec goes. With a map, tell the user that the spec's branch takes the map's number (`<map>-<slug>`) and its PR carries `Closes #<map>`, so the map closes on merge, once the human has read the spec.

<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

With a map, each line of its Out of scope section is an item here, taken from the line without reading its closed ticket. Your own synthesis may add more.

## Further Notes

Any further notes about the feature.

With a map, link it here.

</spec-template>
