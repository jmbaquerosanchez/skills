#!/usr/bin/env python3
"""The frontmatter of each skill. Usage: python3 scripts/frontmatter.py

What the Agent Skills specification and `npx skills` ask for: a YAML block
between two `---` lines at the start of each skills/<name>/SKILL.md, with
`name` equal to the folder's name and `description`. A skill whose frontmatter
fails is not installed, or is installed under another name, and nothing says so
until a project looks for it. Needs PyYAML.
"""

import glob
import os
import re
import sys

import yaml

NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
errors = []


def error(path, message):
    errors.append(f"::error file={path}::{message}")


os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

paths = sorted(glob.glob("skills/*/SKILL.md"))
if not paths:
    error("skills", "there is no skills/<name>/SKILL.md")

seen = {}
for path in paths:
    folder = path.split("/")[1]
    lines = open(path, encoding="utf-8").read().split("\n")
    if lines[0] != "---" or "---" not in lines[1:]:
        error(path, "the frontmatter opens on the first line with `---` and closes with another `---` line")
        continue
    end = lines.index("---", 1)
    try:
        data = yaml.safe_load("\n".join(lines[1:end]))
    except yaml.YAMLError as e:
        error(path, "the frontmatter is not valid YAML: " + str(e).replace("\n", " "))
        continue
    if not isinstance(data, dict):
        error(path, "the frontmatter has to be a map of keys")
        continue

    name = data.get("name")
    if not isinstance(name, str) or len(name) > 64 or not NAME.fullmatch(name):
        error(path, "`name` takes lowercase letters, digits and single hyphens, up to 64 characters")
    elif name != folder:
        error(path, f'`name` is "{name}", but the folder is "{folder}"')
    elif name in seen:
        error(path, f'`name` "{name}" repeated: it is already in {seen[name]}')
    else:
        seen[name] = path

    description = data.get("description")
    if not isinstance(description, str) or not description.strip():
        error(path, "`description` is missing")
    elif len(description) > 1024:
        error(path, f"`description` is over 1024 characters ({len(description)})")

    if "disable-model-invocation" in data and not isinstance(data["disable-model-invocation"], bool):
        error(path, "`disable-model-invocation` takes true or false")

for line in errors:
    print(line)
print(f"{len(paths)} SKILL.md checked, {len(errors)} errors")
sys.exit(1 if errors else 0)
