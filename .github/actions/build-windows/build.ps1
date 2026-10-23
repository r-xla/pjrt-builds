# Runs inside the build image with the XLA checkout mounted at C:\xla, under
# Windows PowerShell 5.1, which every Windows Server image has (PowerShell 7
# only in the newer ones). Builds the CPU plugin and copies it out of the
# container's bazel output as C:\xla\pjrt_cpu.dll.
$ErrorActionPreference = 'Stop'
Set-Location C:\xla

$bazel = (Get-Command bazel, bazelisk -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $bazel) { throw 'no bazel or bazelisk in the build image' }

# The bazel output stays in the container, as in XLA's Windows CI.
& $bazel --output_user_root=C:/x build //xla/pjrt/c:pjrt_c_api_cpu_plugin.so
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# bazel-bin points into C:/x, which only exists in this container.
Copy-Item -Force bazel-bin\xla\pjrt\c\pjrt_c_api_cpu_plugin.so C:\xla\pjrt_cpu.dll
