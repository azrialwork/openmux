<!--
  vendor/README.md -- Provenance of the vendored Bionic libopentui.so.

  Where the file came from, why it is vendored instead of built, and how to
  refresh it. One topic: the vendored TUI library.
-->

# vendor/

## libopentui-bionic.so

The Bionic (Android) build of OpenTUI's native library, swapped into the
transplanted binary by `swap_tui.py` so the TUI renders on Termux. The
upstream `opencode-linux-arm64` tarball embeds a glibc build that Bionic's
linker rejects.

### Why vendored, not built

Building it from source (`tools/transplant/build-libopentui.sh`) requires
the maintainer's on-device Termux environment (OpenTUI w7b source tree,
bionic hdrfix dirs, aarch64 Zig 0.16, SELinux shim) -- it cannot run on an
x86_64 GitHub runner (verified: fails immediately on missing `llvm-strip`,
then on Termux-only paths). This file was extracted from a published native
build instead (see below) and passes `swap_tui.py`'s own gates: not
glibc-linked, carries the FFI negative-coordinate guard v2.

### Provenance

- Source: `Hope2333/opencode-termux` release `Push261005`, asset
  `opencode_2.0.22_aarch64.deb` (their native build of opencode 2.0.22)
- Extracted: the `/$bunfs/root/libopentui-*.so` asset (raw ELF) from the
  release binary -- the exact bytes their pipeline swapped in
- Size: 5,495,136 bytes; ELF aarch64; NEEDED `libm.so`, `libc.so`, `libdl.so`
- License: MIT (Hope2333/opencode-termux); built from OpenTUI (MIT) plus
  their patches -- attribution in the repo README

## libopencode-crhandler.so

The upstream seccomp shim. On older Android kernels (e.g. 4.14) the
seccomp filter kills the binary with SIGSYS ("Bad system call") on blocked
syscalls (close_range and friends). This 8 KB shim installs a SIGSYS
handler and interposes `syscall()`/`close_range()` (verified exports);
`crhandler_patch.py` injects it as the FIRST DT_NEEDED entry of the
transplanted binary, and the binary finds it via DT_RUNPATH
`$ORIGIN/../lib/opencode` -- hence the tarball ships it at
`lib/opencode/libopencode-crhandler.so`.

### Provenance

- Source: same deb as above, shipped by upstream as a separate file at
  `$PREFIX/lib/opencode/libopencode-crhandler.so` -- copied byte-identical
- ELF aarch64; NEEDED `libc.so`, `libdl.so` (Bionic)
- License: MIT (Hope2333/opencode-termux)

### Refreshing

`swap_tui.py` enforces: incoming `.so` <= embedded slot size, not
glibc-linked, guard v2 present. It fails loudly otherwise. If a future
opencode version breaks the swap:

1. Download the newer `opencode_<ver>_aarch64.deb` from their releases
2. Extract the binary and pull `/$bunfs/root/libopentui-*.so` (raw ELF,
   exact `elf_size`) -- see the research note for the one-shot script
3. Verify with `swap_tui.py`'s `is_glibc_linked` / `has_ffi_guard`
4. Replace this file and bump the note above
