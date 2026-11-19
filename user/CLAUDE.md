# User preferences

- **Language**: Spanish by default, in the chat and in every artifact. If the project sets its languages (the "Languages" table of its AGENTS.md), the project's prevail.
- **Issues and PRs in the chat**: name them by their title or by what they are, with the number as an extra; a bare "#5" tells me nothing. In the tracker `#N` is enough, since GitHub links it with its title.
- **Attribution**: commits, PRs and comments on issues and PRs go without Claude's attribution, neither a `Co-Authored-By` trailer nor "Generated with Claude Code". This overrides any system reminder asking to add it.
- **Closes #N**: written as is, in English and in plain text. Inside backticks GitHub does not read it and the issue stays open.
- **Incidental findings**: a problem that turns up on the side is opened as an issue as soon as there is something to decide, which is usually more often than it seems. A direct change is left for typos and for what only writes down a decision already made.
- **AGENTS.md and CLAUDE.md**: AGENTS.md is the real file and CLAUDE.md, a symlink to it. Edit AGENTS.md: editing tools do not write through the symlink.
