# pjrt-builds

Builds of the PJRT plugins and `stablehlo-opt` that the r-xla packages download.

## CPU release for an XLA commit

`Release PJRT CPU` (`.github/workflows/release-cpu.yaml`) builds the PJRT CPU plugin for linux-amd64,
linux-arm64, darwin-arm64, darwin-amd64 and windows-amd64 from one `openxla/xla` commit (input `xla_commit`)
and publishes them as the release `pjrt-cpu-<short sha>`, with assets `pjrt-cpu_<os>-<arch>.tar.gz`.

The run first checks that all patches apply to the commit and that the release does not exist yet. `only`
(optional, e.g. `cpu_linux-amd64 cpu_windows-amd64`) restricts it to some builds and then skips the release.

### Linux and macOS: zml's build setup

The linux and macOS plugins are built with the build setup of [zml/pjrt-artifacts](https://github.com/zml/pjrt-artifacts)
by [ZML](https://zml.ai), copied into this repository: hermetic LLVM toolchains on linux x86, macOS
cross-compiled with a macOS SDK, the same bazel flags and Bazel version. Thanks to the ZML team for working
this out and sharing it. What we took and changed:

- `bazelrc/cpu/`: their `openxla/bazelrc/upstream/.bazelrc` and `tensorflow.bazelrc`, which replace XLA's.
  We left out their BuildBuddy remote build and CUDA configs, and register their toolchains with
  `--extra_toolchains` (see below).
- `patch/pjrt/cpu/`: their CPU patches `0001` (plugin target name) and `0002` (macOS install name) as they are.
  `0003` adds their hermetic toolchain, which they insert into XLA's `MODULE.bazel`; ours appends it to the end
  of the file instead, so that it applies to any recent XLA commit rather than only to their pin. Their other
  patches are left out: they are GPU-only, already upstream, or a small performance change that has to be
  rebased for every XLA bump.
- The build matrix in `release-cpu.yaml`: their CPU rows, without the remote build flags.

### Windows

Windows, which zml does not ship, is built like JAX builds jaxlib locally on Windows:
`.github/actions/build-windows`, `bazelrc/windows/` and `patch/pjrt/windows/`.

### Builds longer than 6 hours

A build job stops bazel after `BUILD_MINUTES` (300), saves bazel's disk cache and fails. Re-running the
failed jobs (*Re-run failed jobs*) continues from that cache; the release job runs once all builds have
succeeded. GitHub caches at most 10 GB per repository, so large caches of parallel jobs can evict each other.
