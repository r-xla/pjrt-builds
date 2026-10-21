#!/usr/bin/env python3
"""Turn pjrt-artifacts' build matrix into our CPU build matrix.

Reads the .github/workflows/_build.yaml of zml/pjrt-artifacts (or a fork),
converted to JSON, on stdin and prints a GitHub Actions matrix as JSON: its
CPU rows with their bazel flags, targets and artifact names, minus the
BuildBuddy remote build flags. Like zml, every row builds on linux x86, macOS
included (cross-compiled with hermetic toolchains).
"""

import json
import re
import sys

# Flags that only make sense with zml's BuildBuddy account.
REMOTE_FLAG = re.compile(r"^--(config=remote|remote_header=.*)$")


def cpu_bazel_version(workflow):
    steps = workflow["jobs"]["pjrt-artifacts"]["steps"]
    for step in steps:
        expr = step.get("env", {}).get("USE_BAZEL_VERSION")
        if expr:
            m = re.search(r"target == 'cpu' && '([^']+)'", expr)
            if not m:
                sys.exit(f"cannot parse USE_BAZEL_VERSION: {expr}")
            return m.group(1)
    sys.exit("no USE_BAZEL_VERSION in the pjrt-artifacts build workflow")


def main():
    workflow = json.load(sys.stdin)
    version = cpu_bazel_version(workflow)
    rows = workflow["jobs"]["pjrt-artifacts"]["strategy"]["matrix"]["pjrt"]
    include = []
    for row in rows:
        if row["target"] != "cpu":
            continue
        flags = [f for f in row["config"].split() if not REMOTE_FLAG.match(f)]
        include.append(
            {
                "target": row["target"],
                "platform": row["platform"],
                "config": " ".join(flags),
                "bazel_target": row["bazel_target"],
                "artifact": row["artifact"],
                "renamed_artifact": row["renamed_artifact"],
                "bazel_version": version,
            }
        )
    if not include:
        sys.exit("the pjrt-artifacts build matrix has no cpu rows")
    json.dump({"include": include}, sys.stdout)


main()
