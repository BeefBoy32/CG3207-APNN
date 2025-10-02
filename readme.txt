# Color_Selector_v2.asm

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
