#!/usr/bin/env python3
"""Citations between the kit's files. Usage: python3 scripts/citations.py

Fails if a citation is left without a target: a renamed heading, a label that
changes, a link to a moved file. The skills cite the contract by its exact
name, and a name that changes on one side and not on the other breaks nothing
visible until a skill looks for what is no longer there.

It reads these forms, and only these; a citation written any other way is not
watched. None is read inside a code block, which is an example.

1. Relative links `[text](path)` and `[text](path#anchor)`, in all Markdown
   that git tracks: the path exists and the anchor is a heading of the target,
   with GitHub's slug. They are not read in inline code either.
2. `§ Name`, in `skills/`: Name is a `##` heading of the flow.md template. A
   § followed by a lowercase letter talks about the sign and does not cite
   ("each § is one of its headings"). Since the citation does not say where it
   ends, it is enough that it starts with the heading, and a heading shortened
   to a prefix of itself ("Test seams" to "Test") is not caught.
3. `*Name*`, in the own skills: Name is a bold label of the flow.md template or
   a fixed row of its tables, like *Shared types*. A lowercase italic is
   emphasis. Matt's copies are left out, because they use italics for emphasis.
4. `"Name" column`, in the own skills: Name is a table header of a jmb-setup
   template.
5. `"Name" table`, `"Name" section` and `see "Name"`, in the own skills: Name
   is a heading of a jmb-setup template, which is what reaches the project's
   AGENTS.md.
6. `` `name` markers ``, in the own skills: a jmb-setup template carries
   `<!-- name:start -->` and `<!-- name:end -->`. Also, in each template, each
   start marker closes with its own end marker.
7. `/name` and `Skill tool with "name"`, in `skills/`: name is a folder of
   `skills/` with its SKILL.md. A bare name between backticks is not read,
   because it cannot be told apart from other words.
8. `jmb-name`, in all Markdown that git tracks, inline code included: the
   same, for any word with the kit's prefix, which cannot be anything but a
   skill.

Forms 4 to 6 leave out Matt's copies, which quote their own headings the same
way ("Wayfinding operations" section, see "Fog of war") and cite nothing of
jmb-setup's.

Which skill is a copy of Matt's is said by its row in the table of
UPSTREAM.md, and each row has to have its folder. A citation that matches these
forms without being one goes to EXCEPTIONS, with its why; an exception that no
longer matches anything also fails, so the list does not pile up leftovers.
"""

import os
import re
import subprocess
import sys

TEMPLATES = "skills/jmb-setup/templates"
FLOW = f"{TEMPLATES}/flow.md"
UPSTREAM = "skills/UPSTREAM.md"

# (file, citation as the script reads it): why it is not a citation.
EXCEPTIONS = {
    ("skills/jmb-prototype/UI.md", "/settings"): "a route of the example application, not a skill",
    ("skills/jmb-improve-codebase-architecture/SKILL.md", "/tmp"): "the system's temporary directory, not a skill",
    ("skills/jmb-triage/AGENT-BRIEF.md", "/triage"): "the command of an example brief, not a call to the skill",
    ("user/README.md", "jmb-skills"): "the folder of the leaks list under ~/.config, not a skill",
}

errors = []
used = set()
checked = 0


def error(path, line, message):
    errors.append(f"::error file={path},line={line}::{message}")


def read(path):
    with open(path, encoding="utf-8") as file:
        return file.read().split("\n")


def without_blocks(lines):
    """The lines, with those of code blocks emptied, to keep the numbering."""
    out, fence = [], None
    for line in lines:
        m = re.match(r"\s*(```+|~~~+)", line)
        if fence is None and m:
            fence = m.group(1)[0] * 3
            out.append("")
        elif fence is not None:
            if line.strip().startswith(fence):
                fence = None
            out.append("")
        else:
            out.append(line)
    return out


def without_code(line):
    return re.sub(r"(`+).*?\1", "", line)


def headings(lines, level=None):
    pattern = r"#{%d} (.+?)\s*$" % level if level else r"#+ (.+?)\s*$"
    return [m.group(1) for line in without_blocks(lines) if (m := re.fullmatch(pattern, line))]


def slug(heading):
    """The anchor GitHub gives a heading, without the suffix of repeated ones."""
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", heading)
    text = re.sub(r"[`*]", "", text).strip().lower()
    return re.sub(r"[^\w\- ]", "", text).replace(" ", "-")


def anchors(lines):
    seen, every = {}, set()
    for heading in headings(lines):
        base = slug(heading)
        n = seen.get(base, 0)
        every.add(base if n == 0 else f"{base}-{n}")
        seen[base] = n + 1
    return every


def tables(lines):
    """Header and rows of each table, as lists of cells."""
    result, current = [], None
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")] if line.lstrip().startswith("|") else None
        if cells is None:
            current = None
        elif current is None:
            current = {"header": cells, "rows": []}
            result.append(current)
        elif not all(re.fullmatch(r":?-+:?", c) for c in cells):
            current["rows"].append(cells)
    return result


def exception(path, citation):
    if (path, citation) in EXCEPTIONS:
        used.add((path, citation))
        return True
    return False


def check(path, n, citation, valid, message):
    global checked
    checked += 1
    if not valid and not exception(path, citation):
        error(path, n, message)


def is_skill(name):
    return os.path.isfile(f"skills/{name}/SKILL.md")


root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(root)

# The targets.
templates = sorted(f"{TEMPLATES}/{f}" for f in os.listdir(TEMPLATES) if f.endswith(".md"))
flow = read(FLOW)
SECTIONS = headings(flow, 2)
LABELS = {m.group(1) for line in flow if (m := re.match(r"\s*- \*\*(.+?)\*\*", line))}
LABELS |= {row[0] for t in tables(flow) for row in t["rows"] if row[0] and "{{" not in row[0]}
COLUMNS = {c for p in templates for t in tables(read(p)) for c in t["header"]}
TITLES = {h for p in templates for h in headings(read(p))}
MARKERS = {}
for p in templates:
    open_ = []
    for n, line in enumerate(read(p), 1):
        for name, side in re.findall(r"<!--\s*([a-z0-9-]+):(start|end)\s*-->", line):
            MARKERS.setdefault(name, set()).add(side)
            if side == "start":
                open_.append(name)
            elif not open_ or open_.pop() != name:
                error(p, n, f'the end marker of "{name}" does not close any start marker of its own')
    for name in open_:
        error(p, 1, f'the start marker of "{name}" has no end marker')

COPIES = set()
for n, line in enumerate(read(UPSTREAM), 1):
    if m := re.match(r"\| `([a-z0-9-]+)` \|", line):
        COPIES.add(m.group(1))
        check(UPSTREAM, n, m.group(1), is_skill(m.group(1)),
              f'the copy "{m.group(1)}" has no folder in skills/')
if not COPIES:
    error(UPSTREAM, 1, "the table of copies is missing, with one `| `name` | …` row per copy")
OWN = {d for d in os.listdir("skills") if is_skill(d)} - COPIES

# The citations.
output = subprocess.run(["git", "ls-files", "-z", "*.md"], capture_output=True, text=True, check=True).stdout
paths = [p for p in output.split("\0") if os.path.isfile(p) and not os.path.islink(p)]
for path in paths:
    lines = read(path)
    in_skills = path.startswith("skills/")
    own = in_skills and path.split("/")[1] in OWN

    for n, line in enumerate(without_blocks(lines), 1):
        text = without_code(line)
        for m in re.finditer(r"\[[^\]]*\]\(([^)\s]+)\)", text):
            target = m.group(1)
            if re.match(r"[a-z][a-z0-9+.-]*:", target):
                continue
            route, _, anchor = target.partition("#")
            file = os.path.normpath(os.path.join(os.path.dirname(path), route)) if route else path
            exists = os.path.exists(file)
            check(path, n, target, exists, f'the link to "{route}" does not lead to any file')
            if exists and anchor and file.endswith(".md"):
                check(path, n, target, anchor in anchors(read(file)),
                      f'"#{anchor}" is not the anchor of any heading of {file}')
        if own:
            for m in re.finditer(r"(?<![*\w])\*(?![*\s])([^*]+?)(?<!\s)\*(?![*\w])", text):
                if m.group(1)[0].isupper():
                    check(path, n, f"*{m.group(1)}*", m.group(1) in LABELS,
                          f"*{m.group(1)}* is neither a label nor a fixed row of {FLOW}")
        for m in re.finditer(r"(?<![\w-])jmb-([a-z0-9]+(?:-[a-z0-9]+)*)", line):
            name = "jmb-" + m.group(1)
            check(path, n, name, is_skill(name), f'"{name}" is not a skill of skills/')

    if not in_skills:
        continue
    for n, line in enumerate(without_blocks(lines), 1):
        for m in re.finditer(r"§ (\S.*)", line):
            rest = m.group(1)
            if not rest[0].isupper():
                continue
            matches = any(rest.startswith(s) and (len(rest) == len(s) or not (rest[len(s)].isalnum() or rest[len(s)] in "-_"))
                          for s in SECTIONS)
            citation = "§ " + " ".join(rest.split()[:3])
            check(path, n, citation, matches, f'"{citation}…" does not start with any ## heading of {FLOW}')
        if own:
            for m in re.finditer(r'"([^"]+)" column\b', line):
                check(path, n, m.group(0), m.group(1) in COLUMNS,
                      f'"{m.group(1)}" is not a table header of the jmb-setup templates')
            for m in re.finditer(r'"([^"]+)" (?:table|section)\b|see "([^"]+)"', line):
                title = m.group(1) or m.group(2)
                check(path, n, m.group(0), title in TITLES,
                      f'"{title}" is not a heading of the jmb-setup templates')
            for m in re.finditer(r"`([a-z0-9-]+)` markers?", line):
                check(path, n, m.group(0), MARKERS.get(m.group(1)) == {"start", "end"},
                      f"no jmb-setup template carries the markers <!-- {m.group(1)}:start --> and <!-- {m.group(1)}:end -->")
        names = re.findall(r"(?<![\w/.~<>$&{}'\"-])/([a-z][a-z0-9-]*)(?![\w/.<>-])", line)
        names += re.findall(r'Skill tool with "([^"]+)"', line)
        for name in names:
            citation = f"/{name}" if f"/{name}" in line else name
            check(path, n, citation, is_skill(name), f'"{name}" is not a skill of skills/')

for (path, citation), why in EXCEPTIONS.items():
    if (path, citation) not in used:
        error(path, 1, f'the exception for "{citation}" ({why}) no longer matches anything; remove it from EXCEPTIONS in scripts/citations.py')

for line in errors:
    print(line)
print(f"{len(paths)} files checked, {checked} citations checked, {len(errors)} broken")
sys.exit(1 if errors else 0)
