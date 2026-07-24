module generate_adders #(
    parameter DATA_WIDTH = 16,
    parameter OUTPUT_SIZE = 8,
    parameter OUTPUT_BUS_WIDTH = 8 * 16
) (
    input wire [OUTPUT_BUS_WIDTH-1:0] operand_a,
    input wire [OUTPUT_BUS_WIDTH-1:0] operand_b,

    output wire [OUTPUT_BUS_WIDTH-1:0] data_out
);
genvar i;
generate
    for (i = 0; i < OUTPUT_SIZE; i = i + 1) begin : gen_adders
        adder_unit #(
            .DATA_WIDTH (DATA_WIDTH)            // Bit width of operands and sum output
        ) u_adder_unit (
            .operand_a (operand_a[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),        // Input: [DATA_WIDTH-1:0] Operand A
            .operand_b (operand_b[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),        // Input: [DATA_WIDTH-1:0] Operand B
            .sum       (data_out[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH])      // Output: [DATA_WIDTH-1:0] Result sum
        );
    end
endgenerate
    
endmodule
    
