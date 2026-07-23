module param_counter #(
    parameter MAX_COUNT = 10
)(
    input  wire clk,
    input  wire rst_n,        // active-low async reset
    input  wire keep_count,   // pulse to begin counting
    output reg  done          // now stays high for 2 cycles when MAX_COUNT reached
);

    localparam WIDTH = $clog2(MAX_COUNT+1);
    reg [WIDTH-1:0] count;
    reg done_d;   // delayed copy of done

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count  <= 0;
            done   <= 1'b0;
            done_d <= 1'b0;
        end
        else begin
            done_d <= done;      // remember last cycle's done
            done   <= done_d;    

            if (keep_count) begin
                count <= count + 1;
                if (count == MAX_COUNT - 1) begin
                    count <= 0;
                    done  <= 1'b1;
                end
            end
            else begin
                count <= 0;
            end
        end
    end
endmodule