# r-xla patches for the IREE PJRT plugin

Applied on top of [`r-xla/iree`](https://github.com/r-xla/iree), branch
`pjrt-c-api-0.114`, in the order listed. Everything on that branch is
deliberately *general* — it is what any client using IREE through PJRT needs,
and is written to be upstreamable to `iree-org/iree`. Anything specific to this
stack lives here instead.

Apply the way the other patch sets are applied:

```sh
git apply ../patch/iree/platform-name-cpu.patch
git apply ../patch/iree/segv-backtrace.patch
```

## `platform-name-cpu.patch` — required

Changes the CPU client's reported platform name from `iree_cpu` to `cpu`.

The platform name is the key a client is registered and looked back up under.
`r-xla/pjrt` registers this plugin as its **`cpu`** platform (via
`PJRT_PLUGIN_PATH_CPU`), and `client_from_device()` resolves a device back to
its client through `the[["clients"]][[platform(device)]]`. With the upstream
name, that lookup misses and the very first buffer creation fails with

```
Error: Expecting an external pointer: [type=NULL].
```

With the patch, `platform(client)` is `cpu` and the device is
`CpuDevice(id=0)`, so the plugin is a drop-in for the XLA CPU plugin
throughout the stack.

**Why it is not upstream:** it hardcodes one client's registration convention.
The upstream bug is the TODO already sitting next to the line — "Seems that it
must match how registered. Action at a distance not great." — and the real fix
is to derive the name from how the client was registered, which is a larger
change and not ours to make unilaterally. Note the cost: with this applied,
`platform(client)` no longer tells you *which* plugin is loaded; only
`PJRT_PLUGIN_PATH_CPU` does.

## `segv-backtrace.patch` — optional, debugging only

Adds an opt-in native backtrace on `SIGSEGV`/`SIGBUS`, enabled by setting
`RXLA_TRAP_SEGV=1`.

R installs its own signal handler at startup which prints only the R call
stack, and that stops at the `.Call` boundary — so a crash inside the plugin
or inside IREE shows nothing useful. Because the plugin is dlopened *after* R
starts, a handler installed here wins. Resolve the printed offsets with:

```sh
addr2line -f -C -e pjrt_plugin_iree_cpu.so 0xd4f82 0x69aad ...
```

This is what located the missing device-group assignment that is now fixed on
the fork branch (four wrong hypotheses had been tried before instrumenting).
Worth keeping for the next one.

**Why it is not upstream:** it is a debugging aid named after this project, and
upstream would reasonably want a different spelling and a different opt-in.

## Compiler options

Not a patch, but needed alongside them. The plugin reads these from
`IREE_PJRT_IREE_COMPILER_OPTIONS`:

```sh
--iree-input-demote-f64-to-f32=false
--iree-llvmcpu-link-embedded=false
--iree-opt-const-eval=false
```

R's `numeric` is f64, and IREE demotes f64 to f32 by default while rewriting
the public function signature, warning but not failing — so without the first
flag every compile succeeds and every execution fails on a dtype mismatch. The
other two are consequences of the first; the reasoning is in
`integrations/pjrt/README.md` on the fork branch.
