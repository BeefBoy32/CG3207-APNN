# Colour selector program

.eqv MMIO_BASE 0xFFFF0000
# Memory-mapped peripheral register offsets
.eqv UART_RX_VALID_OFF          0x00 #RO, status bit
.eqv UART_RX_OFF                0x04 #RO
.eqv UART_TX_READY_OFF          0x08 #RO, status bit
.eqv UART_TX_OFF                0x0C #WO
.eqv OLED_COL_OFF               0x20 #WO
.eqv OLED_ROW_OFF               0x24 #WO
.eqv OLED_DATA_OFF              0x28 #WO
.eqv OLED_CTRL_OFF              0x2C #WO
.eqv ACCEL_DATA_OFF             0x40 #RO
.eqv ACCEL_DREADY_OFF           0x44 #RO, status bit
.eqv DIP_OFF                    0x64 #RO
.eqv PB_OFF                     0x68 #RO
.eqv LED_OFF                    0x60 #WO
.eqv SEVENSEG_OFF               0x80 #WO
.eqv CYCLECOUNT_OFF             0xA0 #RO
.eqv NUM_PIXELS                 0x1800 #6144 pixels

# ------- <code memory (Instruction Memory ROM) begins>
.text    ## IROM segment: IROM_BASE to IROM_BASE+2^IROM_DEPTH_BITS-1
# Total number of real instructions should not exceed 2^IROM_DEPTH_BITS/4 (127 excluding the last line 'halt B halt' if IROM_DEPTH_BITS=9).
# Pseudoinstructions (e.g., li, la) may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS.

# You can also use the actual register numbers directly. For example, instead of s1, you can write x9

main:
    li s0, MMIO_BASE            # MMIO_BASE. Implemented as lui+addi
    
    # LED, SEVENSEG, PUSHBUTTONS, OLED data, ctrl memory address
    addi s1, s0, LED_OFF        # LED address = MMIO_BASE + LED_OFF
    addi s5, s0, SEVENSEG_OFF   # SEVENSEG_OFF = MMIO_BASE + SEVENSEG_OFF
    addi s6, s0, PB_OFF         # PB_OFF = MMIO_BASE + PB_OFF
    addi s8, s0, OLED_DATA_OFF  # OLED_DATA address = MMIO_BASE + OLED_DATA_OFF
    addi s7, s0, OLED_CTRL_OFF  # OLED_CTRL address = MMIO_BASE + OLED_CTRL_OFF
    
    # DIPS memory address
    li s2, DIP_OFF              # note that this li doesn't translate to lui, unlike the li in line 41.
    add s2, s0, s2              # DIP address = MMIO_BASE + DIP_OFF. Could have been done in a way similar to LED address, but done this way to have a DP reg instruction
    
    # write to oled ctrl
    addi s9, zero, 21           # Set OLED ctrl to 16 bit mode, and autoadvancerow mode
    sw s9, (s7)                 # write to memory

    # variables to store oled used data
    li s11, 0x0                 # use for oled_data
    li s10, 0x0                 # use for oled_toggle
    li s9, NUM_PIXELS           # num of pixels in oled

check_btn:
    lw s3, delay_val            # reading the loop counter value
    lw s4, (s6)                 # reading push buttons
    # [2:0] => { BTNL, BTNC, BTNR }

    # check BTNL (value 4)
    li   t0, 4
    beq  s4, t0, inc_oled_data

    # check BTNR (value 1)
    li   t0, 1
    beq  s4, t0, dec_oled_data

    # check BTNC (value 2)
    li   t0, 2
    beq  s4, t0, toggle_rgb

    # if not any, go to wait
    j wait

inc_oled_data:
    # increment the respective color component
    beq s10, zero, inc_red
    li t0, 1
    beq s10, t0, inc_green
    j inc_blue

inc_blue:
    # blue is [4:0]
    # check if lower 5 bits is 31, if so do nothing
    # Mask out blue field
    andi t0, s11, 0x1F
    li t1, 31
    beq t0, t1, update_leds

    # increment blue
    addi s11, s11, 1
    j update_leds

inc_green:
    # green is [10:5]
    # check if bits [10:5] is 63, if so do nothing
    # Maske out green field
    andi t0, s11, 0x7E0
    li t1, 0x7E0
    beq t0, t1, update_leds

    # increment green (shifted left by 5, so add 0x20 each step)
    addi s11, s11, 0x20
    j update_leds

inc_red:
    # red is [15:11]
    # check if bits [15:11] is 31, if so do nothing
    # Mask out red field
    li   t0, 0xF800          # load mask (upper 5 bits)
    and  t1, s11, t0         # t1 = s11 & 0xF800
    beq  t1, t0, update_leds # if already max red, skip

    # Increment red (shifted left by 11, so add 0x800 each step)
    li   t0, 0x800
    add  s11, s11, t0

    j update_leds

dec_oled_data:
    # decrement the respective color component
    beqz s10, dec_red
    li t0, 1
    beq s10, t0, dec_green
    j dec_blue

dec_blue:
    # blue is [4:0], Mask out blue
    andi t0, s11, 0x1F       # t0 = blue value
    beqz t0, update_leds     # if blue == 0, do nothing

    addi s11, s11, -1        # else decrement
    j update_leds            # jump to update_leds

dec_green:
    # green is [10:5], Mask out green
    andi t0, s11, 0x7E0      # t0 = green bits
    beqz t0, update_leds     # if green == 0, do nothing

    addi s11, s11, -0x20     # else decrement
    j update_leds            # jump to update_leds

dec_red:
    # red is [15:11], Mask out red
    li   t0, 0xF800          # load mask
    and  t1, s11, t0         # t1 = red bits
    beqz t1, update_leds     # if red == 0, do nothing

    li   t0, 0x800           # amount to decrement red
    sub  s11, s11, t0        # decrement red
    j update_leds            # jump to update_leds

toggle_rgb:
    # 0 for R, 1 for G, 2 for B
    addi s10, s10, 1         # increment color toggle
    li t0, 3                 # check if it is 3
    beq s10, t0, wrap        # if so, wrap around
    j update_leds
wrap:
    li s10, 0                # wrap around to 0
    j update_leds

update_leds:
    sw s11, (s5)            # writing oled data to SEVENSEG for debugging
    sw s10, (s1)            # writing oled toggle to LED, to indicate which color is being changed
    li t0, 0
    
update_OLED:
    beq t0, s9, wait        # if t0 == num_pixels, done updating OLED
    addi t0, t0, 1          # increment pixel counter
    sw s11, (s8)            # write color data to OLED_DATA
    j update_OLED           # repeat for all pixels
wait:
    addi s3, s3, -1         # subtract 1
    beq s3, zero, check_btn # exit the loop
    jal zero, wait          # continue in the loop (could also have written j wait).

halt:
    j halt                  # infinite loop to halt computation. A program should not "terminate" without an operating system to return control to
                            # keep halt: j halt as the last line of your code so that there is a 'dead end' beyond which execution will not proceed.

# ------- <code memory (Instruction Memory ROM) ends>


#------- <Data Memory begins>
.data  ## DMEM segment: DMEM_BASE to DMEM_BASE+2^DMEM_DEPTH_BITS-1
# Total number of constants+variables should not exceed 2^DMEM_DEPTH_BITS/4 (128 if DMEM_DEPTH_BITS=9).

DMEM:
delay_val: .word 10     # a constant, at location DMEM+0x00 (10 for sim, 50000 for hardware)
.align 9                    # To set the address at this point to be 512-byte aligned, i.e., DMEM+0x200
STACK_INIT:                 # Stack pointer can be initialised to this location - DMEM+0x200 (i.e., the address of stack_top)
#------- <Data Memory ends>
