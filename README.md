# pjrt-builds

Builds of the PJRT plugins and `stablehlo-opt` that the r-xla packages download.

## CPU release for an XLA commit

`Release PJRT CPU` (`.github/workflows/release-cpu.yaml`) builds the PJRT CPU plugin for linux-amd64,
linux-arm64, darwin-arm64, darwin-amd64 and windows-amd64 from one `openxla/xla` commit and publishes them as
the release `pjrt-cpu-<short sha>`, with assets named like zml's: `pjrt-cpu_<os>-<arch>.tar.gz`.

Inputs:

- `xla_commit`: the `openxla/xla` commit.
- `artifacts`: the [zml/pjrt-artifacts](https://github.com/zml/pjrt-artifacts) ref (or a fork's) whose
  patches, bazelrc and bazel flags the linux and macOS builds use, as `owner/repo@ref`. These builds copy zml's:
  hermetic toolchains on linux x86, macOS cross-compiled, read from that ref at run time (`tools/zml-matrix.py`
  drops only the flags for zml's BuildBuddy remote build). zml's patches only apply to XLA commits near their
  pin, so a newer commit needs a ref with rebased patches, e.g.
  - `zml/pjrt-artifacts@v18.0.0` for `6b73c4c`,
  - `sebffischer/pjrt-artifacts@bump-xla-2026-10-21` for `aa1e72c`.
- `only` (optional): space-separated builds, e.g. `cpu_linux-amd64 cpu_windows-amd64`. Skips the release.

Windows, which zml does not ship, is built like JAX builds jaxlib locally on Windows:
`.github/actions/build-windows`, `bazelrc/windows/` and `patch/pjrt/windows/`.

The run first checks that all patches apply and that the release does not exist yet.

### Builds longer than 6 hours

A build job stops bazel after `BUILD_MINUTES` (300), saves bazel's disk cache and fails. Re-running the
failed jobs (*Re-run failed jobs*) continues from that cache; the release job runs once all builds have
succeeded. GitHub caches at most 10 GB per repository, so large caches of parallel jobs can evict each other.
