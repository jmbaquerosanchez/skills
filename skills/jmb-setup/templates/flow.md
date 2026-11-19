<!--
Template for `docs/agents/flow.md`. `jmb-setup` fills it in with what it finds in the project and what it asks; the flow skills read the result.

- The `##` headings, the bold labels, the table headers and the *Shared types* row do not change, not even their language: the skills cite them by name.
- `{{…}}` is a slot: the project's value goes there.
- Comments like this one are for whoever fills the template in, and are deleted when filling it in.
- An optional section that does not apply is deleted whole, heading included: the skills check whether it is there. § Batch table axes comes and goes with § Worktree.
- Write what an agent does not find by looking at the repo. The scripts are already in the project; what goes here is which one applies at each moment and the why that no file tells.
-->

# Flow

Translates into this project the roles the flow skills speak in: `jmb-implement-ticket`, `jmb-review-pr`, `jmb-sync` and `jmb-implement-frontier`. They cite each section by its heading and each field by its bold label.

Whatever goes between `<…>` in a command is replaced by the skill when it runs it: `<n>` is the ticket number, and the others are defined by their field. Each command runs at the root of the checkout where the work happens, the main checkout or the ticket's worktree, unless its field says otherwise.

## Tickets

Which tickets the flow carries: the open ones with the label.

<!--
Label: the one that marks a ticket as ready for an agent to implement with no human present. It is usually the string that `docs/agents/triage-labels.md` gives to the `ready-for-agent` role, the one that `/jmb-to-tickets` and `/jmb-triage` apply.
-->

- **Label**: `{{label}}`

## Spec

The tickets cite its sections in their `Spec:` line.

<!--
Path: a file of the repo. The flow corrects the spec in the same PR as the code that departs from it for a reason, and `jmb-review-pr` reads it in the branch's version: both things ask for it to travel with the code.
Analogies: the section where what a branch resolves by analogy with something already decided goes, for the maintainer to review it. It has to exist: without it, those decisions scatter across AGENTS.md and the commit messages.
-->

- **Path**: `{{document path}}`
- **Analogies**: {{§ and title of the section}}

## Verification

What runs at each moment, with its why when it is not obvious.

<!--
Quick: what runs often while implementing, in seconds; for example, the type checker and the test being touched, with the command of its row in § Test seams.
Full: all the tests, when implementation is done.
Before pushing: what CI runs on a PR, cheapest first. The whole list goes here, *Check* of § Schema included if there is one: the skill runs it as is after implementing and after every sync, so that what can be seen locally does not cost a CI round.
-->

- **Quick**: {{commands}}
- **Full**: {{commands}}
- **Before pushing**: {{commands}}

## Test seams

The project's agreed seams. `/jmb-tdd` only writes tests at agreed seams, and an agent working with no human present cannot agree on them on the spot: it takes them from here.

<!--
One row per seam, from cheapest to most expensive.
"What is tested there" decides which seam each acceptance criterion goes to: also say what does not go there, for example that the most expensive seam only tests what the others cannot observe.
"Where its tests and doubles live": the tests' folder and, if there are any, the doubles that stand in for the real dependencies.
"Command for one file": with `<file>` where the test's path goes.
-->

| Seam | What is tested there | Where its tests and doubles live | Command for one file |
|---|---|---|---|
| {{seam}} | {{behavior}} | {{paths}} | `{{command}}` |

## Worktree

Optional. With this section the flow has parallel mode: each ticket of a batch in its worktree, launched by `jmb-implement-frontier` and brought up to date by `jmb-sync`. Without it, those two skills do not start and the flow is sequential only, in the main checkout. It brings § Batch table axes along with it.

<!--
Isolated resources: what the tests write to or listen on that two worktrees cannot share without stepping on each other (a database the tests empty, a port where the application is served, a directory of files), with its value in the main checkout and in the worktree, and one line of why: what would break if it were shared. If the main checkout's environment carries real credentials, the worktree's comes from an example one, because a subagent would act with them on real services.
Prepare: leaves a freshly created worktree, with its branch, ready to pass the whole of § Verification: creates its isolated resources, writes its environment and installs its dependencies, including what the git hooks need in a fresh copy. After Teardown, it creates the resources again.
Teardown: undoes the isolated resources of ticket `<n>`; the skill removes the worktree with `git worktree remove`. It has to work from any checkout and even if the worktree no longer exists, because `jmb-sync` runs it after removing it.
-->

- **Isolated resources**:

  | Resource | Main checkout | Worktree for ticket `<n>` | Why isolated |
  |---|---|---|---|
  | {{resource}} | {{value}} | {{value as a function of `<n>`}} | {{what would break if it were shared}} |

- **Prepare**: `{{command}}`, at the root of the worktree.
- **Teardown**: `{{command}}`, from any checkout.

## Batch table axes

Comes with § Worktree. The axes along which two tickets running at the same time can collide: `jmb-implement-frontier` notes each frontier ticket on them to pick the batch, and passes each subagent what its neighbors touch.

<!--
One row per axis, read from the ticket's body (`Spec:` line and acceptance criteria), because the code does not exist yet. Generic examples: the schema tables it touches, the endpoints it adds, the events it emits.
The *Shared types* row is fixed and goes first, because it is the expensive collision: two tickets each adding their own part at the end of a shared file is resolved in minutes; one reshaping a type that the other uses forces redoing those uses on sync. In its second column, how they are recognized in this project: better a rule (the types of a folder, the domain ports) than a list of names that ages.
-->

| Axis | What is noted for each ticket |
|---|---|
| Shared types | {{those it reshapes; how they are recognized in this project}} |
| {{axis}} | {{what is noted}} |

## Schema

Optional: for a project whose database migrations are generated from a schema. Each branch that touches the schema carries a single migration of its own, and the one that reaches `main` second regenerates it on sync.

<!--
Source: the schema file or files. Touching them is what triggers this recipe.
Migrations: the folder where they are generated. At the end, the branch has a single migration of its own in it.
Generate: derives the branch's migration from the source. If it takes a name, write it as `<name>`: the skill puts in what changes.
Check: verifies that the chain of migrations is consistent. It also runs in CI and goes in *Before pushing* of § Verification: it is the net that catches a branch that synced without regenerating.
Conflict: what the branch does when, on merging `origin/main`, it collides in the migrations folder. With a tool that generates them, the usual move is to take the folder as it is in `origin/main` and Generate again, which produces the next migration with only the branch's changes. Add the why of whatever is specific to the tool.
Reset the database: how the agent leaves its database as if it had never applied the migration it is going to regenerate, in both places: in a worktree (Teardown and Prepare of § Worktree, if that is enough) and in the main checkout.
-->

- **Source**: `{{path}}`
- **Migrations**: `{{folder}}`
- **Generate**: `{{command}}`
- **Check**: `{{command}}`
- **Conflict**: {{recipe}}
- **Reset the database**: {{recipe in a worktree and in the main checkout}}
