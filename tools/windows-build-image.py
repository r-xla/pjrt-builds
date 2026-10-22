#!/usr/bin/env python3
"""Print the container image XLA's own Windows CI builds in.

Usage: windows-build-image.py <xla checkout>

XLA's xla_windows_x86_cpu_2022 bazel config (tensorflow.bazelrc) builds for
a platform in tools/toolchains/win2022/BUILD whose container-image is the
image its remote build runs in, and which its toolchain config (paths to
LLVM, MSVC and the Windows SDK) is written for. Reading both from the XLA
checkout keeps image and toolchain from the same commit.
"""

import re
import sys
from pathlib import Path

xla = Path(sys.argv[1])
rc = (xla / "tensorflow.bazelrc").read_text()
m = re.search(r'^common:xla_windows_x86_cpu_2022 --platforms="?//tools/toolchains/win2022:([\w-]+)"?', rc, re.M)
if not m:
    sys.exit("no --platforms for xla_windows_x86_cpu_2022 in tensorflow.bazelrc")
platform = m.group(1)

build = (xla / "tools/toolchains/win2022/BUILD").read_text()
m = re.search(r'name = "%s",.*?"container-image": "docker://([^"]+)"' % re.escape(platform), build, re.S)
if not m:
    sys.exit(f"no container-image for platform {platform} in tools/toolchains/win2022/BUILD")
print(m.group(1))
