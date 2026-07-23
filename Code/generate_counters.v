module counter_array #(
    parameter NUM_COUNTERS = 4,
    parameter MAX_COUNT    = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [NUM_COUNTERS-1:0] keep_count,  // one keep_count per counter
    output wire [NUM_COUNTERS-1:0] done         // one done per counter
);

    genvar i;
    generate
        for (i = 0; i < NUM_COUNTERS; i = i + 1) begin : gen_counter
            param_counter #(
                .MAX_COUNT (MAX_COUNT)
            ) u_counter (
                .clk        (clk),
                .rst_n      (rst_n),
                .keep_count (keep_count[i]),
                .done       (done[i])
            );
        end
    endgenerate

endmodule