# pjrt-builds

Builds of the PJRT plugins and `stablehlo-opt` that the r-xla packages download.

## PJRT plugins

The plugins are rebuilds of a [zml/pjrt-artifacts](https://github.com/zml/pjrt-artifacts) release, run
on our own schedule. `zml.env` names that release. At run time, the `Build PJRT` workflow takes from it:

- the XLA commits (`openxla/commits.env`): `openxla/xla` for the CPU plugins, `zml/xla` for CUDA,
- the patches and bazelrc applied to `openxla/xla` (`openxla/patches/`, `openxla/bazelrc/`),
- the build matrix: bazel flags, targets and artifact names (`.github/workflows/_build.yaml`, translated by
  `tools/zml-matrix.py`, which drops the flags for zml's BuildBuddy remote build).

Only the runners (GitHub-hosted, or [RunsOn](https://runs-on.com) on our AWS account with `runner: runs-on`) and the
release are ours, plus the Windows plugin, which zml does not ship
and which is built from the same `openxla/xla` commit. Patches of our own go into `patch/pjrt/<target>/`
(`cpu`, `cuda`, `windows`) and are applied on top of zml's.

Assets are named like zml's: `pjrt-<target>_<os>-<arch>.tar.gz` (`pjrt-cpu_windows-amd64.zip` for Windows).

### Rebuilding

1. Bump `ZML_REF` in `zml.env` (or keep it to rebuild the same pins).
2. Run `Build PJRT` with `release` ticked. The release is tagged `zml-<ZML_REF>` unless you pass `tag`.

To build other XLA commits than zml's, pass `xla_commit` / `cuda_xla_commit` together with a `tag`; zml's
patches must still apply to them. `cuda_compute_capabilities` narrows the GPU architectures the CUDA plugin
is built for, which shortens its build. `only` restricts a run to some builds, e.g. `cpu_linux-amd64`.

### Builds longer than 6 hours

A build job stops bazel after `BUILD_MINUTES` (300), saves bazel's disk cache and fails. Re-running the
failed jobs (*Re-run failed jobs*) continues from that cache; the release job runs once all builds have
succeeded. GitHub caches at most 10 GB per repository, so large caches of parallel jobs can evict each other.
