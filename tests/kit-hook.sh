#!/bin/bash
# Tests of the kit's hook, block-dangerous-git.sh. Usage: bash tests/kit-hook.sh
#
# They launch the hook the way Claude Code launches it: the command comes from
# the settings.json files that hook it, this repo's and the template that
# jmb-setup writes in a project, and it runs from the root with
# CLAUDE_PROJECT_DIR. That way they also break on whatever unhooks the hook
# without touching its code, like a rename or a broken symlink. Each case gets
# on stdin the JSON of a Bash call, and only the exit code is checked: 2 blocks
# and 0 lets through. Claude Code takes any other code as an error that does
# not block and lets the call through, so here it counts as neither.
#
# Each case goes through the two branches with which the hook reads its input:
# python3's and node's, which is forced with a PATH without python3.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SETTINGS=(.claude/settings.json skills/jmb-setup/templates/settings.json)
SH=$(command -v sh)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for b in python3 node git; do
  command -v "$b" >/dev/null || { echo "$b is missing, and these tests need it." >&2; exit 1; }
done

# The commands with which a settings.json hooks the kit's hook: command-type
# handlers in PreToolUse, under a matcher that reaches Bash.
hook_commands() {
  python3 - "$1" <<'PY'
import json, re, sys
settings = json.load(open(sys.argv[1], encoding="utf-8"))
for entry in settings.get("hooks", {}).get("PreToolUse", []):
    matcher = entry.get("matcher", "")
    if matcher not in ("", "*") and not re.fullmatch(matcher, "Bash"):
        continue
    for handler in entry.get("hooks", []):
        command = handler.get("command", "")
        if handler.get("type") == "command" and "block-dangerous-git.sh" in command:
            print(command)
PY
}

# Test repos. The hook judges the command without running it, so it is enough
# for each one to be on the branch that applies. Their first commit goes on a
# branch of its own, so that this script never makes a commit on a main branch.
new_repo() {
  git init -q -b initial "$1"
  git -C "$1" -c user.name=test -c user.email=test@example.invalid -c commit.gpgsign=false \
    commit -q --allow-empty -m initial
}
MAIN=$TMP/on-main
new_repo "$MAIN"
git -C "$MAIN" switch -q -c main
BRANCH=$TMP/on-branch
new_repo "$BRANCH"
git -C "$BRANCH" switch -q -c topic
DETACHED=$TMP/detached
new_repo "$DETACHED"
git -C "$DETACHED" switch -q --detach
WORKTREE=$TMP/worktree
git -C "$MAIN" worktree add -q -b wt "$WORKTREE"
OUTSIDE=$TMP/outside
mkdir "$OUTSIDE"
if git -C "$OUTSIDE" rev-parse --git-dir >/dev/null 2>&1; then
  echo "$TMP falls inside a git repo, and the cases outside a repo would not hold." >&2
  exit 1
fi

# A directory for the PATH with what the hook calls, without python3, plus the
# binaries given after its name.
bin_without_python() {
  local dir=$TMP/$1 b
  shift
  mkdir "$dir"
  for b in bash cat head tail grep tr git "$@"; do
    ln -s "$(command -v "$b")" "$dir/$b"
  done
  echo "$dir"
}
PATH_NODE=$(bin_without_python bin-node node)
PATH_NEITHER=$(bin_without_python bin-neither)

CASES=0
FAILURES=0

# Passes the payload $2 to the hook and checks that it exits with $1. Reads
# COMMAND, RUN_PATH and VARIANT, which the loop at the end sets.
check() {
  local expected=$1 payload=$2 description=$3 rc
  CASES=$((CASES + 1))
  printf '%s' "$payload" |
    (cd "$ROOT" && env PATH="$RUN_PATH" CLAUDE_PROJECT_DIR="$ROOT" "$SH" -c "$COMMAND") >/dev/null 2>"$TMP/stderr"
  rc=$?
  if [ "$rc" != "$expected" ]; then
    FAILURES=$((FAILURES + 1))
    echo "FAIL [$VARIANT] $description: expected $expected, got $rc"
    sed 's/^/    /' "$TMP/stderr"
  fi
}

# One case: the expected code, the call's directory and the Bash command.
case_() {
  local payload where=${2#"$TMP"/} command="'$3'"
  payload=$(python3 -c 'import json, sys
print(json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Bash",
                  "tool_input": {"command": sys.argv[1]}, "cwd": sys.argv[2]}))' "$3" "$2")
  [[ $3 == *$'\n'* ]] && command=$(printf '%q' "$3")
  check "$1" "$payload" "$command in ${where:-an empty cwd}"
}

battery() {
  # Blocks what is destructive, on any branch.
  case_ 2 "$BRANCH" 'git reset --hard'
  case_ 2 "$BRANCH" 'git reset --hard HEAD~1'
  case_ 2 "$BRANCH" 'git clean -fd'
  case_ 2 "$BRANCH" 'git clean -xdf'
  case_ 2 "$BRANCH" 'git branch -D other'
  case_ 2 "$BRANCH" 'git checkout .'
  case_ 2 "$BRANCH" 'git checkout -- .'
  case_ 2 "$BRANCH" 'git restore .'
  case_ 2 "$BRANCH" 'git push --force'
  case_ 2 "$BRANCH" 'git push -f origin topic'
  case_ 2 "$BRANCH" 'git push origin --force-with-lease'

  # Blocks what lands on main.
  case_ 2 "$MAIN" 'git commit -m x'
  case_ 2 "$MAIN" 'git commit'
  case_ 2 "$MAIN" 'git push'
  case_ 2 "$BRANCH" 'git push origin main'
  case_ 2 "$BRANCH" 'git push origin topic:main'

  # Judges each command of the line separately, with its own options
  # (change 5 of the hook's header).
  case_ 2 "$BRANCH" 'git status && git reset --hard'
  case_ 2 "$BRANCH" 'git status; git reset --hard'
  case_ 2 "$BRANCH" 'true || git branch -D other'
  case_ 2 "$BRANCH" '(git reset --hard)'
  case_ 2 "$BRANCH" 'sudo git reset --hard'
  case_ 2 "$BRANCH" 'git --no-pager reset --hard'
  case_ 2 "$BRANCH" 'git -c core.pager=cat reset --hard'
  case_ 2 "$BRANCH" "git -C $MAIN commit -m x"
  case_ 2 "$BRANCH" "git -C \"$MAIN\" commit -m x"
  case_ 2 "$TMP" 'git -C on-main commit -m x'
  case_ 2 "$MAIN" "git -C $BRANCH log && git commit -m x"
  case_ 0 "$MAIN" "git -C $BRANCH commit -m x"
  case_ 0 "$TMP" 'git -C on-branch commit -m x'

  # Fails closed if it cannot read its input or cannot tell which branch it is on.
  check 2 'not json' 'an input that is not JSON'
  case_ 2 "$OUTSIDE" 'git commit -m x'
  case_ 2 "$OUTSIDE" 'git push'
  case_ 2 "" 'git commit -m x'
  case_ 2 "$TMP/does-not-exist" 'git commit -m x'

  # Lets the rest through.
  case_ 0 "$MAIN" 'git status'
  case_ 0 "$MAIN" 'git log --oneline -5'
  case_ 0 "$MAIN" 'git pull'
  case_ 0 "$MAIN" 'ls -la'
  case_ 0 "$MAIN" ''
  case_ 0 "$OUTSIDE" 'git status'
  case_ 0 "$BRANCH" 'git commit -m x'
  case_ 0 "$BRANCH" 'git push'
  case_ 0 "$BRANCH" 'git push -u origin topic'
  case_ 0 "$BRANCH" 'git push origin topic-main'
  case_ 0 "$BRANCH" 'git push origin mainline'
  case_ 0 "$BRANCH" 'git branch -d old'
  case_ 0 "$BRANCH" 'git reset --soft HEAD~1'
  case_ 0 "$BRANCH" 'git checkout main'
  case_ 0 "$BRANCH" 'git checkout ./file'
  case_ 0 "$BRANCH" 'git restore file'
  case_ 0 "$DETACHED" 'git commit -m x'
  # A worktree on its branch, even though the main checkout is on main (change 4).
  case_ 0 "$WORKTREE" 'git commit -m x'

  # Lets through what only names a blocked command: a message in quotes or the
  # body of a heredoc are data (change 3).
  case_ 0 "$BRANCH" 'git commit -m "never git push origin main"'
  case_ 0 "$BRANCH" 'git commit -m "a; git reset --hard"'
  case_ 0 "$BRANCH" 'echo "git reset --hard"'
  case_ 0 "$MAIN" 'grep -r "git commit" .'
  case_ 0 "$BRANCH" $'git commit -F - <<\'EOF\'\ngit reset --hard\ngit push origin main\nEOF'
}

# Each distinct command runs the battery once, with the files that hook it.
declare -A HOOKED_BY
for settings in "${SETTINGS[@]}"; do
  mapfile -t commands < <(hook_commands "$ROOT/$settings")
  if [ ${#commands[@]} -eq 0 ]; then
    FAILURES=$((FAILURES + 1))
    echo "FAIL $settings does not hook block-dangerous-git.sh in PreToolUse for Bash"
  fi
  for command in "${commands[@]}"; do
    HOOKED_BY[$command]+="$settings, "
  done
done

for COMMAND in "${!HOOKED_BY[@]}"; do
  VARIANT="${HOOKED_BY[$COMMAND]}python3"
  RUN_PATH=$PATH
  battery
  VARIANT="${HOOKED_BY[$COMMAND]}node"
  RUN_PATH=$PATH_NODE
  battery
  VARIANT="${HOOKED_BY[$COMMAND]}without python3 or node"
  RUN_PATH=$PATH_NEITHER
  case_ 2 "$BRANCH" 'git status'
done

echo "$CASES cases, $FAILURES failures"
[ "$FAILURES" -eq 0 ]
