/********************************************************************************************/
/*Author        :   Robir Tamer                                                             */
/*File          :   cu.v                                                                    */
/*Discription   :   this module is The Controlling brain of the Processing module           */
/********************************************************************************************/
module cu #(
    parameter PARTIAL_SIZE = 4,
    parameter DATA_WIDTH = 8,
    parameter NUMBER_OF_PARTIALS_PER_OUTPUT = 2

)(
    input   wire    clk,
    input   wire    rst_n,
    input   wire    partial_valid,              // when 1 >>>> partial incoming data is valid      
    input   wire    segment_step,               // when 1 >>>> partial incoming data is valid + new segment
    input   wire    phase_change,               // when 1 >>>> partial incoming data is valid + next state = ACCUMULATED_PARTIALS
                                                // if already in ACCUMULATED_PARTIALS state change direction
    input   wire    next_range,                 // when 1 >>>> partial incoming data is valid + next state = INITIAL_PARTIALS
                                                // and data of this range is ready for the output
    input   wire    operation_done,             // when 1 >>>> partial incoming data is valid + next state = INITIAL_PARTIALS
                                                // and data of this range is ready for the output

    output  wire    sample_data,                // asserted when the data going to the partial sampler is valid
    output  reg     alu_read_en,                // asserted in the ACCUMULATED_PARTIALS state
    output  reg     initial_partial_end,        // asserted in INITIAL_PARTIALS state && (phase_change || range_end || operation_end)
    output  reg     accumulated_partial_end,    // asserted in ACCUMULATED_PARTIALS state && (range_end || operation_end)
    output  wire    direction_change           // asserted when phase_change is high
);
localparam  INITIAL_PARTIALS        ='b0,
            ACCUMULATED_PARTIALS    ='b1;

reg cs,ns;
reg phase_change_temp;

// Current State Logic
always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
                cs <= INITIAL_PARTIALS;
            end 
        else
            begin
                cs <= ns;
            end
    end

// Next State Logic
always @(*)
    begin
        case (cs)
            INITIAL_PARTIALS :      begin
                                        if (phase_change)
                                            begin
                                                ns = ACCUMULATED_PARTIALS;
                                            end
                                        else
                                            begin
                                                ns = INITIAL_PARTIALS;
                                            end
                                    end
            ACCUMULATED_PARTIALS :  begin
                                        if (operation_done || next_range)
                                            begin
                                                ns = INITIAL_PARTIALS;
                                            end
                                        else 
                                            begin
                                                ns = ACCUMULATED_PARTIALS;
                                            end
                                    end
        endcase 
    end

// sample_data Logic
assign sample_data = (segment_step || phase_change || next_range || operation_done); 

// alu_read_en Logic
always @(*)
    begin
        case (cs)
            INITIAL_PARTIALS :      begin
                                        alu_read_en = 1'b0;
                                    end
            ACCUMULATED_PARTIALS :  begin
                                        alu_read_en = 1'b1;
                                    end
        endcase 
    end

// initial_partial_end Logic    
always @(*)
    begin
        case (cs)
            INITIAL_PARTIALS :      begin
                                        if (phase_change || next_range || operation_done)
                                            begin
                                                initial_partial_end = 1'b1;
                                            end
                                        else
                                            begin
                                                initial_partial_end = 1'b0;
                                            end
                                    end
            ACCUMULATED_PARTIALS :  begin
                                        initial_partial_end = 1'b0;
                                    end
        endcase 
    end
// accumulated_partial_end Logic
always @(*)
    begin
        case (cs)
            INITIAL_PARTIALS :      begin
                                        accumulated_partial_end = 1'b0;
                                    end
            ACCUMULATED_PARTIALS :  begin
                                        if ( next_range || operation_done)
                                            begin
                                                accumulated_partial_end = 1'b1;
                                            end
                                        else 
                                            begin
                                                accumulated_partial_end = 1'b0;
                                            end
                                    end
        endcase 
    end

// direction_change Logic
always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
                phase_change_temp <= 1'b0;
            end
        else 
            begin
                phase_change_temp <= phase_change;
            end
    end
assign direction_change = phase_change && ! phase_change_temp;

endmodule