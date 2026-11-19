# Every skill carries the jmb- prefix, copies included

All the kit's skills carry the `jmb-` prefix in their folder and their `name:`, the own skills and the copies alike, although a copy stops being literal there. `npx skills` installs the skills flat, by name, in a space shared with Claude Code's built-in commands, which keep growing, and with any other source; `code-review` already clashed with the built-in `/code-review`. Once projects use the kit, a rename means removing the old skill and adding the new one in each of them. With the prefix on every skill, the name depends neither on where the skill came from nor on whether it has been touched. Replacing or modifying a copy, which is the plan for them, does not rename it.

## Considered options

- **The prefix only on what departs from Matt's version**: each copy would be renamed the first time it is touched.
- **No prefix, except on a clash**: each future clash would be a rename with projects already set up.

## Consequences

The copies change their folder, their `name:` and the mentions between them (`call the Skill tool with "jmb-grilling"`). Each change is noted in the copy's row of [skills/UPSTREAM.md](../../skills/UPSTREAM.md).
