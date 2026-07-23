module mux #(
    DATA_WIDTH = 8;
)(
    input sel,
    input [DATA_WIDTH-1:0] in_a,
    input [DATA_WIDTH-1:0] in_b,
    output reg [DATA_WIDTH-1:0] out
);

    always @(*) begin
        if (sel) begin
            out = in_a;
        end else begin
            out = in_b;
        end
    end
endmodule