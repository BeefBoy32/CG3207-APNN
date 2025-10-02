-------------------------------------------------------------------
Color_Selector_v2.asm

This program is written in RISC-V assembly and demonstrates colour selection and manipulation on an OLED display using pushbuttons, DIP switches, LEDs, and a seven-segment display. It uses memory-mapped I/O (MMIO) to interact with hardware peripherals.
The program allows a user to:
- Increment or decrement the red, green, or blue components of a 16-bit RGB colour.
- Toggle between which colour component is being adjusted.
- Display the selected colour on the OLED screen and debug values on LEDs/7-seg.

The following peripherals are used via MMIO:
- LEDs → Indicate the currently selected colour channel (R, G, or B).
- Seven-segment display → Shows the 16-bit colour value for debugging.
- Pushbuttons → Control adjustments:

- BTNL (4) → Increment current colour component.
- BTNR (1) → Decrement current colour component.
- BTNC (2) → Toggle between Red → Green → Blue.
- OLED display → Displays the current colour across all pixels.

Program Flow
1. Initialize MMIO base addresses and OLED control registers.
2. Enter main loop:
   * Wait for delay counter.
   * Poll pushbuttons.
   * Update selected colour component (R/G/B).
   * Write updated colour to:
     * **Seven-segment display** (debugging).
     * **LEDs** (show which colour is active).
     * **OLED display** (fill with the selected colour).
3. Loop indefinitely until halted.

Data Memory
-`delay_val`: Loop delay counter (default = 50000 for hardware, can be reduced for simulation).

-------------------------------------------------------------------
PC_Logic.v

This file defines the PC_Logic module for the RISC-V processor. Its purpose is to determine whether the program counter (PC) should branch to a new address or simply continue sequential execution. It takes in PCS (which indicates the type of control flow: normal, branch, jump, or jump-register), Funct3 (the specific branch condition from the instruction), and ALUFlags produced by the ALU. Based on these, it sets the output signal PCSrc, which tells the processor whether to update the PC with a branch/jump target or just move to the next instruction. This module implements the decision logic for conditional and unconditional jumps/branches, ensuring correct control flow in the RISC-V pipeline. Currently for branching only equal and not equal conditions are supported and jump instructions do not support linking.

-------------------------------------------------------------------
ALU.v

The ALU performs arithmetic, logical, and shift operations as specified by the RISC-V ISA. It serves as a fundamental component of the processor datapath.

Features
  Arithmetic operations:
    Addition (ALUControl = 0000)
    Subtraction (ALUControl = 0001)
  Logical operations:
    AND (ALUControl = 1110)
    OR (ALUControl = 1100)
  Shift operations:
    Shift Left Logical (ALUControl = 0010)
    Shift Right Logical (ALUControl = 1010)
    Shift Right Arithmetic (ALUControl = 1011)
  Flags output (ALUFlags):
    eq (equality check)
    lt (less-than, placeholder for now)
    ltu (unsigned less-than, placeholder for now)

Module I/O
Inputs
  Src_A [31:0] : First operand
  Src_B [31:0] : Second operand
  ALUControl [3:0] : Operation selector
Outputs
  ALUResult [31:0] : Result of the ALU operation
  ALUFlags [2:0] : Status flags {eq, lt, ltu}
-------------------------------------------------------------------
Decoder.v

This file defines the Decoder module for our processor. Its role is to interpret the instruction fields (Opcode, Funct3, Funct7) and generate the control signals that drive the rest of the datapath. Based on the instruction type (e.g., R-type, I-type, load, store, branch, jump, lui, auipc), the decoder outputs signals such as PCS (to control program counter updates), RegWrite (whether to write back to the register file), MemWrite and MemtoReg (for memory operations), ALUSrcA and ALUSrcB (to select ALU inputs), and ImmSrc (to choose the correct immediate extension format). It also generates the ALUControl signal that specifies which ALU operation should be performed (e.g., add, sub, shift, and, or).

-------------------------------------------------------------------
RV.v

This file defines the RISC-V processor module. It connects and coordinates the major components of a simple CPU, including the program counter, instruction decoder, register file, immediate extender, ALU, and PC control logic. The module takes in a clock, reset, instruction, and memory input data, and produces outputs for memory access, the program counter, ALU result, and write data. Internal wiring and control signals (like ALUSrcA, ALUSrcB, MemtoReg, RegWrite, etc.) are generated through the decoder to steer the datapath correctly depending on the instruction. This file describes how the datapath elements of the RISC-V processor are connected and controlled to fetch, decode, execute instructions, and update registers or memory. It serves to integrate the different submodules in a processor.

-------------------------------------------------------------------
test_Wrapper_Color_Selector_self_checking.v

Self checking testbench to check if the assembly programme runs as expected, by running test cases to check for the following to ensure that our processor instructions are working as expected:

1. All PB (L,C,R) have been pressed:
Expected - SEVENSEG and LED_OUT[2:0] display to remain the same,

2. PB L pressed:
Expected -  Depending on LED_OUT [2:0] value (0 for red, 1 for green, 2 for blue),1 cycle after LED_PC == SW_LED_PC_VALUE,  the following values will increase by 1 if not at maximum value, else remain the same from the values sampled when LED_PC == LW_LED_PC_VALUE:
red   <= SEVENSEGHEX[15:11];
green <= SEVENSEGHEX[10:5];
blue  <= SEVENSEGHEX[4:0];

3. PB R pressed:
Expected -  Depending on LED_OUT [2:0] value (0 for red, 1 for green, 2 for blue),1 cycle after LED_PC == SW_LED_PC_VALUE,  the following values will decrease by 1 if not at minimum value, else remain the same from the values sampled when LED_PC == LW_LED_PC_VALUE:
red   <= SEVENSEGHEX[15:11];
green <= SEVENSEGHEX[10:5];
blue  <= SEVENSEGHEX[4:0];

4. PB C pressed:
Expected -  LED_OUT [2:0] value will cycle to the next value when ,LED_PC == SW_LEDOUT_LED_PC_VALUE, e.g 0->1, 1->2, 2->0 from the value of  LED_OUT [2:0] when LED_PC == LW_LED_PC_VALUE.


