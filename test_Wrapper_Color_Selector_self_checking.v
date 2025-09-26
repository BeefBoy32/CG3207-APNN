`timescale 1ns / 1ps
module test_Wrapper #(
       parameter N_LEDs_OUT = 8,					
       parameter N_DIPs     = 16,
       parameter N_PBs      = 3,
       // Self-checking parameters
       parameter LW_PB_PC_ADDRESS     = 9'h044,  // Default: bits[8:2] = 0x11
       parameter SW_SEVENSEG_PC_ADDRESS = 9'h124,  // Default: bits[8:2] = 0x49
       parameter SW_LEDOUT_PC_ADDRESS = 9'h128   // Default: bits[8:2] = 0x4A
    )
    (
    );
    
    // Derived parameters for LED_PC monitoring
    localparam LW_LED_PC_VALUE = LW_PB_PC_ADDRESS[8:2];   // 0x11
    localparam SW_LED_PC_VALUE = SW_SEVENSEG_PC_ADDRESS[8:2]; // 0x49
    localparam SW_LEDOUT_LED_PC_VALUE = SW_LEDOUT_PC_ADDRESS[8:2]; // 0x4A
    
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
    reg [1:0] sampled_led_out;
    reg [1:0] expected_led_out;
    reg [1:0] actual_led_out;
    reg [2:0] sampled_pb;
    reg [4:0] sampled_sevenseg;
    reg [4:0] expected_sevenseg;
    reg [4:0] actual_sevenseg;
    reg sample_valid;
    reg check_pending;
    reg led_sample_valid;
    reg led_check_pending;
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Instantiate UUT
    Wrapper dut(DIP, PB, LED_OUT, LED_PC, SEVENSEGHEX, UART_TX, UART_TX_ready, UART_TX_valid, UART_RX, UART_RX_valid, UART_RX_ack, OLED_Write, OLED_Col, OLED_Row, OLED_Data, ACCEL_Data, ACCEL_DReady, RESET, CLK);
    
    // Self-checking monitor - runs on positive clock edge
    always @(posedge CLK) begin
        if (RESET) begin
            // Reset all monitoring variables
            sampled_pb <= 3'b000;
            sampled_sevenseg <= 5'b00000;
            expected_sevenseg <= 5'b00000;
            sampled_led_out <= 2'b00;
            expected_led_out <= 2'b00;
            sample_valid <= 1'b0;
            check_pending <= 1'b0;
            led_sample_valid <= 1'b0;
            led_check_pending <= 1'b0;
            test_count <= 0;
            pass_count <= 0;
            fail_count <= 0;
        end else begin
            
            // Sample PB and SEVENSEGHEX and LED_OUT when LED_PC transitions from 0x11 to 0x12
            if (LED_PC == LW_LED_PC_VALUE) begin
                sampled_pb <= PB;
                sampled_sevenseg <= SEVENSEGHEX[15:11];
                sampled_led_out <= LED_OUT[1:0];
                if (PB[1] == 1) begin
                    led_sample_valid <= 1'b1;
                end
                if (PB[2] == 1 || PB[0] == 1) begin
                    sample_valid <= 1'b1;
                end
                check_pending <= 1'b0;  // Clear any pending check
                led_check_pending <= 1'b0;
                $display("[%0t] SAMPLE: LED_PC 0x%02X, PB=3'b%03b, SEVENSEG[15:11]=5'b%05b, LED_OUT[1:0]=2'b%02b",
                         $time, LED_PC, PB, SEVENSEGHEX[15:11], LED_OUT[1:0]);
            end
            
            // Check behavior when LED_PC transitions from 0x49 to 0x4A
            if ((LED_PC == (SW_LED_PC_VALUE + 1)) && sample_valid) begin
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

            if ((LED_PC == (SW_LEDOUT_LED_PC_VALUE + 1)) && led_sample_valid) begin
                actual_led_out <= LED_OUT[1:0];
                led_check_pending <= 1'b1;
                if (sampled_led_out == 2'b10) begin
                    expected_led_out <= 2'b00;
                end else begin
                    expected_led_out <= sampled_led_out + 1;
                end
            end
    

            
            // Perform the check one cycle after setting check_pending
            if (check_pending) begin
                test_count <= test_count + 1;
                
                if (SEVENSEGHEX[15:11] == expected_sevenseg) begin
                    pass_count <= pass_count + 1;
                    $display("[%0t] PASS #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LED_PC_VALUE, SW_LED_PC_VALUE + 1, sampled_pb);
                    $display("         Expected SEVENSEG[15:11]=5'b%05b, Actual=5'b%05b", 
                             expected_sevenseg, SEVENSEGHEX[15:11]);
                end else begin
                    fail_count <= fail_count + 1;
                    $display("[%0t] FAIL #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LED_PC_VALUE, SW_LED_PC_VALUE + 1, sampled_pb);
                    $display("         Expected SEVENSEG[15:11]=5'b%05b, Actual=5'b%05b", 
                             expected_sevenseg, SEVENSEGHEX[15:11]);
                end
                
                check_pending <= 1'b0;
                sample_valid <= 1'b0;  // Clear sample for next iteration
            end

            if (led_check_pending) begin 
                test_count <= test_count + 1;
                
                if (actual_led_out == expected_led_out) begin
                    pass_count <= pass_count + 1;
                    $display("[%0t] PASS #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LEDOUT_LED_PC_VALUE, SW_LEDOUT_LED_PC_VALUE + 1, sampled_pb);
                    $display("         Expected LED_OUT[1:0]=2'b%02b, Actual=2'b%02b", 
                             expected_led_out, actual_led_out);
                end else begin
                    fail_count <= fail_count + 1;
                    $display("[%0t] FAIL #%0d: LED_PC 0x%02X->0x%02X, PB=3'b%03b", 
                             $time, test_count + 1, SW_LEDOUT_LED_PC_VALUE, SW_LEDOUT_LED_PC_VALUE + 1, sampled_pb);
                    $display("         Expected  LED_OUT[1:0]=2'b%02b, Actual=2'b%02b", 
                             expected_led_out, actual_led_out);
                end
                
                led_check_pending <= 1'b0;
                led_sample_valid <= 1'b0;  // Clear sample for next iteration
            end
        end
    end
    
    /*
    // Monitor PC transitions for debugging
	reg [6:0] prev_led_pc = 7'h00;
	always @(posedge CLK) begin
		if (!RESET) begin
			if (LED_PC != prev_led_pc) begin
				$display("[%0t] DEBUG: PC transition from 0x%02X to 0x%02X", 
					$time, prev_led_pc, LED_PC);
			end
			prev_led_pc <= LED_PC;
		end
	end
	*/
    
    // Test summary at end of simulation
    initial begin
        RESET = 1; #10; RESET = 0; //hold reset state for 10 ns.
        $display("[%0t] Starting self-checking testbench", $time);
        
        PB = 3'b010; // Toggle colour
        #1000000;  // Wait for simulation to complete
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
        
    // GENERATE CLOCK       
    always          
    begin
       #5 CLK = ~CLK ; // invert clk every 5 time units 
    end
    
endmodule