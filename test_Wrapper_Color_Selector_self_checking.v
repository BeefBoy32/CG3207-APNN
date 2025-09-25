`timescale 1ns / 1ps
module test_Wrapper #(
       parameter N_LEDs_OUT = 8,					
       parameter N_DIPs     = 16,
       parameter N_PBs      = 3,
       // Self-checking parameters
       parameter [8:0] LW_PB_PC_ADDRESS     = 9'h044,  // Default: bits[8:2] = 0x11
       parameter [8:0] SW_SEVENSEG_PC_ADDRESS = 9'h124   // Default: bits[8:2] = 0x49
    )
    (
    );
    
    // Derived parameters for LED_PC monitoring
    localparam [6:0] LW_LED_PC_VALUE = LW_PB_PC_ADDRESS[8:2];   // 0x11
    localparam [6:0] SW_LED_PC_VALUE = SW_SEVENSEG_PC_ADDRESS[8:2]; // 0x49
    localparam [6:0] NEXT_SW_LED_PC = SW_LED_PC_VALUE + 1;      // 0x4A
    localparam [6:0] NEXT_LW_LED_PC = LW_LED_PC_VALUE + 1;      // 0x23
    
    // Signals for the Unit Under Test (UUT)
    reg  [N_DIPs-1:0] DIP = 0;		
    reg  [N_PBs-1:0] PB = 0;			
    wire [N_LEDs_OUT-1:0] LED_OUT;
    wire [6:0] LED_PC;			
    wire [31:0] SEVENSEGHEX;	
    wire [7:0] UART_TX;
    reg  UART_TX_ready = 0;
    wire UART_TX_valid;
    reg  [7:0] UART_RX = 0;
    reg  UART_RX_valid = 0;
    wire UART_RX_ack;
    wire OLED_Write;
    wire [6:0] OLED_Col;
    wire [5:0] OLED_Row;
    wire [23:0] OLED_Data;
    reg [31:0] ACCEL_Data;
    wire ACCEL_DReady;			
    reg  RESET = 0;	
    reg  CLK = 0;				
    
    // Self-checking variables
    reg [6:0] prev_led_pc;
    reg [2:0] sampled_pb;
    reg [4:0] sampled_sevenseg;
    reg [4:0] expected_sevenseg;
    reg [4:0] actual_sevenseg;
    reg sample_valid;
    reg check_pending;
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Instantiate UUT
    Wrapper dut(DIP, PB, LED_OUT, LED_PC, SEVENSEGHEX, UART_TX, UART_TX_ready, UART_TX_valid, UART_RX, UART_RX_valid, UART_RX_ack, OLED_Write, OLED_Col, OLED_Row, OLED_Data, ACCEL_Data, ACCEL_DReady, RESET, CLK);
    
    // Self-checking monitor - runs on positive clock edge
    always @(posedge CLK) begin
        if (RESET) begin
            // Reset all monitoring variables
            prev_led_pc <= 7'h00;
            sampled_pb <= 3'b000;
            sampled_sevenseg <= 5'b00000;
            expected_sevenseg <= 5'b00000;
            sample_valid <= 1'b0;
            check_pending <= 1'b0;
            test_count <= 0;
            pass_count <= 0;
            fail_count <= 0;
        end else begin
            prev_led_pc <= LED_PC;
            
            // Sample PB and SEVENSEGHEX when LED_PC transitions from 0x11 to 0x12
            if (prev_led_pc == LW_LED_PC_VALUE && LED_PC == NEXT_LW_LED_PC) begin
                sampled_pb <= PB;
                sampled_sevenseg <= SEVENSEGHEX[15:11];
                sample_valid <= 1'b1;
                check_pending <= 1'b0;  // Clear any pending check
                $display("[%0t] SAMPLE: LED_PC 0x%02X->0x%02X, PB=3'b%03b, SEVENSEG[15:11]=5'b%05b", 
                         $time, prev_led_pc, LED_PC, PB, SEVENSEGHEX[15:11]);
            end
            
            // Check behavior when LED_PC transitions from 0x49 to 0x4A
            if (prev_led_pc == SW_LED_PC_VALUE && LED_PC == NEXT_SW_LED_PC && sample_valid) begin
                actual_sevenseg <= SEVENSEGHEX[15:11];
                check_pending <= 1'b1;
                
                // Calculate expected value based on sampled PB
                if (sampled_pb == 3'b100) begin  // Increment case
                    if (sampled_sevenseg != 5'b11111) begin
                        expected_sevenseg <= sampled_sevenseg + 1;
                    end else begin
                        expected_sevenseg <= sampled_sevenseg;  // Stay same at max
                    end
                end else if (sampled_pb == 3'b001) begin  // Decrement case
                    if (sampled_sevenseg != 5'b00000) begin
                        expected_sevenseg <= sampled_sevenseg - 1;
                    end else begin
                        expected_sevenseg <= sampled_sevenseg;  // Stay same at min
                    end
                end else begin
                    expected_sevenseg <= sampled_sevenseg;  // No change for other PB values
                end
            end
            
            // Perform the check one cycle after setting check_pending
            if (check_pending) begin
                test_count <= test_count + 1;
                
                if (SEVENSEGHEX[15:11] == expected_sevenseg) begin
                    pass_count <= pass_count + 1;
                    $display("[%0t] PASS #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LED_PC_VALUE, NEXT_SW_LED_PC, sampled_pb);
                    $display("         Expected SEVENSEG[15:11]=5'b%05b, Actual=5'b%05b", 
                             expected_sevenseg, SEVENSEGHEX[15:11]);
                end else begin
                    fail_count <= fail_count + 1;
                    $display("[%0t] FAIL #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LED_PC_VALUE, NEXT_SW_LED_PC, sampled_pb);
                    $display("         Expected SEVENSEG[15:11]=5'b%05b, Actual=5'b%05b", 
                             expected_sevenseg, SEVENSEGHEX[15:11]);
                end
                
                check_pending <= 1'b0;
                sample_valid <= 1'b0;  // Clear sample for next iteration
            end
        end
    end
    
    // Test summary at end of simulation
    initial begin
        #2000;  // Wait for simulation to complete
        $display("\n==================== TEST SUMMARY ====================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0 && test_count > 0) begin
            $display("Result:      ALL TESTS PASSED!");
        end else if (test_count == 0) begin
            $display("Result:      NO TESTS EXECUTED");
        end else begin
            $display("Result:      SOME TESTS FAILED");
        end
        $display("=====================================================\n");
        $finish;
    end
    
    // Note: This testbench is for DIP_to_LED program. Other assembly programs require appropriate modifications.
    // STIMULI
    initial
    begin
        RESET = 1; #10; RESET = 0; //hold reset state for 10 ns.
        PB = 3'b100; // Increase colour Red
        #220;			
        PB = 3'b001;
        #220;	
    end
    
    // GENERATE CLOCK       
    always          
    begin
       #5 CLK = ~CLK ; // invert clk every 5 time units 
    end
    
    // Optional: Continuous monitoring display (can be disabled by commenting out)
    always @(posedge CLK) begin
        if (!RESET && LED_PC == LW_LED_PC_VALUE) begin
            $display("[%0t] INFO: At lw instruction (LED_PC=0x%02X), PB=3'b%03b, SEVENSEG[15:11]=5'b%05b", 
                     $time, LED_PC, PB, SEVENSEGHEX[15:11]);
        end
        if (!RESET && LED_PC == SW_LED_PC_VALUE) begin
            $display("[%0t] INFO: At sw instruction (LED_PC=0x%02X), SEVENSEG[15:11]=5'b%05b", 
                     $time, LED_PC, SEVENSEGHEX[15:11]);
        end
    end
    
endmodule