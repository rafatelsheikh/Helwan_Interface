module RAM #(
    parameter DATA_WIDTH = 16,
    parameter OUTPUT_SIZE = 8,
    parameter MEM_SIZE = 1024,
    parameter ADDR_SIZE = 10,
    parameter DATA_SIZE = DATA_WIDTH * OUTPUT_SIZE
)(
    input clk,
    input out_read_en,
    input [ADDR_SIZE-1:0] out_read_address,
    input alu_read_en,
    input [ADDR_SIZE-1:0] alu_read_address,
    input write_en,
    input [ADDR_SIZE-1:0] write_address,
    input [DATA_SIZE-1:0] data_in,
    output reg [DATA_SIZE-1:0] out_read_data,
    output reg [DATA_SIZE-1:0] alu_read_data
);

    // memory array
    reg [DATA_SIZE-1:0] memory [0:MEM_SIZE-1];

    // write operation
    always @(posedge clk) begin
        if (write_en) begin
            memory[write_address] <= data_in;
        end
    end

    // read operation for output
    always @(*) begin
        if (out_read_en) begin
            out_read_data = memory[out_read_address];
        end else begin
            out_read_data = {DATA_SIZE{1'b0}}; 
        end
    end

    // read operation for alu
    always @(*) begin
        if (alu_read_en) begin
            alu_read_data = memory[alu_read_address];
        end else begin
            alu_read_data = {DATA_SIZE{1'b0}};
        end
    end
endmodule
