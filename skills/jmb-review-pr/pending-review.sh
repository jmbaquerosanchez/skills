#!/bin/bash
# Whether a PR has a pending review. Usage: bash pending-review.sh <pr>
#
# It is the definition of the signal that the "Pending review" section of
# protocol.md, next to this script, describes: jmb-implement-ticket and jmb-sync
# call it instead of reading the PR's comments themselves. Run it inside a clone
# of the repo, where gh infers which one. It answers with its exit code:
#
#   0  pending review: stdout carries the full body of the last review comment,
#      the one with the findings and the reviewed head on its first line.
#   1  no pending review: the PR has no review comment, or its last one is
#      followed by a fixes comment. Stdout is empty.
#   2  it could not answer: wrong arguments, or gh failed. The reason goes to
#      stderr. A failure is never 1, which would read as nothing pending.
#
# The whole rule is the jq expression of a single gh call, and gh carries its
# own jq, so a project needs neither jq nor python3. It writes nothing: the
# kit's hook judges the line of the Bash call, not what a script runs inside.

set -u

usage() {
  echo "Usage: bash pending-review.sh <pr>, with the PR number: $1." >&2
  exit 2
}
[ $# -eq 1 ] || usage "it takes one argument, and got $#"
[[ $1 =~ ^[1-9][0-9]*$ ]] || usage "'$1' is not a PR number"

# The comments, oldest first: a review comment becomes the pending one, a fixes
# comment answers it, and any other comment changes nothing. Both prefixes go
# at the start of the body, letter by letter, as protocol.md writes them.
RULE='reduce .comments[].body as $body (null;
    if $body | startswith("Review of `") then $body
    elif $body | startswith("## Fixes after review") then null
    else . end)
  | select(. != null)'

if ! review=$(gh pr view "$1" --json comments --jq "$RULE"); then
  echo "pending-review.sh: gh failed, so whether PR #$1 has a pending review is unknown." >&2
  exit 2
fi
[ -n "$review" ] || exit 1
printf '%s\n' "$review"
