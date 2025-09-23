main:
        addi    sp, sp, -16
        sw      s0, 12(sp)
        li      t4, 0
        li      t1, 0
        li      t2, 0
        lui     a1, 1048560
        li      a0, 33
        li      a6, 255
        li      a3, 96
        li      a5, 64
        li      a7, 1
        li      t0, 2
        sw      a0, 44(a1)
        li      t3, 255
.LBB0_1:
        li      a2, 0
        andi    a4, t3, 255
        andi    t6, t2, 255
        slli    a0, a4, 16
        slli    s0, t6, 8
        or      a0, a0, s0
        andi    t5, t1, 255
        or      a0, a0, t5
.LBB0_2:
        li      s0, 0
        sw      a2, 36(a1)
.LBB0_3:
        sw      s0, 32(a1)
        addi    s0, s0, 1
        sw      a0, 40(a1)
        bne     s0, a3, .LBB0_3
        addi    a2, a2, 1
        bne     a2, a5, .LBB0_2
        lw      a2, 104(a1)
        andi    a0, a2, 2
        beqz    a0, .LBB0_12
        beqz    t4, .LBB0_9
        bne     t4, a7, .LBB0_10
        li      t4, 2
        j       .LBB0_11
.LBB0_9:
        li      t4, 1
        j       .LBB0_11
.LBB0_10:
        addi    a0, t4, -2
        seqz    a0, a0
        addi    a0, a0, -1
        and     t4, a0, t4
.LBB0_11:
        lw      a0, 104(a1)
        andi    a0, a0, 2
        bnez    a0, .LBB0_11
.LBB0_12:
        andi    a0, a2, 1
        beqz    a0, .LBB0_23
        bnez    t4, .LBB0_16
        beq     a4, a6, .LBB0_16
        addi    t3, t3, 16
        andi    a0, t3, 255
        snez    a0, a0
        addi    a0, a0, -1
        or      t3, a0, t3
        j       .LBB0_22
.LBB0_16:
        bne     t4, a7, .LBB0_19
        beq     t6, a6, .LBB0_19
        addi    t2, t2, 16
        andi    a0, t2, 255
        snez    a0, a0
        addi    a0, a0, -1
        or      t2, a0, t2
        j       .LBB0_22
.LBB0_19:
        bne     t4, t0, .LBB0_22
        beq     t5, a6, .LBB0_22
        addi    t1, t1, 16
        andi    a0, t1, 255
        snez    a0, a0
        addi    a0, a0, -1
        or      t1, a0, t1
.LBB0_22:
        lw      a0, 104(a1)
        andi    a0, a0, 1
        bnez    a0, .LBB0_22
.LBB0_23:
        andi    a2, a2, 4
        beqz    a2, .LBB0_1
        bnez    t4, .LBB0_27
        andi    a0, t3, 255
        beqz    a0, .LBB0_27
        addi    t3, t3, -16
        andi    a0, t3, 255
        addi    a0, a0, -255
        seqz    a0, a0
        addi    a0, a0, -1
        and     t3, a0, t3
        j       .LBB0_33
.LBB0_27:
        bne     t4, a7, .LBB0_30
        andi    a0, t2, 255
        beqz    a0, .LBB0_30
        addi    t2, t2, -16
        andi    a0, t2, 255
        addi    a0, a0, -255
        seqz    a0, a0
        addi    a0, a0, -1
        and     t2, a0, t2
        j       .LBB0_33
.LBB0_30:
        bne     t4, t0, .LBB0_33
        andi    a0, t1, 255
        beqz    a0, .LBB0_33
        addi    t1, t1, -16
        andi    a0, t1, 255
        addi    a0, a0, -255
        seqz    a0, a0
        addi    a0, a0, -1
        and     t1, a0, t1
.LBB0_33:
        lw      a0, 104(a1)
        andi    a0, a0, 4
        bnez    a0, .LBB0_33
        j       .LBB0_1