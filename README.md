# CSE 30 ARM Workspace Container

A high-performance, architecture-agnostic Docker workspace designed specifically for UCSD CSE 30 Course. This container allows teaching ARM assembly and systems programming when students or cloud platforms (like Prairielearn, Gradescope or GitHub Codespaces) are limited to x86 environments.

# 0. Getting Started
```
docker buildx build -t workspace .
docker run -d -p 9000:8080 -it workspace
```

# 1. Key Features
- Transparent ARM Emulation: Uses a custom `LD_PRELOAD` system call hook to intercept `execve`. If an ARM ELF binary is detected, it is automatically executed via `qemu-arm-static` without user intervention.
- Integrated Web Terminal: Powered by xterm-rs, providing a low-latency, responsive terminal interface directly in the browser.
- Complete Toolchain:
  - GCC Cross-Compiler: Pre-configured for `arm-linux-gnueabi`.
  - Custom Debugger (`cse30db`): A sophisticated wrapper that bridges `qemu-arm`'s GDB stub with a local GDB client for a native debugging experience.
  - Valgrind for ARM: Pre-installed and configured to detect memory leaks in ARM binaries.
- Student-Centric Design: Includes helpful stubs (like the `gdb` warning script) to guide students toward the correct tools.
- Permission Mapping: Automatic UID/GID synchronization to ensure files created in the container remain accessible to the host user.

# 2. Core Technology: Transparent Execution
The "magic" of this workspace lies in the [hook_execve.c](hook_execve.c) library.
1. Intercept: When a user runs a command, the library intercepts the `execve` system call.
2. Inspect: It checks the ELF header of the target file.
3. Translate: If the file is an ARM binary, it transparently rewrites the command to run under `qemu-arm-static`.

This allows students to use standard workflows (e.g., `make` and `./program`) without needing to know that emulation is happening in the background.

### Self-check & disable hook on ARM hosts
The entrypoint runs [check_arch_arm.c](check_arch_arm.c) first:
- It writes a tiny ARM ELF blob into `/tmp`, chmod +x, and tries to `exec()` it.
- If that ARM binary can run natively, it returns success and the entrypoint clears `LD_PRELOAD`.

So:
- On **x86 hosts**: ARM ELF won't run natively -> hook stays enabled -> ARM is emulated via QEMU.
- On **ARM hosts**: ARM ELF runs -> hook is disabled (not needed).

# 3. Notes for Instructors / Platform Integrators
### ARM Toolchain
- Toolchain root: `/usr/arm-gnu-toolchain`
- Cross-compiler and binutils are symlinked into:
  - `/usr/bin/` (many toolchain binaries)
  - `/usr/armbin` (curated "ARM-facing" tools)
Useful commands:
```
arm-none-linux-gnueabihf-gcc --version
arm-none-linux-gnueabihf-objdump -d a.out
```
### "Course-facing" ARM bin directory: `/usr/armbin`
`PATH` includes `/usr/armbin` first.

Notably:
- `/usr/armbin/gcc` is a wrapper to the ARM gcc toolchain and supports injecting flags via `GCC_WRAPPER_FLAGS`.

Example:
```
gcc hello.c -o hello_arm
```

### Valgrind (ARM under QEMU)
Valgrind is installed in the standard location; the ARM memcheck tool is wrapped so it runs via QEMU automatically.

Example:
```
valgrind ./hello_arm
```

### Debugger
```
cse30db --help
man cse30db
```



# 4. Use Case: Education at Scale
In CSE 30, providing a consistent environment is critical. This image ensures that whether a student is on an Intel Mac, a Windows PC, or using a cloud-based grading platform, the behavior of their ARM assembly code remains identical. It removes the "it works on my machine" barrier and allows instructors to focus on teaching systems concepts rather than troubleshooting environment issues.
