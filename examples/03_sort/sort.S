    .text
    .globl sort
    .type sort, @function

sort:
    addi x2, x2, -20      # sp = sp - 20
    sw   x1, 16(x2)       # save ra
    sw   x22, 12(x2)      # save x22
    sw   x21, 8(x2)       # save x21
    sw   x20, 4(x2)       # save x20
    sw   x19, 0(x2)       # save x19

    addi x21, x10, 0      # x21 = v
    addi x22, x11, 0      # x22 = n
    addi x19, x0, 0       # i = 0

for1tst:
    bge  x19, x22, exit1  # if i >= n, exit

    addi x20, x19, -1     # j = i - 1

for2tst:
    blt  x20, x0, exit2   # if j < 0, exit inner loop

    slli x5, x20, 2       # x5 = j * 4
    add  x5, x21, x5      # x5 = v + (j * 4)
    lw   x6, 0(x5)        # x6 = v[j]
    lw   x7, 4(x5)        # x7 = v[j+1]
    ble  x6, x7, exit2    # if v[j] <= v[j+1], exit inner loop

    addi x10, x21, 0      # arg0 = v
    addi x11, x20, 0      # arg1 = j
    jal  x1, swap         # call swap(v, j)

    addi x20, x20, -1     # j = j - 1
    jal  x0, for2tst      # repeat inner loop

exit2:
    addi x19, x19, 1      # i = i + 1
    jal  x0, for1tst      # repeat outer loop

exit1:
    lw   x19, 0(x2)       # restore x19
    lw   x20, 4(x2)       # restore x20
    lw   x21, 8(x2)       # restore x21
    lw   x22, 12(x2)      # restore x22
    lw   x1, 16(x2)       # restore ra
    addi x2, x2, 20       # sp = sp + 20
    jalr x0, 0(x1)        # return
