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

Assets are named like zml's: `pjrt-<target>_<os>-<arch>.tar.gz`. The Windows plugin is built like JAX builds
jaxlib locally on Windows (`.github/actions/build-windows`, `bazelrc/windows/`, `patch/pjrt/windows/`).

### CPU release for an XLA commit

`Release PJRT CPU` builds the CPU plugin for linux-amd64, linux-arm64, darwin-arm64, darwin-amd64 and
windows-amd64 from one `openxla/xla` commit and publishes them as the release `pjrt-cpu-<short sha>`. It takes
two inputs:

- `xla_commit`: the `openxla/xla` commit,
- `artifacts`: the pjrt-artifacts ref whose patches, bazelrc and bazel flags the non-Windows builds use, as
  `owner/repo@ref`. zml's patches only apply to commits near their pin, so a newer XLA commit needs a ref
  with rebased patches, e.g. `zml/pjrt-artifacts@v18.0.0` for `6b73c4c`,
  `sebffischer/pjrt-artifacts@bump-xla-2026-10-21` for `aa1e72c`.

The run checks first that all patches apply and that the release does not exist yet. `only` restricts it to
some builds and then skips the release.

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
