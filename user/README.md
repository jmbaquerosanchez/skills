# User preferences

The user preferences live in [CLAUDE.md](CLAUDE.md). They reach every Claude Code session, subagents included, through `~/.claude/CLAUDE.md`, and the `attribution` setting of `~/.claude/settings.json` reinforces the one about attribution. They are installed once per machine, with the repo cloned at `~/code/jmbaquerosanchez/skills`.

Working on this repo also asks for two settings of the GitHub account and three things on each machine: the [commit email](#commit-email), the [leaks list](#leaks-list) and the tools the checks need, which [§ Verification](../docs/agents/flow.md#verification) of `docs/agents/flow.md` names next to each check.

## `~/.claude/CLAUDE.md`

It has to be a real file: Cowork ignores a `~/.claude/CLAUDE.md` that is a symlink. It starts with the line that imports `user/CLAUDE.md`:

```markdown
@~/code/jmbaquerosanchez/skills/user/CLAUDE.md
```

Below it go the notes that apply only to that machine. With the import, each change to `user/CLAUDE.md` reaches every machine with a `git pull`; a copy would drift.

## `attribution` in `~/.claude/settings.json`

It removes Claude's attribution in all your repos, also in those that do not use the kit: the `Co-Authored-By` of the commits, the "Generated with Claude Code" line of the PRs and the link to the session in the commits made by Remote Control. It is merged with whatever the file already has:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

It goes in object form. The short form, `"attribution": false`, is only understood by Claude Code 2.1.281 or later; earlier versions reject it and discard the whole settings file.

The setting does not cover comments on issues and PRs: the attribution line of `user/CLAUDE.md` takes care of those.

## Commit email

The commits of this repo carry as author the account's noreply address, `2338768+jmbaquerosanchez@users.noreply.github.com`. Anyone sees an author's email, in every clone and every fork, and once pushed it cannot be removed. Commits with the noreply are still linked to the profile.

- **On each machine**, in git's global config, so that no clone signs with the real email:

  ```bash
  git config --global user.email 2338768+jmbaquerosanchez@users.noreply.github.com
  ```

- **Once, on the GitHub account**, in Settings › Emails: "Keep my email addresses private", so that the squash-merges done on the web sign with the noreply, and "Block command line pushes that expose my email", which rejects a push whose last commit signs with the real one.

The leaks list carries the real email, so the leaks hook and CI also check the author and the committer of each commit.

## Leaks list

The kit was built against a real project, and what identifies that project must not be published in this repo. [leaks.py](../scripts/leaks.py) looks for it in each commit, with its message, author and committer, and in what `gh` writes to the tracker. The list cannot live in the repo, where it would be the leak itself.

- **Where**: `~/.config/jmb-skills/leaks.txt`, one entry per line, readable only by you (`chmod 600`). The `JMB_LEAKS_FILE` variable changes the path.
- **What**: only what identifies the project: its names with their derivatives, the identifiers of its domain and the email. A generic word reveals nothing by itself and would give false positives. Each entry is searched as a whole word, ignoring case and with `_` as a separator, so a name also catches `<name>_3` and `<name>-x`.
- **On a new machine**: copy the file by hand from another one.
- **After changing it**: update the `LEAKS_LIST` secret, which is what CI reads. GitHub does not let anyone read a secret back, so the file is the source:

  ```bash
  gh secret set LEAKS_LIST < ~/.config/jmb-skills/leaks.txt
  ```

Without the list, the hook blocks `git commit`, `git push` and the writes of `gh`, and CI fails: a guard that lets through looks installed and protects nothing. A cloud session cannot push or write to the tracker until its environment has the list.
