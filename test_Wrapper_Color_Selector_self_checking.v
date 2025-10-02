`timescale 1ns / 1ps
module test_Wrapper #(
    parameter N_LEDs_OUT = 8,
    parameter N_DIPs     = 16,
    parameter N_PBs      = 3,
    /*parameter LW_PB_PC_ADDRESS      = 9'h044,  // bits[8:2] = 0x11
    parameter SW_SEVENSEG_PC_ADDRESS = 9'h124,  // bits[8:2] = 0x49
    parameter SW_LEDOUT_PC_ADDRESS  = 9'h128,   // bits[8:2] = 0x4A
    parameter WAIT_PC_ADDRESS       = 9'h140*/
//    parameter LW_PB_PC_ADDRESS      = 9'h050,  // bits[8:2] = 0x11
//    parameter SW_SEVENSEG_PC_ADDRESS = 9'h130,  // bits[8:2] = 0x49
//    parameter SW_LEDOUT_PC_ADDRESS  = 9'h134,   // bits[8:2] = 0x4A
//    parameter WAIT_PC_ADDRESS       = 9'h14c
    parameter LW_PB_PC_ADDRESS       = 9'h060,  // lw s4, (s6)
    parameter SW_SEVENSEG_PC_ADDRESS = 9'h134,  // sw s11, (s5)
    parameter SW_LEDOUT_PC_ADDRESS   = 9'h138,  // sw s10, (s1)
    parameter WAIT_PC_ADDRESS        = 9'h150   // wait loop
)
();

    // Derived LED_PC values
    localparam LW_LED_PC_VALUE         = LW_PB_PC_ADDRESS[8:2];      // 0x11
    localparam SW_LED_PC_VALUE         = SW_SEVENSEG_PC_ADDRESS[8:2]; // 0x49
    localparam SW_LEDOUT_LED_PC_VALUE  = SW_LEDOUT_PC_ADDRESS[8:2];   // 0x4A
    localparam WAIT_PC_VALUE = WAIT_PC_ADDRESS[8:2];

    // Signals
    reg  [N_DIPs-1:0] DIP = 0;
    reg  [N_PBs-1:0]  PB  = 0;
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
    reg RESET = 0;
    reg CLK = 0;

    // Self-checking variables
    reg [4:0] sampled_red, expected_red, actual_red;
    reg [5:0] sampled_green, expected_green, actual_green;
    reg [4:0] sampled_blue, expected_blue, actual_blue;
    reg [1:0] sampled_led_out, expected_led_out, actual_led_out;

    reg [1:0] color_selected; // 0=Red, 1=Green, 2=Blue

    reg sample_valid, led_sample_valid, no_action_sample_valid;
    reg check_pending, led_check_pending;
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Instantiate the DUT
    Wrapper dut(
        DIP, PB, LED_OUT, LED_PC, SEVENSEGHEX,
        UART_TX, UART_TX_ready, UART_TX_valid,
        UART_RX, UART_RX_valid, UART_RX_ack,
        OLED_Write, OLED_Col, OLED_Row, OLED_Data,
        ACCEL_Data, ACCEL_DReady,
        RESET, CLK
    );

    // Clock generation
    always #5 CLK = ~CLK;

    // Self-checking monitor
    always @(posedge CLK) begin
        if (RESET) begin
            sampled_red <= 0; expected_red <= 0; actual_red <= 0;
            sampled_green <= 0; expected_green <= 0; actual_green <= 0;
            sampled_blue <= 0; expected_blue <= 0; actual_blue <= 0;
            sampled_led_out <= 0; expected_led_out <= 0; actual_led_out <= 0;
            color_selected <= 0;
            sample_valid <= 0; led_sample_valid <= 0; no_action_sample_valid <= 0;
            check_pending <= 0; led_check_pending <= 0;
            test_count <= 0; pass_count <= 0; fail_count <= 0;
        end else begin
            // SAMPLE at LW_LED_PC_VALUEc
            if (LED_PC == LW_LED_PC_VALUE) begin
                sampled_red   <= SEVENSEGHEX[15:11];
                sampled_green <= SEVENSEGHEX[10:5];
                sampled_blue  <= SEVENSEGHEX[4:0];
                sampled_led_out <= LED_OUT[1:0];

                // Determine sample validity
                if ((PB == 3'b100) || (PB == 3'b001)) begin
                    sample_valid <= 1'b1;
                    led_sample_valid <= 1'b0;
                    no_action_sample_valid <= 1'b0;
                end 
                else if (PB == 3'b010) begin
                    led_sample_valid <= 1'b1;
                    color_selected <= (color_selected + 1) % 3;
                    sample_valid <= 1'b0;
                    no_action_sample_valid <= 1'b0;
                end
                else begin 
                    no_action_sample_valid <= 1'b1;
                    sample_valid <= 1'b0;
                    led_sample_valid <= 1'b0;
                end 

                $display("[%0t] SAMPLE: LED_PC=0x%02X, PB=3'b%03b, color_selected=%0d, SEVENSEG R=5'b%05b G=6'b%06b B=5'b%05b, LED_OUT=2'b%02b",
                         $time, LED_PC, PB, color_selected, SEVENSEGHEX[15:11], SEVENSEGHEX[10:5], SEVENSEGHEX[4:0], LED_OUT[1:0]);
            end

            // SEVENSEG check
            if ((LED_PC == SW_LED_PC_VALUE + 1) && sample_valid) begin
                actual_red   <= SEVENSEGHEX[15:11];
                actual_green <= SEVENSEGHEX[10:5];
                actual_blue  <= SEVENSEGHEX[4:0];
                check_pending <= 1'b1;

                // Compute expected values only for selected color
                expected_red   <= (color_selected==0 && PB==3'b100 && sampled_red!=5'b11111)   ? sampled_red + 1 :
                                  (color_selected==0 && PB==3'b001 && sampled_red!=5'b00000)   ? sampled_red - 1 :
                                  sampled_red;
                expected_green <= (color_selected==1 && PB==3'b100 && sampled_green!=6'b111111) ? sampled_green + 1 :
                                  (color_selected==1 && PB==3'b001 && sampled_green!=6'b000000) ? sampled_green - 1 :
                                  sampled_green;
                expected_blue  <= (color_selected==2 && PB==3'b100 && sampled_blue!=5'b11111)  ? sampled_blue + 1 :
                                  (color_selected==2 && PB==3'b001 && sampled_blue!=5'b00000)  ? sampled_blue - 1 :
                                  sampled_blue;
            end

            // LED_OUT check
            if ((LED_PC == SW_LEDOUT_LED_PC_VALUE + 1) && led_sample_valid) begin
                actual_led_out <= LED_OUT[1:0];
                led_check_pending <= 1'b1;
                expected_led_out <= (sampled_led_out == 2'b10) ? 2'b00 : sampled_led_out + 1;
            end

            if ((LED_PC == WAIT_PC_VALUE) && no_action_sample_valid) begin
                test_count <= test_count + 1;
                $display("[%0t] TEST #%0d: PB=3'b%03b, SEVENSEG expected R=5'b%05b G=6'b%06b B=5'b%05b LED_OUT=2'b%02b, actual R=5'b%05b G=6'b%06b B=5'b%05b LED_OUT=2'b%02b",
                         $time, test_count, PB, sampled_red, sampled_green, sampled_blue, sampled_led_out, SEVENSEGHEX[15:11], SEVENSEGHEX[10:5], SEVENSEGHEX[4:0], LED_OUT[1:0]);

                if (SEVENSEGHEX[15:11] == sampled_red && SEVENSEGHEX[10:5] == sampled_green && SEVENSEGHEX[4:0] == sampled_blue && sampled_led_out == LED_OUT[1:0]) begin
                    pass_count <= pass_count + 1;
                    $display("         PASS");
                end else begin
                    fail_count <= fail_count + 1;
                    $display("         FAIL");
                end
                no_action_sample_valid <= 0;
            end

            // Perform SEVENSEG check
            if (check_pending) begin
                test_count <= test_count + 1;
                $display("[%0t] TEST #%0d: PB=3'b%03b, SEVENSEG expected R=5'b%05b G=6'b%06b B=5'b%05b, actual R=5'b%05b G=6'b%06b B=5'b%05b",
                         $time, test_count, PB, expected_red, expected_green, expected_blue, actual_red, actual_green, actual_blue);

                if (actual_red == expected_red && actual_green == expected_green && actual_blue == expected_blue) begin
                    pass_count <= pass_count + 1;
                    $display("         PASS");
                end else begin
                    fail_count <= fail_count + 1;
                    $display("         FAIL");
                end
                check_pending <= 0;
                sample_valid <= 0;
            end

            // Perform LED_OUT check
            if (led_check_pending) begin
                test_count <= test_count + 1;
                $display("[%0t] TEST #%0d: PB=3'b%03b, LED_OUT expected=2'b%02b, actual=2'b%02b",
                         $time, test_count, PB, expected_led_out, actual_led_out);

                if (actual_led_out == expected_led_out) begin
                    pass_count <= pass_count + 1;
                    $display("         PASS");
                end else begin
                    fail_count <= fail_count + 1;
                    $display("         FAIL");
                end
                led_check_pending <= 0;
                led_sample_valid <= 0;
            end
        end
    end

    // Synchronized PB sequence
    reg [2:0] pb_sequence [0:2];
    integer pb_index;
    initial begin
        pb_sequence[0] = 3'b010; // toggle color
        pb_sequence[1] = 3'b100; // increment selected
        pb_sequence[2] = 3'b001; // decrement selected
        pb_index = 0;

        RESET = 1; #10; RESET = 0;
        $display("[%0t] Starting synchronized PB sequence", $time);
        // Test for all buttons pressed
        PB = 3'b111;
        wait(no_action_sample_valid==1);
            // wait until test is done
        wait(no_action_sample_valid==0);
        
        PB = 3'b010;
        wait((check_pending==1) || (led_check_pending==1));
            // wait until test is done
        wait((check_pending==0) && (led_check_pending==0));
        PB = 3'b100;
        #16_000_000;
        PB = 3'b001;
        #16_000_000;
        
        PB = 3'b010;
        wait((check_pending==1) || (led_check_pending==1));
            // wait until test is done
        wait((check_pending==0) && (led_check_pending==0));
        PB = 3'b100;
        #8_000_000;
        PB = 3'b001;
        #8_000_000;
        
        PB = 3'b010;
        wait((check_pending==1) || (led_check_pending==1));
            // wait until test is done
        wait((check_pending==0) && (led_check_pending==0)); 
        PB = 3'b100;
        #8_000_000;
        PB = 3'b001;
        #8_000_000;
        /*
        forever begin
            PB = pb_sequence[pb_index];
            // wait until DUT sets check_pending or led_check_pending
            wait((check_pending==1) || (led_check_pending==1));
            // wait until test is done
            wait((check_pending==0) && (led_check_pending==0));
            PB = 3'b000;  // release button
            #10_000;      // short delay to avoid glitches
            pb_index = (pb_index + 1) % 3; // next PB
        end*/
    end

    // End simulation
    initial begin
        #65_000_000; // 65 ms simulation
        $display("\n==================== TEST SUMMARY ====================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (fail_count == 0 && test_count > 0)
            $display("Result:      ALL TESTS PASSED!");
        else if (test_count == 0)
            $display("Result:      NO TESTS EXECUTED");
        else
            $display("Result:      SOME TESTS FAILED");
        $display("=====================================================\n");
        $finish;
    end

endmodule
