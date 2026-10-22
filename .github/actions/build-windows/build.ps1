# Runs inside the build image with the XLA checkout mounted at C:\xla. Builds
# the CPU plugin, copies it out of the container's bazel output as
# C:\xla\pjrt_cpu.dll and checks that it exports GetPjrtApi.
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-Location C:\xla

$bazel = (Get-Command bazel, bazelisk -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $bazel) { throw 'no bazel or bazelisk in the build image' }

# The bazel output stays in the container, as in XLA's Windows CI.
& $bazel --output_user_root=C:/x build //xla/pjrt/c:pjrt_c_api_cpu_plugin.so

# bazel-bin points into C:/x, which only exists in this container.
Copy-Item -Force bazel-bin\xla\pjrt\c\pjrt_c_api_cpu_plugin.so C:\xla\pjrt_cpu.dll

$exports = & C:\tools\LLVM\bin\llvm-readobj.exe --coff-exports C:\xla\pjrt_cpu.dll
if (-not ($exports -match '\bGetPjrtApi\b')) { throw 'pjrt_cpu.dll does not export GetPjrtApi' }
Write-Host 'pjrt_cpu.dll exports GetPjrtApi'
