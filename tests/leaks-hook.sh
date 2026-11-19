#!/bin/bash
# Tests of the repo's leaks hook, scripts/leaks.py. Usage: bash tests/leaks-hook.sh
#
# Like tests/kit-hook.sh, they launch the hook the way Claude Code launches it:
# the command comes from .claude/settings.json and runs from the root with
# CLAUDE_PROJECT_DIR. Each case gets on stdin the JSON of a Bash call, and only
# the exit code is checked: 2 blocks and 0 lets through. The list is a file of
# made-up entries, never the real one, and every case also checks that the
# hook's output does not carry any of them: it says where, never what.
#
# At the end, the `commits` mode that CI runs, by its exit codes: 1 on a leak,
# 2 when it cannot check.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SH=$(command -v sh)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for b in python3 git; do
  command -v "$b" >/dev/null || { echo "$b is missing, and these tests need it." >&2; exit 1; }
done

# The made-up list. A blank line is skipped, and entries count by their line.
LIST=$TMP/list.txt
printf '%s\n' 'acme' '' 'Widget Tron' 'leaky@example.com' >"$LIST"
ENTRIES=('acme' 'Widget Tron' 'leaky@example.com')
EMPTY_LIST=$TMP/empty.txt
printf '\n  \n' >"$EMPTY_LIST"

# The commands with which .claude/settings.json hooks the leaks hook:
# command-type handlers in PreToolUse, under a matcher that reaches Bash.
mapfile -t COMMANDS < <(python3 - "$ROOT/.claude/settings.json" <<'PY'
import json, re, sys
settings = json.load(open(sys.argv[1], encoding="utf-8"))
for entry in settings.get("hooks", {}).get("PreToolUse", []):
    matcher = entry.get("matcher", "")
    if matcher not in ("", "*") and not re.fullmatch(matcher, "Bash"):
        continue
    for handler in entry.get("hooks", []):
        command = handler.get("command", "")
        if handler.get("type") == "command" and "scripts/leaks.py" in command:
            print(command)
PY
)

# Test repos, each on branch topic, with a remote of its own to which topic is
# pushed. The hook judges the command without running it, so it is enough for
# each one to be in the state that applies.
new_repo() {
  git init -q --bare "$1.git"
  git init -q -b topic "$1"
  git -C "$1" config user.name test
  git -C "$1" config user.email test@example.invalid
  git -C "$1" config commit.gpgsign false
  git -C "$1" remote add origin "$1.git"
  commit_file "$1" notes.md hello "first commit"
  git -C "$1" push -q -u origin topic
}
commit_file() {
  printf '%s\n' "$3" >"$1/$2"
  git -C "$1" add "$2"
  git -C "$1" commit -q -m "$4"
}

CLEAN=$TMP/clean
new_repo "$CLEAN"
commit_file "$CLEAN" notes.md "hello again" "second commit, not pushed"
STAGED=$TMP/staged
new_repo "$STAGED"
printf 'built for acme\n' >"$STAGED/notes.md"
git -C "$STAGED" add notes.md
STAGED_PATH=$TMP/staged-path
new_repo "$STAGED_PATH"
printf 'hello\n' >"$STAGED_PATH/acme_notes.md"
git -C "$STAGED_PATH" add acme_notes.md
UNSTAGED=$TMP/unstaged
new_repo "$UNSTAGED"
printf 'built for ACME\n' >"$UNSTAGED/notes.md"
UNTRACKED=$TMP/untracked
new_repo "$UNTRACKED"
printf 'built for acme\n' >"$UNTRACKED/draft.md"
IDENTITY=$TMP/identity
new_repo "$IDENTITY"
git -C "$IDENTITY" config user.email leaky@example.com
CONTENT=$TMP/content
new_repo "$CONTENT"
commit_file "$CONTENT" notes.md "see widget tron" "notes"
commit_file "$CONTENT" notes.md "see the docs" "notes, reworded"
MESSAGE=$TMP/message
new_repo "$MESSAGE"
commit_file "$MESSAGE" notes.md "hello again" "port the acme fix"
AUTHOR=$TMP/author
new_repo "$AUTHOR"
printf 'hello again\n' >"$AUTHOR/notes.md"
git -C "$AUTHOR" commit -q -a -m "notes" --author "Someone <leaky@example.com>"
PUSHED=$TMP/pushed
new_repo "$PUSHED"
commit_file "$PUSHED" notes.md "built for acme" "notes"
git -C "$PUSHED" push -q
commit_file "$PUSHED" notes.md "built for a client" "notes, without the name"
BRANCH_NAME=$TMP/branch-name
new_repo "$BRANCH_NAME"
git -C "$BRANCH_NAME" switch -q -c fix-acme
OTHER_REF=$TMP/other-ref
new_repo "$OTHER_REF"
git -C "$OTHER_REF" switch -q -c other
commit_file "$OTHER_REF" notes.md "built for acme" "notes"
git -C "$OTHER_REF" switch -q topic
OUTSIDE=$TMP/outside
mkdir "$OUTSIDE"
if git -C "$OUTSIDE" rev-parse --git-dir >/dev/null 2>&1; then
  echo "$TMP falls inside a git repo, and the cases outside a repo would not hold." >&2
  exit 1
fi

printf 'Fix the parser\n\nFor acme.\n' >"$TMP/message-leaky.txt"
printf 'Fix the parser\n' >"$TMP/message-clean.txt"
printf 'Seen at Leaky@Example.com\n' >"$TMP/body-leaky.md"
printf 'All good.\n' >"$TMP/body-clean.md"
EMPTY_PATH=$TMP/bin-empty
mkdir "$EMPTY_PATH"

CASES=0
FAILURES=0

fail() {
  FAILURES=$((FAILURES + 1))
  echo "FAIL $1"
  sed 's/^/    /' "$TMP/output"
}

# Passes the payload $2 to the hook and checks that it exits with $1. Reads
# COMMAND, LIST_FILE and RUN_PATH.
check() {
  local expected=$1 payload=$2 description=$3 rc entry
  CASES=$((CASES + 1))
  printf '%s' "$payload" |
    (cd "$ROOT" && env PATH="$RUN_PATH" CLAUDE_PROJECT_DIR="$ROOT" JMB_LEAKS_FILE="$LIST_FILE" \
      "$SH" -c "$COMMAND") >"$TMP/output" 2>&1
  rc=$?
  [ "$rc" = "$expected" ] || fail "$description: expected $expected, got $rc"
  for entry in "${ENTRIES[@]}"; do
    if grep -qiF -- "$entry" "$TMP/output"; then
      fail "$description: the output carries an entry of the list"
      break
    fi
  done
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
  LIST_FILE=$LIST

  # git commit: the message, as a whole word, ignoring case, with _ and - as
  # separators.
  case_ 0 "$CLEAN" 'git commit -m "Fix the parser"'
  case_ 2 "$CLEAN" 'git commit -m "Fix the parser for acme"'
  case_ 2 "$CLEAN" 'git commit -m "Fix the parser for ACME_3"'
  case_ 2 "$CLEAN" 'git commit -m "Fix the acme-x parser"'
  case_ 2 "$CLEAN" 'git commit -m "Fix widget tron"'
  case_ 0 "$CLEAN" 'git commit -m "Fix the acmes and nacme"'
  case_ 2 "$CLEAN" $'git commit -F - <<\'EOF\'\nFix the parser\n\nFor acme.\nEOF'
  case_ 2 "$CLEAN" "git commit -F $TMP/message-leaky.txt"
  case_ 2 "$CLEAN" "git commit --file=$TMP/message-leaky.txt"
  case_ 0 "$CLEAN" "git commit -F $TMP/message-clean.txt"
  case_ 0 "$CLEAN" "git commit -F $TMP/does-not-exist.txt"

  # git commit: the tracked files, staged and in the working tree, their paths
  # and the identity it would sign with. An untracked file is left to the push.
  case_ 2 "$STAGED" 'git commit -m "Fix the parser"'
  case_ 2 "$STAGED_PATH" 'git commit -m "Fix the parser"'
  case_ 2 "$UNSTAGED" 'git commit -a -m "Fix the parser"'
  case_ 0 "$UNTRACKED" 'git commit -m "Fix the parser"'
  case_ 2 "$IDENTITY" 'git commit -m "Fix the parser"'
  case_ 2 "$CLEAN" 'git -c user.email=leaky@example.com commit -m "Fix the parser"'
  case_ 2 "$CLEAN" "git -C $STAGED commit -m x"
  case_ 2 "$CLEAN" "git status && git -C \"$IDENTITY\" commit -m x"

  # git push: each commit not on a remote-tracking branch, from HEAD and from
  # the refs it names, and the current branch's name.
  case_ 0 "$CLEAN" 'git push'
  case_ 0 "$CLEAN" 'git push -u origin topic'
  case_ 2 "$CONTENT" 'git push'
  case_ 2 "$MESSAGE" 'git push'
  case_ 2 "$AUTHOR" 'git push'
  case_ 0 "$PUSHED" 'git push'
  case_ 2 "$BRANCH_NAME" 'git push -u origin fix-acme'
  case_ 2 "$BRANCH_NAME" 'git push'
  case_ 0 "$OTHER_REF" 'git push'
  case_ 2 "$OTHER_REF" 'git push origin other'
  case_ 2 "$OTHER_REF" 'git push origin other:topic'
  case_ 2 "$OTHER_REF" 'git push --all'
  case_ 2 "$CLEAN" "git -C $CONTENT push"

  # gh: what it writes to GitHub, in the command and in the files it reads.
  case_ 0 "$CLEAN" 'gh issue create --title "Parser" --body "It breaks."'
  case_ 2 "$CLEAN" 'gh issue create --title "Parser" --body "It breaks for acme."'
  case_ 2 "$CLEAN" "gh pr comment 3 --body-file $TMP/body-leaky.md"
  case_ 2 "$CLEAN" "gh pr comment 3 --body-file=$TMP/body-leaky.md"
  case_ 0 "$CLEAN" "gh pr create --title x -F $TMP/body-clean.md"
  case_ 2 "$CLEAN" "gh pr create --title x -F $TMP/body-leaky.md"
  case_ 2 "$CLEAN" $'gh pr create --title x --body "$(cat <<\'EOF\'\nIt breaks\nfor acme.\nEOF\n)"'
  case_ 2 "$CLEAN" "gh release create v1 --notes-file $TMP/body-leaky.md"
  case_ 2 "$CLEAN" 'gh label create acme'
  case_ 2 "$CLEAN" 'gh api repos/o/r/issues -f title=x -f body=acme'
  case_ 2 "$CLEAN" "gh api repos/o/r/issues/1/comments -F body=@$TMP/body-leaky.md"
  case_ 2 "$CLEAN" "gh api -X PATCH repos/o/r/issues/1 --input $TMP/body-leaky.md"

  # Lets through what only reads, or does not publish, even naming an entry.
  case_ 0 "$CLEAN" 'gh pr view 3 -R someone/acme'
  case_ 0 "$CLEAN" 'gh issue -R someone/acme view 1'
  case_ 0 "$CLEAN" 'gh issue list --search acme'
  case_ 0 "$CLEAN" 'gh api repos/someone/acme'
  case_ 0 "$CLEAN" "gh secret set LEAKS_LIST < $LIST"
  case_ 0 "$CLEAN" 'grep -ri acme .'
  case_ 0 "$CLEAN" 'git log --grep acme'
  case_ 0 "$CLEAN" 'echo "git commit -m acme"'
  case_ 0 "$OTHER_REF" 'git commit -m "then git push origin other"'
  case_ 0 "$CLEAN" ''

  # Fails closed when it cannot check: without a list, with an empty one,
  # without a repo, or with an input that is not JSON. Only for the commands it
  # watches.
  check 2 'not json' 'an input that is not JSON'
  case_ 2 "$OUTSIDE" 'git commit -m x'
  case_ 2 "" 'git commit -m x'
  LIST_FILE=$TMP/does-not-exist.txt
  case_ 2 "$CLEAN" 'git commit -m x'
  case_ 2 "$CLEAN" 'git push'
  case_ 2 "$CLEAN" 'gh issue create --title x --body y'
  case_ 0 "$CLEAN" 'git status'
  LIST_FILE=$EMPTY_LIST
  case_ 2 "$CLEAN" 'git commit -m x'
}

if [ ${#COMMANDS[@]} -eq 0 ]; then
  FAILURES=$((FAILURES + 1))
  echo "FAIL .claude/settings.json does not hook scripts/leaks.py in PreToolUse for Bash"
fi
for COMMAND in "${COMMANDS[@]}"; do
  RUN_PATH=$PATH
  battery
  # Without python3, the `|| exit 2` blocks every call.
  RUN_PATH=$EMPTY_PATH
  LIST_FILE=$LIST
  case_ 2 "$CLEAN" 'git status'
done

# The commits mode, as CI runs it.
commits() {
  local expected=$1 list=$2 repo=$3 rc entry
  shift 3
  CASES=$((CASES + 1))
  (cd "$repo" && JMB_LEAKS_FILE=$list python3 "$ROOT/scripts/leaks.py" commits "$@") >"$TMP/output" 2>&1
  rc=$?
  [ "$rc" = "$expected" ] || fail "commits $* in ${repo#"$TMP"/}: expected $expected, got $rc"
  for entry in "${ENTRIES[@]}"; do
    if grep -qiF -- "$entry" "$TMP/output"; then
      fail "commits $* in ${repo#"$TMP"/}: the output carries an entry of the list"
      break
    fi
  done
}
commits 0 "$LIST" "$CLEAN" HEAD
commits 1 "$LIST" "$CONTENT" HEAD --not --remotes
commits 1 "$LIST" "$AUTHOR" origin/topic..HEAD
commits 0 "$LIST" "$PUSHED" origin/topic..HEAD
commits 1 "$LIST" "$PUSHED" HEAD
commits 2 "$TMP/does-not-exist.txt" "$CLEAN" HEAD
commits 2 "$EMPTY_LIST" "$CLEAN" HEAD
commits 2 "$LIST" "$CLEAN"

echo "$CASES cases, $FAILURES failures"
[ "$FAILURES" -eq 0 ]
