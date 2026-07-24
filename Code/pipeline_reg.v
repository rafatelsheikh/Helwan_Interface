module pipeline_reg #(
    parameter ADDR_WIDTH = 8
)(
    input clk,
    input rst_n,
    input alu_read_en,
    input initial_partial_end,
    input accumulated_partial_end,
    input direction_change,
    input [ADDR_WIDTH-1:0] output_addr,
    output reg alu_read_en_reg,
    output reg initial_partial_end_reg,
    output reg accumulated_partial_end_reg,
    output reg direction_change_reg,
    output reg [ADDR_WIDTH-1:0] output_addr_reg
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_read_en_reg <= 0;
            initial_partial_end_reg <= 0;
            accumulated_partial_end_reg <= 0;
            direction_change_reg <= 0;
            output_addr_reg <= 0;
        end else begin
            alu_read_en_reg <= alu_read_en;
            initial_partial_end_reg <= initial_partial_end;
            accumulated_partial_end_reg <= accumulated_partial_end;
            direction_change_reg <= direction_change;
            output_addr_reg <= output_addr;
        end
    end

endmodule