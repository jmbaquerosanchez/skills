#!/bin/bash
# PreToolUse guard for Bash calls. Blocks git commands the agent must not run.
#
# Adapted from the git-guardrails-claude-code skill, with five deliberate
# changes. The first three were found by running the bundled script in a real
# project; the fourth came from a guard that refused every commit made from a
# worktree, and the fifth from one flag that walked past the whole guard:
#
# 1. It bans every `git push`. That breaks the flow this guard serves, where
#    the agent is expected to push its own branch and open a PR. What must
#    never happen is a push that lands on main -- main only advances through a
#    squash-merged PR, and merging is a human action -- so the push rule is
#    scoped to main rather than blanket.
#
# 2. It reads the command with `jq` and, when jq is absent, leaves the
#    variable empty so nothing matches and it exits 0. A guard that fails open
#    is worse than no guard: it looks installed and protects nothing. jq is
#    not on every machine. This one uses python3 or node, and blocks
#    if it cannot parse its input at all.
#
# 3. It greps the whole command string, so any command whose *text* mentions a
#    blocked pattern is refused -- a commit message that discusses pushing, for
#    instance. Here heredoc bodies are dropped (they are data, not commands)
#    and patterns must sit at a command boundary, not anywhere in the line.
#
# 4. It resolved the current branch against CLAUDE_PROJECT_DIR. That variable
#    is fixed when the session starts and deliberately does NOT follow Claude
#    into a worktree, so every commit made from a worktree was judged against
#    the main checkout -- normally main -- and refused. The payload's `cwd`
#    field is the one that follows Claude, and that is what this reads.
#
# 5. It read the whole command line as one blob, and that broke both ways.
#    Patterns expected the subcommand glued to `git`, so `git -C <dir> commit`
#    matched nothing and was waved through, reset --hard included; meanwhile the
#    directory it judged came from the first `-C` found anywhere on the line, so
#    a harmless `git -C <worktree> log && git commit` lent its directory to a
#    bare commit on main. It now splits the line and judges one command at a
#    time, reading that command's own options. This is not the accepted blind
#    spot below: `-C` is the sanctioned way to reach a worktree from a shell
#    pinned elsewhere and `--no-pager` is an ordinary flag, so the hole was
#    reachable by accident, not only by someone looking for it.
#
# What this guard does NOT defend against, decided and not overlooked:
# a segment counts as git only when it starts with `git` (or `sudo git`), so
# `command git ...`, `/usr/bin/git ...` and `VAR=x git ...` slip past unchecked,
# for every rule below. The threat model is an agent taking the path of least
# resistance -- one that will use a documented workaround it stumbles on, not
# one hunting for novel evasions. A blacklist over shell text cannot close that
# class anyway (`sh -c`, `eval`, `xargs`), and the one workaround that got used
# in practice was reached for only because change 4 above was broken. Removing
# that pressure is the fix; widening the regex would buy three patched
# instances of an unclosable class at the cost of permanent complexity in the
# piece that can least afford to be wrong. The written rule in the project's
# AGENTS.md carries the rest.
#
# See the flow block that jmb-setup writes in the project's AGENTS.md.

INPUT=$(cat)

read -r -d '' EXTRACT_PY <<'PYEOF' || true
import sys, json, re
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(1)
cmd = payload.get("tool_input", {}).get("command", "") or ""
# The directory Claude is working in: the worktree root once it enters one.
# Printed on the first line, the command follows. A newline in it would corrupt
# that split, so treat such a value as absent and let the caller fail closed.
cwd = payload.get("cwd", "") or ""
if "\n" in cwd:
    cwd = ""
# Drop heredoc bodies. The line that opens the heredoc is kept -- it holds the
# real command -- but its content is data and must not be scanned for patterns.
kept, delim = [], None
for line in cmd.split("\n"):
    if delim is not None:
        if line.strip() == delim:
            delim = None
        continue
    kept.append(line)
    m = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
    if m:
        delim = m.group(2)
# Neutralise command separators inside quoted strings. The caller splits the
# line into command segments, and a quoted commit message must not be able to
# forge one. Only the separators change; quotes and paths survive intact.
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
print(cwd)
print("".join(masked))
PYEOF

read -r -d '' EXTRACT_JS <<'JSEOF' || true
let s = "";
process.stdin.on("data", d => s += d).on("end", () => {
  let payload;
  try { payload = JSON.parse(s); } catch { process.exit(1); }
  const cmd = payload?.tool_input?.command ?? "";
  let cwd = payload?.cwd ?? "";
  if (String(cwd).includes("\n")) cwd = "";
  const kept = []; let delim = null;
  for (const line of String(cmd).split("\n")) {
    if (delim !== null) { if (line.trim() === delim) delim = null; continue; }
    kept.push(line);
    const m = line.match(/<<-?\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\1/);
    if (m) delim = m[2];
  }
  // Same neutralising as the python path: separators inside quotes cannot
  // forge a command segment for the caller's split.
  let masked = "", quote = null;
  for (const ch of kept.join("\n")) {
    if (quote) {
      if (ch === quote) { quote = null; masked += ch; continue; }
      masked += ";&|()\n".includes(ch) ? "_" : ch;
      continue;
    }
    if (ch === "'" || ch === '"') quote = ch;
    masked += ch;
  }
  process.stdout.write(cwd + "\n" + masked);
});
JSEOF

if command -v python3 >/dev/null 2>&1; then
  EXTRACTED=$(printf '%s' "$INPUT" | python3 -c "$EXTRACT_PY") || EXTRACTED="__UNPARSEABLE__"
elif command -v node >/dev/null 2>&1; then
  EXTRACTED=$(printf '%s' "$INPUT" | node -e "$EXTRACT_JS") || EXTRACTED="__UNPARSEABLE__"
else
  echo "BLOCKED: the git guard has no python3 or node to parse its input, so it cannot tell whether this command is safe. Failing closed." >&2
  exit 2
fi

if [ "$EXTRACTED" = "__UNPARSEABLE__" ]; then
  echo "BLOCKED: the git guard could not parse its input. Failing closed." >&2
  exit 2
fi

# First line is the working directory, the rest is the command.
CWD=$(printf '%s\n' "$EXTRACTED" | head -n 1)
COMMAND=$(printf '%s\n' "$EXTRACTED" | tail -n +2)

[ -z "$COMMAND" ] && exit 0

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

# --- One command at a time ------------------------------------------------
# Everything below judges a single command segment. Splitting first is what
# keeps the two questions -- "is this forbidden?" and "which repository does it
# act on?" -- asked about the same command. Asked of the whole line, a harmless
# `git -C <worktree> log` lent its directory to a bare `git commit`, and the
# commit landed on main.
#
# Over-splitting is safe: an extra segment can only add a verdict, never hide
# one. Under-splitting would hide one, which is why the extractor neutralises
# separators inside quotes before any of this runs.
#
# Known limit: a `cd` in an earlier segment is not followed, so
# `cd elsewhere && git commit` is judged against the directory Claude was in.
# That one needs shell semantics, the class the note above declines to chase.
# `-C` is different: git states the target itself and the guard can read it.

# Splits `git ...` into the repository it acts on and the subcommand it runs.
# Only -C changes the repository; the other options are listed so a subcommand
# sitting behind one is still seen, and unknown options are skipped for the same
# reason -- losing the subcommand is how a guard stops guarding. Repeated -C
# folds left, which is what git itself does.
#
# Sets SEG_DIR and SEG_REST. Returns 1 when the segment is not a git command.
parse_git_segment() {
  local seg=$1 dir tok
  seg=${seg#"${seg%%[![:space:]]*}"}
  case $seg in
    sudo\ *) seg=${seg#sudo }; seg=${seg#"${seg%%[![:space:]]*}"} ;;
  esac
  case $seg in
    git|git\ *) ;;
    *) return 1 ;;
  esac
  seg=${seg#git}
  dir=$CWD
  set -f
  set -- $seg
  while [ $# -gt 0 ]; do
    case $1 in
      -C)
        shift
        [ $# -gt 0 ] || break
        # The value keeps its quotes after word splitting; a quoted path is
        # ordinary, and leaving them on would point at a directory that does
        # not exist and refuse the command.
        tok=${1#[\"\']}
        tok=${tok%[\"\']}
        case $tok in /*) dir=$tok ;; *) dir=$dir/$tok ;; esac
        ;;
      -c|--git-dir|--work-tree|--namespace|--exec-path|--super-prefix)
        shift
        [ $# -gt 0 ] || break
        ;;
      -*) ;;
      *) break ;;
    esac
    shift
  done
  SEG_DIR=$dir
  SEG_REST=$*
  set +f
  return 0
}

# The branch a directory is on. Prints it and returns 0; returns 1 when it
# cannot tell, which every caller must treat as a block -- a guard that cannot
# see is not a guard. An empty branch on success is a detached HEAD, which
# cannot advance main.
branch_of() {
  local dir=$1
  [ -n "$dir" ] || return 1
  [ -d "$dir" ] || return 1
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  git -C "$dir" branch --show-current 2>/dev/null
  return 0
}

# Destructive, never allowed. Anchored at the subcommand, so a command that
# merely names one in an argument is not matched.
DESTRUCTIVE='^(reset +--hard|clean +-[a-zA-Z]*f|branch +-D|checkout +(-- +)?\.( |$)|restore +(-- +)?\.( |$)|push +([^ ]* )?--force|push +([^ ]* )?-f( |$))'

while IFS= read -r segment; do
  parse_git_segment "$segment" || continue
  [ -n "$SEG_REST" ] || continue

  if printf '%s' "$SEG_REST" | grep -qE "$DESTRUCTIVE"; then
    block "this is a destructive git command. Ask the user to run it themselves."
  fi

  # main only advances through a squash-merged PR. Blocking the push alone was
  # not enough: the commit still got made, then sat on the local main waiting
  # for a human to push it while PRs advanced through the other path, and local
  # main drifted from origin/main. Refusing the commit keeps that one path.
  if printf '%s' "$SEG_REST" | grep -qE '^commit( |$)'; then
    if ! branch=$(branch_of "$SEG_DIR"); then
      block "the git guard cannot tell which branch this would commit on (looked in '$SEG_DIR'). Failing closed."
    fi
    if [ "$branch" = "main" ]; then
      block "the current branch is main, and main only advances through a squash-merged PR. Create a branch first."
    fi
  fi

  # Pushing is fine, landing on main is not.
  if printf '%s' "$SEG_REST" | grep -qE '^push( |$)'; then
    if printf '%s' "$SEG_REST" | grep -qE "[ :\"']main([ \"']|\$)"; then
      block "this pushes to main. main only advances through a squash-merged PR."
    fi
    if ! branch=$(branch_of "$SEG_DIR"); then
      block "the git guard cannot tell which branch this would push (looked in '$SEG_DIR'). Failing closed."
    fi
    if [ "$branch" = "main" ]; then
      block "the current branch is main, so a bare push would land there. Work on a branch and open a PR."
    fi
  fi
done <<SEGMENTS
$(printf '%s\n' "$COMMAND" | tr ';&|()' '\n\n\n\n\n')
SEGMENTS

exit 0
