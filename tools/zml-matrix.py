#!/usr/bin/env python3
"""Turn zml/pjrt-artifacts' build matrix into ours.

Reads zml's .github/workflows/_build.yaml (converted to JSON) on stdin and
prints a GitHub Actions matrix as JSON: the CPU and CUDA rows with their
bazel flags, targets and artifact names, minus the BuildBuddy remote build
flags, mapped onto GitHub-hosted runners.
"""

import json
import re
import sys

TARGETS = {"cpu", "cuda"}
# Flags that only make sense with zml's BuildBuddy account.
REMOTE_FLAG = re.compile(r"^--(config=remote|remote_header=.*)$")


def runner(row):
    # zml cross-compiles every CPU platform (macOS included) on linux x86;
    # CUDA for arm64 builds natively.
    if row["target"] == "cuda" and row["platform"].endswith("arm64"):
        return "ubuntu-24.04-arm"
    return "ubuntu-24.04"


def bazel_versions(workflow):
    steps = workflow["jobs"]["pjrt-artifacts"]["steps"]
    for step in steps:
        expr = step.get("env", {}).get("USE_BAZEL_VERSION")
        if expr:
            m = re.search(r"target == 'cpu' && '([^']+)' \|\| '([^']+)'", expr)
            if not m:
                sys.exit(f"cannot parse USE_BAZEL_VERSION: {expr}")
            return {"cpu": m.group(1), "cuda": m.group(2)}
    sys.exit("no USE_BAZEL_VERSION in zml's build workflow")


def main():
    workflow = json.load(sys.stdin)
    versions = bazel_versions(workflow)
    rows = workflow["jobs"]["pjrt-artifacts"]["strategy"]["matrix"]["pjrt"]
    include = []
    for row in rows:
        if row["target"] not in TARGETS:
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
                "bazel_version": versions[row["target"]],
                "runner": runner(row),
            }
        )
    if {r["target"] for r in include} != TARGETS:
        sys.exit("zml's build matrix lost its cpu or cuda rows")
    json.dump({"include": include}, sys.stdout)


main()
