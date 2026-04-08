    .text
    .globl add
    .type add, @function

add:
    add x10, x10, x11
    jalr x0,0(x1)
