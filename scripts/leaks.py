#!/usr/bin/env python3
"""Leaks of the source project. Usage:

    python3 scripts/leaks.py commits <git rev-list arguments>
    python3 scripts/leaks.py hook < payload.json

The kit was built against a real project, and what identifies that project (its
name and derivatives, the identifiers of its domain, its owner's email) must not
reach this repo, which is public. The values cannot be written here, because the
list would be the leak itself. They live outside the repo, one entry per line,
in ~/.config/jmb-skills/leaks.txt or the path in JMB_LEAKS_FILE; CI writes its
file from the LEAKS_LIST secret. user/README.md tells how to set it up on a
machine.

Each entry is searched as a literal and a whole word, ignoring case. Only a
letter or a digit next to it breaks the match: `_` separates, so that a name
followed by `_3` is still found. Without a list, or with an empty one, the check
fails instead of letting through: a guard that lets through looks installed and
protects nothing.

It prints where it found an entry (the file, the line and the entry's line in
the list), never what matched. A path or a branch name is printed with every
match replaced by ***.

Two modes:

- `commits`: each commit that `git rev-list` gives for the arguments, as it
  would be published: every path of its tree, the content of each file (or the
  target of each symlink), its message, its author and its committer. CI runs
  it on the commits of each PR and on each push to main, and it is what checks
  the single commit before publishing. Exits 1 on a leak and 2 when it cannot
  check.

- `hook`: the repo's PreToolUse hook for Bash, hooked in .claude/settings.json
  with `|| exit 2`, so that an error blocks too. It reads the call's JSON on
  stdin and exits 2 to block, 0 to let through. It acts on three commands, and
  in all three it checks the command's text, heredocs included:
  - `git commit`: also the file of `-F`, the identity git would sign with and
    the content of the tracked files, staged and in the working tree, which
    covers `-a`. A file that is not tracked yet is left to the push.
  - `git push`: also the current branch's name and each commit not on any
    remote-tracking branch, from HEAD and from the refs it names, as
    `commits` checks them.
  - The writes of `gh`: issue, pr, release, label and repo, except their
    subcommands that only read, and `gh api` with a body. Also the files of
    `--body-file`, `--input`, `--notes-file`, and `-F`, `--field` with
    `name=@file`.

  It splits the line into commands like the kit's hook, and it has the same
  blind spot, for the reasons in the header of block-dangerous-git.sh: a
  command counts only when it starts with `git`, `sudo git` or `gh`, so an
  indirection such as `sh -c` slips past, and a `cd` in an earlier command is
  not followed. The push and CI catch most of what slips past a commit.
"""

import json
import os
import re
import shlex
import subprocess
import sys

DEFAULT_LIST = "~/.config/jmb-skills/leaks.txt"
SETUP = 'user/README.md, section "Leaks list", tells how to set it up'


class Unchecked(Exception):
    """The check cannot run. Every caller treats it as a block."""


def load_list():
    path = os.path.expanduser(os.environ.get("JMB_LEAKS_FILE") or DEFAULT_LIST)
    try:
        with open(path, encoding="utf-8") as file:
            lines = file.read().split("\n")
    except OSError:
        raise Unchecked(f"there is no leaks list at {path}; {SETUP}")
    parts = []
    for n, line in enumerate(lines, 1):
        entry = line.strip()
        if not entry:
            continue
        pattern = re.escape(entry)
        if entry[0].isalnum():
            pattern = r"(?<![^\W_])" + pattern
        if entry[-1].isalnum():
            pattern += r"(?![^\W_])"
        parts.append(f"(?P<e{n}>{pattern})")
    if not parts:
        raise Unchecked(f"the leaks list at {path} is empty; {SETUP}")
    return re.compile("|".join(parts), re.IGNORECASE)


class Scan:
    def __init__(self, pattern):
        self.pattern = pattern
        self.findings = []

    def redact(self, text):
        return self.pattern.sub("***", text)

    def text(self, where, text, lines=True):
        seen = set()
        for m in self.pattern.finditer(text):
            line = text.count("\n", 0, m.start()) + 1 if lines else None
            if (line, m.lastgroup) in seen:
                continue
            seen.add((line, m.lastgroup))
            at = f", line {line}" if line else ""
            self.findings.append(f"{where}{at}: entry on line {m.lastgroup[1:]} of the list")

    def path(self, where, path):
        self.text(f"{where} {self.redact(path)}, in its path", path, lines=False)

    def blobs(self, cwd, located):
        """Scans each blob once: `located` maps its id to where it was found."""
        contents = cat_blobs(cwd, list(located))
        for blob, where in located.items():
            self.text(where, contents[blob].decode("utf-8", "replace"))


def git(cwd, *args, stdin=None):
    try:
        result = subprocess.run(["git", "-c", "log.showSignature=false", *args],
                                cwd=cwd or None, input=stdin, capture_output=True)
    except OSError as e:
        raise Unchecked(f"cannot run git in {cwd!r}: {e.strerror}")
    if result.returncode != 0:
        message = result.stderr.decode("utf-8", "replace").strip().split("\n")[-1]
        raise Unchecked(f"git {args[0]} failed in {cwd!r}: {message}")
    return result.stdout


def cat_blobs(cwd, blobs):
    if not blobs:
        return {}
    out = git(cwd, "cat-file", "--batch", stdin=("\n".join(blobs) + "\n").encode())
    contents, i = {}, 0
    for blob in blobs:
        end = out.index(b"\n", i)
        header = out[i:end].split()
        if len(header) != 3:
            raise Unchecked(f"git cat-file did not find {blob}")
        size = int(header[2])
        contents[blob] = out[end + 1:end + 1 + size]
        i = end + 1 + size + 1
    return contents


def nul_records(out):
    return [r for r in out.decode("utf-8", "replace").split("\0") if r]


def scan_commits(scan, cwd, revs):
    """Scans the commits that `git rev-list <revs>` gives. Returns how many."""
    fields = git(cwd, "log", "-z", "--format=%H%x00%an <%ae>%x00%cn <%ce>%x00%B", *revs, "--")
    fields = fields.decode("utf-8", "replace").split("\0")
    count, located, paths = 0, {}, set()
    for i in range(0, len(fields) - 3, 4):
        sha, author, committer, message = fields[i:i + 4]
        sha = sha.strip()
        count += 1
        where = f"commit {sha[:10]}"
        scan.text(f"{where}, author", author, lines=False)
        scan.text(f"{where}, committer", committer, lines=False)
        scan.text(f"{where}, message", message)
        for record in nul_records(git(cwd, "ls-tree", "-r", "-z", "--full-tree", sha)):
            meta, path = record.split("\t", 1)
            _, kind, obj = meta.split()
            if path not in paths:
                paths.add(path)
                scan.path(where + ",", path)
            if kind == "blob" and obj not in located:
                located[obj] = f"{where}, {scan.redact(path)}"
    scan.blobs(cwd, located)
    return count


# --- The hook ---------------------------------------------------------------

GH_WRITES = {"issue", "pr", "release", "label", "repo"}
GH_READS = {"view", "list", "status", "checks", "diff", "checkout", "clone", "download"}
GH_BODY = {"-f", "-F", "--field", "--raw-field", "--input"}


def segments(command):
    """The commands of the line, split the way the kit's hook splits them.

    Heredoc bodies are dropped and separators inside quotes are masked, so that
    a message cannot forge a command. This is only to find the commands: the
    text that gets scanned is the whole line.
    """
    kept, delim = [], None
    for line in command.split("\n"):
        if delim is not None:
            if line.strip() == delim:
                delim = None
            continue
        kept.append(line)
        m = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        if m:
            delim = m.group(2)
    masked, quote = [], None
    for ch in "\n".join(kept):
        if quote:
            if ch == quote:
                quote = None
            elif ch in ";&|()\n":
                ch = "_"
        elif ch in "'\"":
            quote = ch
        masked.append(ch)
    for segment in re.split(r"[;&|()\n]", "".join(masked)):
        try:
            tokens = shlex.split(segment)
        except ValueError:
            tokens = [t.strip("'\"") for t in segment.split()]
        if tokens[:1] == ["sudo"]:
            tokens = tokens[1:]
        if tokens:
            yield tokens


def git_command(tokens, cwd):
    """(directory, subcommand, arguments) of a git command, or None."""
    if tokens[0] != "git":
        return None
    directory, i = cwd, 1
    while i < len(tokens) and tokens[i].startswith("-"):
        if tokens[i] == "-C" and i + 1 < len(tokens):
            target = os.path.expanduser(tokens[i + 1])
            directory = os.path.join(directory, target)
            i += 1
        elif tokens[i] in ("-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix"):
            i += 1
        i += 1
    if i >= len(tokens):
        return None
    return directory, tokens[i], tokens[i + 1:]


def gh_writes(tokens):
    """Whether a gh command writes text that GitHub publishes."""
    if tokens[0] != "gh" or len(tokens) < 2:
        return False
    family, rest = tokens[1], tokens[2:]
    if family == "api":
        method = "GET"
        for i, t in enumerate(rest):
            if t in ("-X", "--method") and i + 1 < len(rest):
                method = rest[i + 1].upper()
            elif t.startswith("--method="):
                method = t.split("=", 1)[1].upper()
            elif t.startswith("-X") and len(t) > 2:
                method = t[2:].upper()
        return method != "GET" or any(t.split("=", 1)[0] in GH_BODY or re.match(r"-[fF].", t) for t in rest)
    if family not in GH_WRITES:
        return False
    i = 0
    while i < len(rest) and rest[i].startswith("-"):
        i += 2 if rest[i] in ("-R", "--repo") else 1
    return i < len(rest) and rest[i] not in GH_READS


def option_values(tokens, names):
    """The values of the options in `names`, as `--name value` or `--name=value`."""
    for i, t in enumerate(tokens):
        if t in names and i + 1 < len(tokens):
            yield t, tokens[i + 1]
        elif "=" in t and t.split("=", 1)[0] in names:
            yield tuple(t.split("=", 1))


def scan_file(scan, where, directory, path):
    """Scans a file the command reads. One that does not exist yet comes, if
    from anywhere, from the command itself, which is already scanned."""
    if path == "-":
        return
    full = os.path.join(directory, os.path.expanduser(path))
    try:
        with open(full, encoding="utf-8", errors="replace") as file:
            scan.text(f"{where} {scan.redact(path)}", file.read())
    except FileNotFoundError:
        pass
    except OSError as e:
        raise Unchecked(f"cannot read {scan.redact(path)}: {e.strerror}")


def toplevel(directory):
    if not directory:
        raise Unchecked("the call has no working directory, so it cannot tell which repo this acts on")
    return git(directory, "rev-parse", "--show-toplevel").decode().strip()


def check_commit(scan, directory, args):
    root = toplevel(directory)
    for _, path in option_values(args, ("-F", "--file")):
        scan_file(scan, "the message file", directory, path)
    for ident in ("GIT_AUTHOR_IDENT", "GIT_COMMITTER_IDENT"):
        value = git(directory, "var", ident).decode("utf-8", "replace")
        scan.text(f"the {ident[4:-6].lower()} git would sign with", value, lines=False)
    located = {}
    for record in nul_records(git(root, "ls-files", "-s", "-z")):
        meta, path = record.split("\t", 1)
        obj = meta.split()[1]
        scan.path("staged", path)
        located.setdefault(obj, f"staged {scan.redact(path)}")
    scan.blobs(root, located)
    for path in nul_records(git(root, "diff", "--name-only", "-z")):
        full = os.path.join(root, path)
        if os.path.islink(full):
            scan.text(f"working tree {scan.redact(path)}", os.readlink(full))
        elif os.path.isfile(full):
            with open(full, encoding="utf-8", errors="replace") as file:
                scan.text(f"working tree {scan.redact(path)}", file.read())


def check_push(scan, directory, args):
    toplevel(directory)
    branch = git(directory, "branch", "--show-current").decode("utf-8", "replace")
    scan.text("the name of the current branch", branch, lines=False)
    revs = ["HEAD"]
    for arg in args:
        if arg in ("--all", "--mirror", "--branches"):
            revs.append("--branches")
        elif arg in ("--tags", "--follow-tags"):
            revs.append("--tags")
        elif not arg.startswith("-"):
            source = arg.lstrip("+").split(":", 1)[0]
            resolves = subprocess.run(["git", "rev-parse", "--verify", "--quiet", source + "^{commit}"],
                                      cwd=directory or None, capture_output=True).returncode == 0
            if source and resolves:
                revs.append(source)
    scan_commits(scan, directory, revs + ["--not", "--remotes"])


def check_gh(scan, cwd, tokens):
    for name, value in option_values(tokens, ("--body-file", "--input", "--notes-file", "-F", "--field")):
        if name in ("-F", "--field"):
            if "=" not in value:
                scan_file(scan, "the body file", cwd, value)
            elif value.split("=", 1)[1].startswith("@"):
                scan_file(scan, "the file", cwd, value.split("=", 1)[1][1:])
        else:
            scan_file(scan, "the file", cwd, value)


def block(message):
    print(f"BLOCKED by the leaks guard: {message}", file=sys.stderr)
    return 2


def hook():
    try:
        payload = json.load(sys.stdin)
        command = payload.get("tool_input", {}).get("command") or ""
        cwd = payload.get("cwd") or ""
    except Exception:
        return block("it could not parse its input. Failing closed.")
    actions = []
    for tokens in segments(command):
        parsed = git_command(tokens, cwd)
        if parsed and parsed[1] in ("commit", "push"):
            actions.append(parsed)
        elif gh_writes(tokens):
            actions.append((cwd, "gh", tokens))
    if not actions:
        return 0
    scan = None
    try:
        scan = Scan(load_list())
        scan.text("the command", command)
        for directory, what, args in actions:
            {"commit": check_commit, "push": check_push, "gh": check_gh}[what](scan, directory, args)
    except Unchecked as e:
        message = scan.redact(str(e)) if scan else str(e)
        return block(f"{message}. Failing closed.")
    if not scan.findings:
        return 0
    return block(
        "this would publish values of the source project.\n"
        + "".join(f"  - {f}\n" for f in scan.findings)
        + "Stop and tell the user where, as above, never what matched: it is not written anywhere, "
        "not even in your reply. The user decides what to change."
    )


def commits(revs):
    try:
        scan = Scan(load_list())
        count = scan_commits(scan, ".", revs)
    except Unchecked as e:
        print(f"::error::{e}")
        return 2
    for finding in scan.findings:
        print(f"::error::{finding}")
    print(f"{count} commits checked, {len(scan.findings)} leaks")
    return 1 if scan.findings else 0


if __name__ == "__main__":
    mode, args = (sys.argv[1], sys.argv[2:]) if len(sys.argv) > 1 else ("", [])
    if mode == "hook":
        sys.exit(hook())
    if mode == "commits" and args:
        sys.exit(commits(args))
    print("\n\n".join(__doc__.split("\n\n")[:2]), file=sys.stderr)
    sys.exit(2)
