# xterm js files multi stage build
FROM node:23-bullseye AS xterm-builder
WORKDIR /xtermjs
RUN npm install @xterm/xterm@5.6.0-beta.107 && \
    npm install @xterm/addon-fit@0.11.0-beta.107 && \
    npm install @xterm/addon-clipboard@0.2.0-beta.90

FROM rust:1.86-bullseye AS xterm-rs-builder
COPY xterm-rs /xterm-rs
WORKDIR /xterm-rs
RUN cargo build --release

# base image
FROM ubuntu:noble-20250404 AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /

# PL user
RUN useradd -m -s /bin/bash student
RUN OLD_UID="$(id -u student)" && \
    OLD_GID="$(id -g student)" && \
    NEW_UID=1001 && \
    NEW_GID=1001 && \
    groupmod -g "$NEW_GID" student && \
    usermod -u "$NEW_UID" -g "$NEW_GID" student && \
    find /home -user "$OLD_UID" -execdir chown -h "$NEW_UID" {} + && \
    find /home -group "$OLD_GID" -execdir chgrp -h "$NEW_GID" {} +
ENV PL_USER=student

# x86 tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo gosu ca-certificates curl wget bzip2 net-tools build-essential gdb-multiarch libssl-dev manpages-dev zstd \
        vim neovim emacs-nox nano tmux ssh git less file xxd && \
    # helix
    curl -L https://github.com/helix-editor/helix/releases/download/25.01/helix-25.01-x86_64-linux.tar.xz | tar -xJv -C / &&\
    rm -rf /helix-25.01-x86_64-linux/runtime/grammars &&\
    mv /helix-25.01-x86_64-linux/hx /usr/bin &&\
    mv /helix-25.01-x86_64-linux/runtime /usr/bin/runtime &&\
    rm -rf /helix-25.01-x86_64-linux

# timezone
RUN ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime \
    && echo "America/Los_Angeles" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# set 'vim' command to use the native vim
# set emacs native compile to use x86 gcc
# setup vim osc52
RUN update-alternatives --set vim /usr/bin/vim.basic && \
    echo "(setq native-comp-driver-options '(\"-B/usr/bin/\" \"-fPIC\" \"-O2\"))" >> /etc/emacs/site-start.d/00-native-compile.el && \
    mkdir -p "/usr/share/vim/vim91/pack/vendor/start" && \
    git clone --branch main https://github.com/ojroques/vim-oscyank.git "/usr/share/vim/vim91/pack/vendor/start/vim-oscyank" && \
    echo -e 'if !has("nvim") && !has("clipboard_working")\n\
        let s:VimOSCYankPostRegisters = ["", "+", "*"]\n\
        let s:VimOSCYankOperators = ["y", "d"]\n\
        function! s:VimOSCYankPostCallback(event)\n\
            if index(s:VimOSCYankPostRegisters, a:event.regname) != -1\n\
                        \\ && index(s:VimOSCYankOperators, a:event.operator) != -1\n\
                call OSCYankRegister(a:event.regname)\n\
            endif\n\
        endfunction\n\
        augroup VimOSCYankPost\n\
            autocmd!\n\
            autocmd TextYankPost * call s:VimOSCYankPostCallback(v:event)\n\
        augroup END\n\
    endif' >> /etc/vim/vimrc

# riscv32 gnu toolchain
RUN curl -L https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-riscv32-static -o /usr/bin/qemu-riscv32-static && \
    chmod +x /usr/bin/qemu-riscv32-static && \
    curl -L https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2026.04.05/riscv32-glibc-ubuntu-24.04-gcc.tar.xz -o /tmp/riscv32-glibc-ubuntu-24.04-gcc.tar.xz && \
    mkdir -p /usr/riscv32-toolchain && \
    tar -xvf /tmp/riscv32-glibc-ubuntu-24.04-gcc.tar.xz -C /usr/riscv32-toolchain --strip-components=1 && \
    rm /tmp/riscv32-glibc-ubuntu-24.04-gcc.tar.xz
ENV RISCV_TOOLCHAIN=/usr/riscv32-toolchain
ENV QEMU_LD_PREFIX=/usr/riscv32-toolchain/sysroot

# symbolic link
RUN mkdir -p /usr/riscvbin && \
    TOOLCHAIN_GCC="$(find /usr/riscv32-toolchain/bin -maxdepth 1 -type f -name '*-gcc' | head -n 1)" && \
    [ -n "$TOOLCHAIN_GCC" ] && \
    TOOLCHAIN_PREFIX="${TOOLCHAIN_GCC##*/}" && \
    TOOLCHAIN_PREFIX="${TOOLCHAIN_PREFIX%-gcc}" && \
    for tool in addr2line nm readelf strings strip ar as g++ cpp ld ranlib objcopy objdump size; do \
        TARGET="/usr/riscv32-toolchain/bin/${TOOLCHAIN_PREFIX}-${tool}"; \
        if [ -f "$TARGET" ]; then \
            ln -s "$TARGET" "/usr/riscvbin/${tool}"; \
        fi; \
    done && \
    printf '#!/bin/bash\nexec /usr/riscv32-toolchain/bin/%s-gcc $GCC_WRAPPER_FLAGS "$@"\n' "$TOOLCHAIN_PREFIX" > /usr/riscvbin/gcc && \
    chmod +x /usr/riscvbin/gcc

# gdb wrapper & man page
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y unminimize man-db && \
    yes | /usr/bin/unminimize || [ $? -eq 141 ]
    # mkdir -p /usr/local/man/man1
COPY gdb riscv32db /usr/riscvbin/
RUN chmod +x /usr/riscvbin/gdb /usr/riscvbin/riscv32db
COPY riscv32db.1 /usr/local/man/man1/

# exec hook
COPY hook_execve.c /
RUN QEMU_HASH="$(sha256sum /usr/bin/qemu-riscv32-static | awk "{print \$1}")" && \
    sed -i "s|PLACEHOLDER_HASH|$QEMU_HASH|g" /hook_execve.c && \
    /usr/bin/gcc -shared -fPIC -o hook_execve.so hook_execve.c -ldl -lssl -lcrypto && \
    mv /hook_execve.so /usr/lib/hook_execve.so && \
    rm hook_execve.c
ENV LD_PRELOAD=/usr/lib/hook_execve.so

# xterm rs
RUN mkdir /xterm
COPY xterm-rs/static /xterm/static
RUN curl -L https://static.jyh.sb/script/iterm-theme/themes.min.mjs -o /xterm/static/js/themes.min.mjs
COPY --from=xterm-rs-builder /xterm-rs/target/release/xterm-rs /xterm/xterm-rs
COPY --from=xterm-builder /xtermjs/node_modules/@xterm/xterm/css/xterm.css /xterm/static/css/xterm.css
COPY --from=xterm-builder /xtermjs/node_modules/@xterm/xterm/lib/xterm.mjs /xterm/static/js/xterm.mjs
COPY --from=xterm-builder /xtermjs/node_modules/@xterm/addon-fit/lib/addon-fit.mjs /xterm/static/js/addon-fit.mjs
COPY --from=xterm-builder /xtermjs/node_modules/@xterm/addon-clipboard/lib/addon-clipboard.mjs /xterm/static/js/addon-clipboard.mjs

EXPOSE 8080

# gosu helper
COPY --chmod=0755 --chown=root:root container-entry /usr/bin/
USER root
RUN mkdir -p /run /var/run && \
    touch /run/fixuid.ran /var/run/fixuid.ran

ENV PATH="/usr/riscvbin:/usr/riscv32-toolchain/bin:$PATH"
ENV IMAGE_VERSION="v1.0.0"
USER student
ENTRYPOINT ["/usr/bin/container-entry"]
