module top #(
    parameter DATA_WIDTH             = 16,  // Width in bits of a single data element
    parameter PARTIAL_SIZE           = 4,   // Number of data elements per Partial Transaction
    parameter OUTPUT_SIZE            = 8,   // Number of data elements per Output Word
    parameter MAX_SEGMENTS_PER_RANGE = 100  // Max processing segments per range
    parameter ADDR_WIDTH             = $clog2(MAX_SEGMENTS_PER_RANGE * PARTIAL_SIZE**2 / OUTPUT_SIZE),   // Width of logical output-address values
)(
    input  wire                                clk,   
    input  wire                                rst_n,           // Asynchronous active-low reset

    // Upstream Interface
    input  wire                                partial_valid,   // Valid Partial Transaction flag
    input  wire [(PARTIAL_SIZE*DATA_WIDTH)-1:0] partial_data,   // Partial Transaction bus
    input  wire                                segment_step,    // Advance to next segment in range
    input  wire                                phase_change,    // Transition between processing phases
    input  wire                                next_range,      // Transition to new processing range
    input  wire                                operation_done,  // Final Partial Transaction of operation

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
    localparam BUFFER_SIZE = 2 * MIN_BUFFER_CAPACITY; // this constant indicate how may ranges of max size can the ram hold
    localparam  PHY_ADDRESS_WIDTH = $clog2(BUFFER_SIZE);
    // number of clocks to process a segment
    localparam T_SEGMENT               = PARTIAL_SIZE; // *********************** TO BE MODIFIED
    localparam T_RANGE_FILL_MAX        = MAX_SEGMENTS_PER_RANGE * T_SEGMENT; 

    // MAX delay of the downstream side to request the data range.
    localparam MAX_DOWNSTREAM_DELAY    = 3 * T_RANGE_FILL_MAX; 

    // Latency of producing valid data after operation_done is asserted
    localparam MAX_COMPLETION_LATENCY  = T_SEGMENT; 
endmodule