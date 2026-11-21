# Review protocol

The two comments with which the flow skills pass the baton on a PR: `jmb-review-pr` posts the review comment, and `jmb-implement-ticket` answers with the fixes comment. `jmb-implement-ticket` reads the review comment to know what to fix, and [pending-review.sh](pending-review.sh) matches the two to tell it and `jmb-sync` whether a PR is due for fixes. That is why their form is fixed here.

**The skeleton is fixed.** In the blocks below, whatever is outside `<…>` is copied as is, in English, whatever the project's language: it is protocol syntax, like `Closes #N`. Each `<…>` is a slot: a value (`<branch>`, `<sha>`) or a text, which goes in the tracker's language per the "Languages" table of the project's AGENTS.md. A slot with `|` gives literal alternatives: pick one and copy it as is.

## Review comment

`jmb-review-pr` posts it on the PR, with the form it shows in the terminal. References to files go as `path:line` in backticks, without a link: in a PR comment, relative links do not resolve.

```
Review of `<branch>` (PR #<pr>, ticket #<n>) against `origin/main`: merge-base `<sha>`, commits `<merge-base>..<head>` (<k>). Two axes with `jmb-review-pr` (sonnet), at the maintainer's request.

## Standards

<Standards axis report>

## Spec

<Spec axis report>

<summary line: findings per axis and the worst of each axis>
```

The first line carries the reviewed head, `<head>`, which the fixes comment cites as `<reviewed head>`. Without a ticket, the parenthesis stays as `(PR #<pr>)`.

## Fixes comment

`jmb-implement-ticket` posts it on the same PR, right before returning it to ready. One entry per finding, in the review's order and under its same headings, so the two comments read side by side:

```
## Fixes after review

On the review of `<reviewed head>`: commits `<reviewed head>..<new head>` (<k>), CI green on `<new head>`. <Synced onto `<origin/main sha>` | `origin/main` has not moved.>

### Standards

- **<finding gist>** → `<sha>`. <what was done>
- **<gist>** → no change: <argument>
- **<gist>** → out of scope (<#m | maintainer>): <why>

### Spec

<one entry per Spec finding, with the same form>

### Also

- `<sha>`: <what and why>
```

## Pending review

A PR has a **pending review** when its last comment starting with "Review of \`" is not followed by any comment starting with `## Fixes after review`. It is the signal on which `jmb-implement-ticket` starts its fixes and `jmb-sync` relaunches the PR.

[pending-review.sh](pending-review.sh), next to this file, is its definition: the skills call it and do not read the comments themselves, so that two sessions cannot read the same PR two ways. It takes the PR number, runs inside a clone of the repo and answers with its exit code:

- `0`, pending review: stdout carries the full body of the last review comment.
- `1`, no pending review, with stdout empty.
- `2`, it could not answer (wrong arguments, or `gh` failed), with the reason on stderr.

It matches the two first lines at the start of the body, letter by letter: that is why they are copied as they are.

The last review comment is the one that counts because `jmb-review-pr` can be relaunched on a PR already fixed, and its new comment leaves the PR with a pending review again. And since the fixes comment is posted at the end, a fixer that is interrupted leaves the review pending, and the next one picks it up.
