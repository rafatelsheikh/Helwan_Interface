`timescale 1ns / 1ps

module tb_generate_adders;

    // Parameters matching the DUT defaults
    parameter DATA_WIDTH       = 16;
    parameter OUTPUT_SIZE      = 8;
    parameter OUTPUT_BUS_WIDTH = OUTPUT_SIZE * DATA_WIDTH;

    // Testbench signals
    reg  [OUTPUT_BUS_WIDTH-1:0] operand_a;
    reg  [OUTPUT_BUS_WIDTH-1:0] operand_b;
    wire [OUTPUT_BUS_WIDTH-1:0] data_out;

    // Instantiate the Design Under Test (DUT)
    generate_adders #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUTPUT_SIZE(OUTPUT_SIZE),
        .OUTPUT_BUS_WIDTH(OUTPUT_BUS_WIDTH)
    ) dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .data_out(data_out)
    );

    integer k;
    // Test stimulus
    initial begin
        // Display header
        $display("---------------------------------------------------------");
        $display("Starting generate_adders Testbench");
        $display("---------------------------------------------------------");

        // Initialize inputs
        operand_a = 0;
        operand_b = 0;
        #10;

        // Test Case 1: Simple values across all adders
        // Sets each 16-bit word in operand_a to 10, and operand_b to 20
        operand_a = {8{16'h000A}}; // 10 in hex
        operand_b = {8{16'h0014}}; // 20 in hex
        #10;
        $display("[Test 1] A = 10, B = 20 | Out Word 0 = %0d (Expected: 30)", data_out[15:0]);

        // Test Case 2: Different values for each index
        // Packer simulation for unique values per adder
        operand_a = {16'd80, 16'd70, 16'd60, 16'd50, 16'd40, 16'd30, 16'd20, 16'd10};
        operand_b = {16'd8,  16'd7,  16'd6,  16'd5,  16'd4,  16'd3,  16'd2,  16'd1};
        #10;

        // Display results for all 8 adders
        $display("\n[Test 2] Vector addition check:");
        for (k = 0; k < OUTPUT_SIZE; k = k + 1) begin
            $display("  Adder %0d: %0d + %0d = %0d", 
                     k, 
                     operand_a[k*DATA_WIDTH +: DATA_WIDTH], 
                     operand_b[k*DATA_WIDTH +: DATA_WIDTH], 
                     data_out[k*DATA_WIDTH  +: DATA_WIDTH]);
        end

        // Finish simulation
        $display("---------------------------------------------------------");
        $display("Simulation Complete!");
        $display("---------------------------------------------------------");
        $finish;
    end

endmodule