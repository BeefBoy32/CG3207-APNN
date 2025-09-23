main:
        li      a1, 0
        lui     a0, 1048560
        li      a3, 33
        lui     a4, 16
        li      a2, 96
        sw      a3, 44(a0)
        addi    a3, a4, -256
        li      a4, 64
.LBB0_1:
        li      a5, 0
        sw      a1, 36(a0)
.LBB0_2:
        sw      a5, 32(a0)
        addi    a5, a5, 1
        sw      a3, 40(a0)
        bne     a5, a2, .LBB0_2
        addi    a1, a1, 1
        bne     a1, a4, .LBB0_1
        lui     a1, 16
        addi    a6, a1, -256
        li      a2, 96
        li      a3, 64
        mv      a5, a6
.LBB0_5:
        lw      a1, 104(a0)
        andi    a1, a1, 2
        beqz    a1, .LBB0_5
        li      a1, 255
        lui     a4, 4080
        beq     a5, a1, .LBB0_8
        mv      a4, a6
.LBB0_8:
        bne     a5, a6, .LBB0_10
        li      a4, 255
.LBB0_10:
        li      a5, 0
.LBB0_11:
        li      a1, 0
        sw      a5, 36(a0)
.LBB0_12:
        sw      a1, 32(a0)
        addi    a1, a1, 1
        sw      a4, 40(a0)
        bne     a1, a2, .LBB0_12
        addi    a5, a5, 1
        bne     a5, a3, .LBB0_11
.LBB0_14:
        lw      a1, 104(a0)
        andi    a1, a1, 2
        bnez    a1, .LBB0_14
        mv      a5, a4
        j       .LBB0_5