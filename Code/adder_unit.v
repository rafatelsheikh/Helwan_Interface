module adder_unit #(
    parameter DATA_WIDTH = 16  // Bit width of operands and output
)(
    input  wire [DATA_WIDTH-1:0] operand_a,
    input  wire [DATA_WIDTH-1:0] operand_b,
    output wire [DATA_WIDTH-1:0] sum
);
    assign sum = operand_a + operand_b;
endmodule