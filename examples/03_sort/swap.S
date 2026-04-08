    .text
    .globl swap
    .type swap, @function

swap:
    slli x6, x11, 2       # x6 = k * 4
    add  x6, x10, x6      # x6 = v + (k * 4)
    lw   x5, 0(x6)        # x5(temp) = v[k]
    lw   x7, 4(x6)        # x7 = v[k+1]
    sw   x7, 0(x6)        # v[k] = x7
    sw   x5, 4(x6)        # v[k+1] = x5
    jalr x0, 0(x1)        # return
