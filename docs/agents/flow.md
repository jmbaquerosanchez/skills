# Flow

Translates into this project the roles the flow skills speak in: `jmb-implement-ticket`, `jmb-review-pr`, `jmb-sync` and `jmb-implement-frontier`. They cite each section by its heading and each field by its bold label.

Whatever goes between `<…>` in a command is replaced by the skill when it runs it: `<n>` is the ticket number, and the others are defined by their field. Each command runs at the root of the checkout where the work happens, the main checkout or the ticket's worktree, unless its field says otherwise.

## Tickets

Which tickets the flow carries: the open ones with the label.

- **Label**: `ready-for-agent`

## Spec

The tickets cite its sections in their `Spec:` line. It does not exist yet: `/jmb-to-spec` creates it with the first feature that gets a spec, and until then a ticket is its own spec.

- **Path**: `docs/spec.md`
- **Analogies**: § Analogies

## Verification

What runs at each moment, with its why when it is not obvious. The three are the same list, what CI runs, because all of it takes seconds. `frontmatter.py` needs PyYAML. The leaks check goes last: it reads the branch's commits and needs the machine's list, which `user/README.md` sets up; without it, it fails instead of letting through.

- **Quick**: `python3 scripts/frontmatter.py && python3 scripts/citations.py && python3 scripts/licenses.py && bash tests/kit-hook.sh && bash tests/leaks-hook.sh && python3 scripts/leaks.py commits origin/main..HEAD`
- **Full**: the same as *Quick*.
- **Before pushing**: the same as *Quick*.

## Test seams

The project's agreed seams. `/jmb-tdd` only writes tests at agreed seams, and an agent working with no human present cannot agree on them on the spot: it takes them from here.

| Seam | What is tested there | Where its tests and doubles live | Command for one file |
|---|---|---|---|
| The hooks | What each hook, the kit's and the leaks one, blocks and lets through: the JSON of a Bash call on stdin, launched the way `.claude/settings.json` hooks it, and only the exit code checked; also the exit codes of `leaks.py commits`. A hook that fails lets a commit reach `main` unseen. | `tests/`, one file per hook; the leaks one with a made-up list, never the real one | `bash <file>` |

## Worktree

Optional. With this section the flow has parallel mode: each ticket of a batch in its worktree, launched by `jmb-implement-frontier` and brought up to date by `jmb-sync`. Without it, those two skills do not start and the flow is sequential only, in the main checkout. It brings § Batch table axes along with it.

- **Isolated resources**: none. The checks and the tests write only to temporary directories of their own, and the leaks list, outside the checkout, is only read.
- **Prepare**: `true`, at the root of the worktree. A fresh worktree passes § Verification as it is: nothing is installed in the checkout.
- **Teardown**: `true`, from any checkout.

## Batch table axes

Comes with § Worktree. The axes along which two tickets running at the same time can collide: `jmb-implement-frontier` notes each frontier ticket on them to pick the batch, and passes each subagent what its neighbors touch.

| Axis | What is noted for each ticket |
|---|---|
| Shared types | The names that skills cite from another file and that it renames or reshapes: the headings, bold labels and table headers of the `flow.md` template, the headings of the AGENTS.md block and of the cross-cutting criteria, and the `jmb-setup` markers. `scripts/citations.py` lists the forms. |
| Skill folder | The folders of `skills/` it touches. |
