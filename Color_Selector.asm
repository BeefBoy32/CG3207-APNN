# Colour selector program

# This sample program for RISC-V simulation using RARS

.eqv MMIO_BASE 0xFFFF0000
# Memory-mapped peripheral register offsets
.eqv UART_RX_VALID_OFF 		0x00 #RO, status bit
.eqv UART_RX_OFF			0x04 #RO
.eqv UART_TX_READY_OFF		0x08 #RO, status bit
.eqv UART_TX_OFF			0x0C #WO
.eqv OLED_COL_OFF			0x20 #WO
.eqv OLED_ROW_OFF			0x24 #WO
.eqv OLED_DATA_OFF			0x28 #WO
.eqv OLED_CTRL_OFF			0x2C #WO
.eqv ACCEL_DATA_OFF			0x40 #RO
.eqv ACCEL_DREADY_OFF		0x44 #RO, status bit
.eqv DIP_OFF				0x64 #RO
.eqv PB_OFF				    0x68 #RO
.eqv LED_OFF				0x60 #WO
.eqv SEVENSEG_OFF			0x80 #WO
.eqv CYCLECOUNT_OFF			0xA0 #RO

# ------- <code memory (Instruction Memory ROM) begins>
.text	## IROM segment: IROM_BASE to IROM_BASE+2^IROM_DEPTH_BITS-1
# Total number of real instructions should not exceed 2^IROM_DEPTH_BITS/4 (127 excluding the last line 'halt B halt' if IROM_DEPTH_BITS=9).
# Pseudoinstructions (e.g., li, la) may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS.

# You can also use the actual register numbers directly. For example, instead of s1, you can write x9

main:
	li s0, MMIO_BASE		    # MMIO_BASE. Implemented as lui+addi
	addi s1, s0, LED_OFF		# LED address = MMIO_BASE + LED_OFF
	addi s5, s0, SEVENSEG_OFF   # SEVENSEG_OFF = MMIO_BASE + SEVENSEG_OFF
    addi s6, s0, PB_OFF         # PB_OFF = MMIO_BASE + PB_OFF
	li  s2, DIP_OFF			    # note that this li doesn't translate to lui, unlike the li in line 41.
	add s2, s0, s2			    # DIP address = MMIO_BASE + DIP_OFF. Could have been done in a way similar to LED address, but done this way to have a DP reg instruction
    li s11, 0x0                 # use for OLED_Data
    li s10, 0x0	                # use for oled_toggle
    addi s9, s0, OLED_CTRL_OFF  # OLED_CTRL address = MMIO_BASE + OLED_CTRL_OFF
    li t0, 0x15                 # set OLED ctrl to 0x20
    sw t0, (s9)                 # initialize OLED ctrl to 0x20
    addi s9, s0, OLED_COL_OFF   # OLED_COL address = MMIO_BASE + OLED_COL_OFF
    addi s8, s0, OLED_DATA_OFF  # OLED_DATA address = MMIO_BASE + OLED_DATA_OFF

check_btn:
    lw s3, delay_val    # reading the loop counter value
    lw s4, (s6)         # reading push buttons
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
    j wait

inc_oled_data:
    # increment the respective color component
    beqz s10, inc_red
    li t0, 1
    beq s10, t0, inc_green
    j inc_blue

inc_blue:
    # blue is [4:0]
    # check if lower 5 bits is 31, if so do nothing
    andi t0, s11, 0x1F
    li t1, 31
    beq t0, t1, update_leds
    addi s11, s11, 1
    j update_leds

inc_green:
    # green is [10:5]
    # check if bits [10:5] is 63, if so do nothing
    andi t0, s11, 0x7E0
    li t1, 0x7E0
    beq t0, t1, update_leds
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
    # Extract lower 5 bits (blue channel)
    andi t0, s11, 0x1F       # t0 = blue value
    beqz t0, update_leds     # if blue == 0, do nothing

    addi s11, s11, -1        # else decrement
    j update_leds            # jump to update_leds

dec_green:
    # green is [10:5]
    andi t0, s11, 0x7E0
    beqz t0, update_leds
    addi s11, s11, -0x20
    j update_leds    

dec_red:
    # red is [15:11]
    # Mask out red [15:11]
    li   t0, 0xF800          # load mask
    and  t1, s11, t0         # t1 = red bits
    beqz t1, update_leds     # if red == 0, skip

    # Subtract one red step (0x800)
    li   t0, 0x800
    sub  s11, s11, t0

    j update_leds

toggle_rgb:
    # 0 for R, 1 for G, 2 for B
    addi s10, s10, 1
    li t0, 3
    beq s10, t0, wrap
    j update_leds
wrap:
    li s10, 0
    j update_leds

update_leds:
    sw s11, (s5)         # writing to SEVENSEG
    sw s10, (s1)
    li t0, 0
    li t1, 96
    li t2, 0
    li t3, 65
wait:
	addi s3, s3, -1		# subtract 1
    addi t2, t2, 1
    bne t2, t3, write_data
    li t2, 0
    addi t0, t0, 1
    beq t0, t1, reset_col
    j write_data
reset_col:
    li t0, 0
write_data:
    sw t0, (s9)     # write to OLED_COL
    sw s11, (s8)     # write to OLED_DATA
	beq s3, zero, check_btn	# exit the loop
	jal zero, wait		# continue in the loop (could also have written j wait).

halt:	
	j halt		# infinite loop to halt computation. A program should not "terminate" without an operating system to return control to
				# keep halt: j halt as the last line of your code so that there is a 'dead end' beyond which execution will not proceed.
				
# ------- <code memory (Instruction Memory ROM) ends>			
				
								
#------- <Data Memory begins>									
.data  ## DMEM segment: DMEM_BASE to DMEM_BASE+2^DMEM_DEPTH_BITS-1
# Total number of constants+variables should not exceed 2^DMEM_DEPTH_BITS/4 (128 if DMEM_DEPTH_BITS=9).

DMEM:
delay_val: .word 300000  # a constant, at location DMEM+0x00
string1:
.asciz "\r\nWelcome to CG3207..\r\n"	# string, from DMEM+0x4 to DMEM+0x18 (word address, including null character. The last character is at a byte address 0x1B). # correction: 0x18/0x1B, not 0x1F
# Food for thought: What will be the address of var1 if string1 had one extra character, say  "..." instead of ".."? Hint: words are word-aligned.

.align 9	# To set the address at this point to be 512-byte aligned, i.e., DMEM+0x200
STACK_INIT:	# Stack pointer can be initialised to this location - DMEM+0x200 (i.e., the address of stack_top)
			# stack grows downwards, so stack pointer should be decremented when pushing and incremented when popping (if the stack is full-descending). Stack can be used for function calls and local variables.
		# Not allocating any heap, as it is unlikely to be used in this simple program. If we need dynamic memory allocation,we need to allocate memory and imeplement a heap manager.
#------- <Data Memory ends>													
