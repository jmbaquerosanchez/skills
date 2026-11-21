#!/bin/bash
# Tests of pending-review.sh, in the jmb-review-pr folder. Usage: bash tests/pending-review.sh
#
# The script answers whether a PR has a pending review ("Pending review" in
# that folder's protocol.md) with its exit code: 0 with the last review comment
# on stdout, 1 with nothing, or 2 when it could not answer. Each case checks the
# code and the exact stdout for one sequence of PR comments.
#
# The script runs with a PATH that holds only a double of gh, so it can call
# nothing else: neither jq nor python3 nor anything that writes. The double
# takes only `gh pr view <pr> --json comments --jq <expr>`, logs the PR it was
# asked for (or the whole call, if it is any other) and answers by running
# `jq -r <expr>` on the case's comments, so
# what runs is the exact expression the script ships. gh embeds gojq, which
# behaves like jq for what that expression uses. These tests need jq; the
# projects that receive the script do not.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT=$ROOT/skills/jmb-review-pr/pending-review.sh
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
unset GH_FAILS

JQ=$(command -v jq) || { echo "jq is missing, and these tests need it." >&2; exit 1; }

# The double. With GH_FAILS it fails with that code and says nothing, so that
# the message the test sees on stderr is the script's own.
mkdir "$TMP/bin"
{
  echo "#!$BASH"
  cat <<'EOF'
if [ $# -ne 7 ] || [ "$1 $2" != "pr view" ] || [ "$4 $5 $6" != "--json comments --jq" ]; then
  printf 'unexpected: gh %s\n' "$*" >>"$DOUBLE/calls"
  echo "gh double: unexpected call: gh $*" >&2
  exit 99
fi
printf '%s\n' "$3" >>"$DOUBLE/calls"
[ -z "${GH_FAILS:-}" ] || exit "$GH_FAILS"
exec "$JQ" -r "$7" "$DOUBLE/comments.json"
EOF
} >"$TMP/bin/gh"
chmod +x "$TMP/bin/gh"

# The PR's comments, oldest first, one argument per body.
comments() {
  "$JQ" -n '{comments: [$ARGS.positional[] | {author: {login: "someone"}, body: .}]}' \
    --args "$@" >"$TMP/comments.json"
}

# Runs the script with the given arguments; leaves RC, $TMP/out and $TMP/err.
run() {
  rm -f "$TMP/calls"
  env -i PATH="$TMP/bin" DOUBLE="$TMP" JQ="$JQ" ${GH_FAILS:+GH_FAILS=$GH_FAILS} \
    "$BASH" "$SCRIPT" "$@" >"$TMP/out" 2>"$TMP/err"
  RC=$?
}

CASES=0
FAILURES=0

fail() {
  FAILURES=$((FAILURES + 1))
  echo "FAIL $1"
  if [ -s "$TMP/err" ]; then sed 's/^/    /' "$TMP/err"; fi
}

# Checks the code, the exact stdout and the gh calls of the last run: $2 is
# what stdout must hold, and $3 the PRs gh was asked for, one per line.
expect() {
  local code=$1 stdout=$2 calls=$3 description=$4
  CASES=$((CASES + 1))
  if [ "$RC" != "$code" ]; then
    fail "$description: expected exit $code, got $RC"
  elif ! printf '%s' "$stdout" | cmp -s - "$TMP/out"; then
    fail "$description: unexpected stdout:"
    sed 's/^/    /' "$TMP/out"
  elif [ "$(cat "$TMP/calls" 2>/dev/null)" != "$calls" ]; then
    fail "$description: expected the gh calls '$calls', got '$(cat "$TMP/calls" 2>/dev/null)'"
  elif [ "$code" = 2 ] && [ ! -s "$TMP/err" ]; then
    fail "$description: exit 2 without a message on stderr"
  fi
}

# The answers for PR 42, with a single gh call.
pending() { run 42; expect 0 "$1"$'\n' 42 "$2"; }
none() { run 42; expect 1 "" 42 "$1"; }
# Wrong arguments: exit 2 before calling gh.
refuses() { local description=$1; shift; run "$@"; expect 2 "" "" "$description"; }

REVIEW_A='Review of `21-topic` (PR #42, ticket #21) against `origin/main`: merge-base `aaa1111`, commits `aaa1111..bbb2222` (3). Two axes with `jmb-review-pr` (sonnet), at the maintainer'"'"'s request.

## Standards

- `skills/x/SKILL.md:3`: a finding with "quotes", $HOME, a backslash \n and a %s.

## Spec

No findings.

Standards: 1 finding (minor). Spec: none.'
REVIEW_B='Review of `21-topic` (PR #42, ticket #21) against `origin/main`: merge-base `aaa1111`, commits `aaa1111..ccc3333` (5). Two axes with `jmb-review-pr` (sonnet), at the maintainer'"'"'s request.

## Standards

No findings.

## Spec

No findings.

Standards: none. Spec: none.'
FIXES='## Fixes after review

On the review of `bbb2222`: commits `bbb2222..ccc3333` (2), CI green on `ccc3333`. `origin/main` has not moved.

### Standards

- **The finding** → `ccc3333`. Fixed.'
PERSON='Thanks, I will look at it tomorrow.'
BOT='<!-- coverage-bot -->
Coverage: 100%.'

comments
none "a PR without comments"
comments "$PERSON" "$BOT"
none "comments from people and bots only"
comments "$REVIEW_A"
pending "$REVIEW_A" "a review with nothing after it, as an interrupted fixer leaves it"
comments "$PERSON" "$REVIEW_A" "$PERSON" "$BOT"
pending "$REVIEW_A" "people and bots before and after the review"
comments "$REVIEW_A" "$FIXES"
none "a review answered by its fixes"
comments "$REVIEW_A" "$PERSON" "$FIXES" "$BOT"
none "people and bots between the review and its fixes"
comments "$REVIEW_A" "$REVIEW_B"
pending "$REVIEW_B" "two reviews in a row: the last one counts"
comments "$REVIEW_A" "$FIXES" "$REVIEW_B"
pending "$REVIEW_B" "fixes before the last review do not answer it"
comments "$REVIEW_A" "$FIXES" "$REVIEW_B" "$FIXES"
none "reviews and fixes alternating, the last review answered"
comments "$REVIEW_A" "$FIXES" "$REVIEW_B" "$PERSON" "$FIXES" "$REVIEW_A" "$BOT"
pending "$REVIEW_A" "reviews and fixes alternating, the last review not answered"

# The prefixes count at the start of the body only, letter by letter.
comments "As the comment starting with Review of \`21-topic\` says, this is fine."
none "the review prefix further into a body"
comments "$REVIEW_A" "$FIXES" "> ${REVIEW_B//$'\n'/$'\n'> }

Is this still pending?"
none "a reply that quotes a review does not reopen it"
comments "review of \`21-topic\` (PR #42)"
none "the review prefix in another case"
comments "$REVIEW_A" "I will post the ## Fixes after review comment when CI is green." "> ${FIXES//$'\n'/$'\n'> }"
pending "$REVIEW_A" "the fixes prefix further into a body, or quoted"
comments "$REVIEW_A" "### Fixes after review"
pending "$REVIEW_A" "the fixes prefix with another heading level"

# It could not answer: exit 2, never 1.
comments "$REVIEW_A" "$FIXES"
refuses "no arguments"
refuses "two arguments" 42 43
refuses "an empty argument" ""
refuses "a word" abc
refuses "a number with a suffix" 42a
refuses "a number with #" "#42"
refuses "a negative number" -1
refuses "zero" 0
GH_FAILS=1
run 42
expect 2 "" 42 "gh fails with exit 1, as when the PR does not exist"
GH_FAILS=4
run 42
expect 2 "" 42 "gh fails with exit 4, as when it is not authenticated"
unset GH_FAILS

echo "$CASES cases, $FAILURES failures"
[ "$FAILURES" -eq 0 ]
