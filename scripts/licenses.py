#!/usr/bin/env python3
"""The LICENSE of each skill. Usage: python3 scripts/licenses.py

A project receives only the folder of each skill: `npx skills` copies nothing
else, and drops a symlink that leads out of the folder. A project with its flow
committed redistributes those folders, so each skills/<name>/ carries its own
LICENSE, a regular file with the notice of whoever holds it. Which notice is
said by skills/UPSTREAM.md:

- a copy, with a row in its table: Matt's MIT notice, which his license asks to
  go with every copy. All the copies carry the same file.
- an own skill: the root LICENSE, the MIT of the kit.
- an own skill with a row in its "Derived files" section: the root LICENSE, a
  blank line and Matt's notice, since some of its files are adapted from his.

The repeated files are on purpose, and this check is what keeps them true: it
catches a new skill without its LICENSE and a copy that loses Matt's notice.
"""

import os
import re
import sys
from collections import Counter

UPSTREAM = "skills/UPSTREAM.md"
MATT = re.compile(r"^Copyright \(c\) .*Matt Pocock$", re.M)
errors = []


def error(path, message):
    errors.append(f"::error file={path}::{message}")


def read(path):
    with open(path, encoding="utf-8") as file:
        return file.read()


os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

upstream = read(UPSTREAM)
copies = set(re.findall(r"^\| `([a-z0-9-]+)` \|", upstream, re.M))
derived = set(re.findall(r"^\| \[([a-z0-9-]+)/", upstream, re.M))
if not copies:
    error(UPSTREAM, "the table of copies is missing, with one `| `name` | …` row per copy")
for name in sorted(derived & copies):
    error(UPSTREAM, f'"{name}" is a copy and also has derived files; a derived file belongs to an own skill')

skills = sorted(d for d in os.listdir("skills") if os.path.isfile(f"skills/{d}/SKILL.md"))
texts = {}
for name in skills:
    path = f"skills/{name}/LICENSE"
    if os.path.islink(path):
        error(path, "is a symlink: npx skills drops one that leads out of the folder, and the project would get the skill without its license; make it a regular file")
    elif not os.path.isfile(path):
        error(path, "is missing: a project receives only the skill's folder, so its license has to be inside")
    else:
        texts[name] = read(path)

root = read("LICENSE") if os.path.isfile("LICENSE") else None
if root is None:
    error("LICENSE", "is missing: it is the license of the kit, which GitHub shows for the repo and the own skills carry")
elif MATT.search(root):
    error("LICENSE", "names Matt Pocock: the root LICENSE is the kit's own, and his notice goes in the copies")

copy_texts = Counter(texts[n] for n in copies if n in texts)
matt = copy_texts.most_common(1)[0][0] if copy_texts else None
if matt is not None and not MATT.search(matt):
    error(UPSTREAM, "the LICENSE the copies carry does not name Matt Pocock in its copyright line: a copy has to carry his notice")

for name in skills:
    if name not in texts:
        continue
    path = f"skills/{name}/LICENSE"
    if name in copies:
        if texts[name] != matt:
            error(path, "differs from the LICENSE of the other copies: every copy carries the same notice, Matt's")
    elif root is None:
        continue
    elif name in derived:
        if matt is not None and texts[name] != root + "\n" + matt:
            error(path, f"has to be the root LICENSE, a blank line and Matt's notice: {name} has files derived from his, listed in {UPSTREAM}")
    elif texts[name] != root:
        error(path, f"has to be the root LICENSE: {name} is an own skill, without a row in {UPSTREAM}")

for line in errors:
    print(line)
print(f"{len(skills)} skills checked, {len(errors)} errors")
sys.exit(1 if errors else 0)
