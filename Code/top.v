module top #(
    parameter DATA_WIDTH             = 16,  // Width in bits of a single data element
    parameter PARTIAL_SIZE           = 4,   // Number of data elements per Partial Transaction
    parameter OUTPUT_SIZE            = 8,   // Number of data elements per Output Word
    parameter MAX_SEGMENTS_PER_RANGE = 100,  // Max processing segments per range
    parameter ADDR_WIDTH             = $clog2(MAX_SEGMENTS_PER_RANGE * PARTIAL_SIZE**2 / OUTPUT_SIZE)   // Width of logical output-address values
)(
    input  wire                                clk,   
    input  wire                                rst_n,           // Asynchronous active-low reset

    // Upstream Interface
    input  wire                                 partial_valid,   // Valid Partial Transaction flag
    input  wire [(PARTIAL_SIZE*DATA_WIDTH)-1:0] partial_data,   // Partial Transaction bus
    input  wire                                 segment_step,    // Advance to next segment in range
    input  wire                                 phase_change,    // Transition between processing phases
    input  wire                                 next_range,      // Transition to new processing range
    input  wire                                 operation_done,  // Final Partial Transaction of operation

    // Downstream Interface 
    input  wire [ADDR_WIDTH-1:0]               output_addr,     // Logical address requested by downstream
    output reg                                 output_valid,    // indicate if Output data is available
    output reg  [(OUTPUT_SIZE*DATA_WIDTH)-1:0] output_data      // Output Word bus
);

    localparam PARTIALS_PER_OUTPUT = OUTPUT_SIZE / PARTIAL_SIZE;
    localparam OUTPUTS_PER_SEGMENT = PARTIAL_SIZE / PARTIALS_PER_OUTPUT; 

    // Bus Widths in Bits
    localparam INPUT_BUS_WIDTH   = PARTIAL_SIZE * DATA_WIDTH;
    localparam OUTPUT_BUS_WIDTH    = OUTPUT_SIZE * DATA_WIDTH;

    // RAM configuration 
    localparam MIN_BUFFER_CAPACITY = MAX_SEGMENTS_PER_RANGE * OUTPUTS_PER_SEGMENT;
    localparam BUFFER_SIZE = 5 * MIN_BUFFER_CAPACITY; // this constant indicate how may ranges of max size can the ram hold
    localparam PHY_ADDRESS_WIDTH = $clog2(BUFFER_SIZE);
    localparam MEM_SIZE = PHY_ADDRESS_WIDTH**2;

    // number of clocks to process a segment
    localparam T_SEGMENT               = PARTIAL_SIZE; // *********************** TO BE MODIFIED
    localparam T_RANGE_FILL_MAX        = MAX_SEGMENTS_PER_RANGE * T_SEGMENT; 

    // MAX delay of the downstream side to request the data range.
    localparam MAX_DOWNSTREAM_DELAY    = 3 * T_RANGE_FILL_MAX; 

    // Latency of producing valid data after operation_done is asserted
    localparam MAX_COMPLETION_LATENCY  = T_SEGMENT;

    // Internal Signals
    reg [PHY_ADDRESS_WIDTH-1:0] out_read_address;
    reg alu_read_en;
    reg [PHY_ADDRESS_WIDTH-1:0] alu_read_address;
    reg sample_data;
    reg sampled_data_valid;
    reg [OUTPUT_BUS_WIDTH-1:0] sampled_data;
    reg [OUTPUT_BUS_WIDTH-1:0] alu_operand_a;
    reg [OUTPUT_BUS_WIDTH-1:0] alu_result;
    reg initial_partial_end;
    reg accumulated_partial_end;
    reg direction_change;
    reg [OUTPUT_BUS_WIDTH-1:0] mem_data_in;

    // reg variables
    reg alu_read_en_reg;
    reg initial_partial_end_reg;
    reg accumulated_partial_end_reg;
    reg direction_change_reg;
    reg [ADDR_WIDTH-1:0] output_addr_reg;

    // Instantiate RAM
    RAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUTPUT_SIZE(OUTPUT_SIZE),
        .MEM_SIZE(MEM_SIZE),
        .ADDR_SIZE(PHY_ADDRESS_WIDTH)
    ) my_ram (
        .clk(clk),
        .out_read_en(output_valid),
        .out_read_address(out_read_address),
        .alu_read_en(alu_read_en_reg),
        .alu_read_address(alu_read_address),
        .write_en(sampled_data_valid_reg),
        .write_address(alu_read_address),
        .data_in(mem_data_in),
        .out_read_data(output_data),
        .alu_read_data(alu_operand_a)
    );

    // Instantiate ALU
    generate_adders #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUTPUT_SIZE(OUTPUT_SIZE),
        .OUTPUT_BUS_WIDTH(OUTPUT_BUS_WIDTH)
    ) my_alu (
        .operand_a(alu_operand_a),
        .operand_b(sampled_data_reg),
        .data_out(alu_result)
    );

    // Instantiate Input Sampler
    input_sampler #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARTIAL_SIZE(PARTIAL_SIZE),
        .NUMBER_OF_PARTIALS_PER_OUTPUT(PARTIALS_PER_OUTPUT)
    ) my_input_sampler (
        .clk(clk),
        .rst_n(rst_n),
        .sample_data(sample_data),
        .data_in(partial_data),
        .data_out(sampled_data),
        .valid_out(sampled_data_valid)
    );

    // Instantiate Control Unit
    cu #(
        .PARTIAL_SIZE(PARTIAL_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_OF_PARTIALS_PER_OUTPUT(PARTIALS_PER_OUTPUT)
    ) my_cu (
        .clk(clk),
        .rst_n(rst_n),
        .partial_valid(partial_valid),
        .segment_step(segment_step),
        .phase_change(phase_change),
        .next_range(next_range),
        .operation_done(operation_done),
        .sample_data(sample_data),
        .alu_read_en(alu_read_en_reg),
        .initial_partial_end(initial_partial_end),
        .accumulated_partial_end(accumulated_partial_end),
        .direction_change(direction_change)
    );

    // Instantiate Memory Interpreter
    mem_arbiter #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_SIZE(MEM_SIZE),
        .ADDR_SIZE(PHY_ADDRESS_WIDTH),
        .RANGES_NUMBER(2)
    ) my_mem_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .end_range(initial_partial_end_reg),
        .accumulated_processing_end(accumulated_partial_end_reg),
        .address_in(output_addr_reg),
        .change_direction(direction_change_reg),
        .en(sampled_data_valid),
        .alu_address_out(alu_read_address),
        .out_address_out(out_read_address),
        .output_valid(output_valid)
    );

    mux #(
        .DATA_WIDTH(OUTPUT_BUS_WIDTH)
    ) my_mux (
        .sel(alu_read_en_reg),
        .in_a(alu_result),
        .in_b(sampled_data),
        .out(mem_data_in)
    );

    pipeline_reg #(
        .ADDR_WIDTH(ADDR_WIDTH)

    ) my_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .alu_read_en(alu_read_en),
        .initial_partial_end(initial_partial_end),
        .accumulated_partial_end(accumulated_partial_end),
        .direction_change(direction_change),
        .output_addr(output_addr),
        .alu_read_en_reg(alu_read_en_reg),
        .initial_partial_end_reg(initial_partial_end_reg),
        .accumulated_partial_end_reg(accumulated_partial_end_reg),
        .direction_change_reg(direction_change_reg),
        .output_addr_reg(output_addr_reg)
    );

endmodule
