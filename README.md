# RISC-V Workspace Container

A high-performance Docker workspace designed specifically for RISC-V LAB. This container allows teaching 32-bit RISC-V assembly and systems programming when students or cloud platforms (like Prairielearn, Gradescope or GitHub Codespaces) are limited to x86 environments.

# 0. Getting Started
```
docker buildx build --platform linux/amd64 -t workspace .

docker run -d --platform linux/amd64 -p 9000:8080 \
  -v "$(pwd)/examples:/home/student/examples" \
  --name riscv32ws \
  workspace
```

# 1. Key Features
- Transparent RISC-V Emulation: Uses a custom `LD_PRELOAD` system call hook to intercept `execve`. If a 32-bit RISC-V ELF binary is detected, it is automatically executed via `qemu-riscv32-static` without user intervention.
- Integrated Web Terminal: Powered by xterm-rs, providing a low-latency, responsive terminal interface directly in the browser.
- Complete Toolchain:
  - GCC Cross-Compiler: Pre-configured for the packaged RV32 glibc Linux toolchain.
  - Custom Debugger (`riscv32db`): A wrapper that bridges `qemu-riscv32-static`'s GDB stub with a local GDB client for a native debugging experience.
- Student-Centric Design: Includes helpful stubs (like the `gdb` warning script) to guide students toward the correct tools.
- Permission Mapping: Automatic UID/GID synchronization to ensure files created in the container remain accessible to the host user.

# 2. Core Technology: Transparent Execution
The "magic" of this workspace lies in the [hook_execve.c](hook_execve.c) library.
1. Intercept: When a user runs a command, the library intercepts the `execve` system call.
2. Inspect: It checks the ELF header of the target file.
3. Translate: If the file is a 32-bit RISC-V binary, it transparently rewrites the command to run under `qemu-riscv32-static`.

This allows students to use standard workflows (e.g., `make` and `./program`) without needing to know that emulation is happening in the background.

# 3. Notes for Instructors / Platform Integrators
### RISC-V Toolchain
- Toolchain root: `/usr/riscv32-toolchain`
- `PATH` includes:
  - `/usr/riscvbin` (curated course-facing tools such as `gcc`, `objdump`, and `riscv32db`)
  - `/usr/riscv32-toolchain/bin` (full upstream toolchain binaries)

Notably:
- `/usr/riscvbin/gcc` is a wrapper to the packaged RV32 gcc toolchain and supports injecting flags via `GCC_WRAPPER_FLAGS`.

Example:
```
gcc hello.c -o hello_rv32
```

### Debugger
```
riscv32db --help
man riscv32db
```


# 4. Use Case: Education at Scale
In RISC-V, providing a consistent environment is critical. This image ensures that whether a student is on an Intel Mac, a Windows PC, or using a cloud-based grading platform, the behavior of their RISC-V assembly code remains identical. It removes the "it works on my machine" barrier and allows instructors to focus on teaching systems concepts rather than troubleshooting environment issues.
