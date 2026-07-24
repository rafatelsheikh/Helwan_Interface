module input_sampler #(
    parameter DATA_WIDTH = 16,
    parameter PARTIAL_SIZE = 4,
    parameter NUMBER_OF_PARTIALS_PER_OUTPUT = 2,
    parameter DATA_IN_SIZE = DATA_WIDTH * PARTIAL_SIZE,
    parameter DATA_OUT_SIZE = DATA_WIDTH * NUMBER_OF_PARTIALS_PER_OUTPUT * PARTIAL_SIZE
)(
    input clk,
    input rst_n,
    input sample_data,
    input [DATA_IN_SIZE-1:0] data_in,
    output reg [DATA_OUT_SIZE-1:0] data_out,
    output reg valid_out
);

    // local prameter for the counter size
    localparam COUNTER_SIZE = $clog2(NUMBER_OF_PARTIALS_PER_OUTPUT);

    // reg for saving the partials
    reg [0:NUMBER_OF_PARTIALS_PER_OUTPUT-1] [DATA_IN_SIZE-1:0] saved_partials;


    // counter to count saved partials
    reg [COUNTER_SIZE-1:0] partials_count;

    // variable to indicate that data is sampled
    reg data_sampled;

    // saving in reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            saved_partials <= 0;
        end else if (sample_data) begin
            if (partials_count < NUMBER_OF_PARTIALS_PER_OUTPUT) begin
                saved_partials[partials_count] <= data_in;
            end        
        end
    end

    // updating counter and saving in reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partials_count <= 0;
        end else if (sample_data) begin
            if (partials_count < NUMBER_OF_PARTIALS_PER_OUTPUT) begin
                if (partials_count == NUMBER_OF_PARTIALS_PER_OUTPUT - 1) begin
                    partials_count <= 0;
                end else begin
                    partials_count <= partials_count + 1;
                end
            end
        end
    end

    // data_sampled logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_sampled <= 0;
        end else if (sample_data && (partials_count == NUMBER_OF_PARTIALS_PER_OUTPUT - 1)) begin
            data_sampled <= 1;
        end else begin
            data_sampled <= 0;
        end
    end

    // updating output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            data_out <= 0;
        end else if (data_sampled) begin
            valid_out <= 1;
            data_out <= saved_partials;
        end else begin
            valid_out <= 0;
            data_out <= 0;
        end
    end

endmodule
