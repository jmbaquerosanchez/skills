# The kit's text is in English and reaches the project as is

Everything the kit contains is in English and reaches a project unchanged: skills, templates, headings, markers, labels and the hook's messages. Nothing is translated on install. The project's "Languages" table governs only what the agent writes for the project: code, documentation, tickets, PRs, commits, comments and the `{{…}}` slots of a template.

The skills look for their headings and markers letter by letter, and `jmb-setup` has to give the same result every time it runs again, which a translation on the fly would break. The cost, accepted: a project in another language has mixed files, such as the flow block of its AGENTS.md or the skeleton of a review comment.

The table goes in the project's AGENTS.md, written by `jmb-setup` with the languages it asks for, and not in `flow.md`: the language governs every turn, not only those in which a flow skill runs. Its exceptions are syntax and stay fixed: the conventional commit prefix, `Closes #N` and whatever the framework imposes.
