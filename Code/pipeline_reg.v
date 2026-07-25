module pipeline_reg (
    input clk,
    input rst_n,
    input alu_read_en,
    input initial_partial_end,
    input accumulated_partial_end,
    input direction_change,
    output reg alu_read_en_reg,
    output reg initial_partial_end_reg,
    output reg accumulated_partial_end_reg,
    output reg direction_change_reg
);

    reg alu_read_en_reg0;
    reg initial_partial_end_reg0;
    reg accumulated_partial_end_reg0;
    reg direction_change_reg0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_read_en_reg0 <= 0;
            initial_partial_end_reg0 <= 0;
            accumulated_partial_end_reg0 <= 0;
            direction_change_reg0 <= 0;
        end else begin
            alu_read_en_reg0 <= alu_read_en;
            initial_partial_end_reg0 <= initial_partial_end;
            accumulated_partial_end_reg0 <= accumulated_partial_end;
            direction_change_reg0 <= direction_change;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_read_en_reg <= 0;
            initial_partial_end_reg <= 0;
            accumulated_partial_end_reg <= 0;
            direction_change_reg <= 0;
        end else begin
            alu_read_en_reg <= alu_read_en_reg0;
            initial_partial_end_reg <= initial_partial_end_reg0;
            accumulated_partial_end_reg <= accumulated_partial_end_reg0;
            direction_change_reg <= direction_change_reg0;
        end
    end

endmodule
