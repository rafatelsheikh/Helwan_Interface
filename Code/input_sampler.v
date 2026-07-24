module input_sampler #(
    parameter DATA_WIDTH = 16,
    parameter PARTIAL_SIZE = 4,
    parameter NUMBER_OF_PARTIALS_PER_OUTPUT = 2,
    parameter DATA_IN_SIZE = DATA_WIDTH * PARTIAL_SIZE,
    parameter DATA_OUT_SIZE = DATA_WIDTH * NUMBER_OF_PARTIALS_PER_OUTPUT
)(
    input clk,
    input rst_n,
    input sample_data,
    input [DATA_IN_SIZE-1:0] data_in,
    output [DATA_OUT_SIZE-1:0] data_out,
    output valid_out
);

    // local prameter for the counter size
    localparam COUNTER_SIZE = $clog2(NUMBER_OF_PARTIALS_PER_OUTPUT);

    // using generate to cover the case where NUMBER_OF_PARTIALS_PER_OUTPUT = 1 
    generate
        // reg to save partials
        if (NUMBER_OF_PARTIALS_PER_OUTPUT > 1) begin
            reg [0:NUMBER_OF_PARTIALS_PER_OUTPUT-2] [DATA_IN_SIZE-1:0] saved_partials;
            
            // counter for the number of partials already saved
            reg [COUNTER_SIZE:0] partials_count;

            // saving in reg
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    saved_partials <= 0;
                end else if (sample_data) begin
                    if (partials_count < NUMBER_OF_PARTIALS_PER_OUTPUT - 1) begin
                        saved_partials[partials_count] <= data_in;
                    end        
                end
            end

            // updating counter
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    partials_count <= 0;
                end else if (sample_data) begin
                    if (partials_count < NUMBER_OF_PARTIALS_PER_OUTPUT - 1) begin
                        partials_count <= partials_count + 1;
                    end else if (partials_count == NUMBER_OF_PARTIALS_PER_OUTPUT - 1) begin
                        partials_count <= 0;
                    end
                end
            end

            // output logic
            assign data_out = (sample_data && (partials_count == NUMBER_OF_PARTIALS_PER_OUTPUT - 1))? {saved_partials, data_in} : 0;
            assign valid_out = sample_data && (partials_count == NUMBER_OF_PARTIALS_PER_OUTPUT - 1);
        end else begin
            assign data_out = (sample_data)? data_in : 0;
            assign valid_out = sample_data;
        end
    endgenerate


endmodule