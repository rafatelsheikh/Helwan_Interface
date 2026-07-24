/*
questions? 
does the downstream may request data even if the buffer is empty
hallo mr rafat you may struggle here please bare with me and call 01012887393 for any issues (the design is on fire)
*/
module mem_arbiter #(
    parameter ADDR_WIDTH = 8, // logical range address
    parameter BUFFER_SIZE = 1024,
    parameter OUTPUTS_PER_SEGMENT = 2, 
    parameter PHY_ADDRESS_WIDTH = 10,
    parameter MAX_SEGMENTS_PER_RANGE = 100,
    parameter MAX_DOWNSTREAM_DELAY = 1200
) (
    input wire clk,
    input wire rst_n,
    input wire end_range, // intial partials done
    input wire end_accumlated_processing, // indicat if the current range is valid or no
    input wire change_direction,
    input wire en,
    input wire [ADDR_WIDTH-1:0] address_in,

    output wire [PHY_ADDRESS_WIDTH-1:0] out_addr_out,
    output wire [PHY_ADDRESS_WIDTH-1:0] alu_addr_out,
    output wire output_valid
);

    // number of blocks in the memory
    localparam MAX_RANGE_NUMBER = BUFFER_SIZE / (OUTPUTS_PER_SEGMENT * MAX_SEGMENTS_PER_RANGE);
    localparam MAX_OUTPUTWORDS_PER_RANGE = OUTPUTS_PER_SEGMENT * MAX_SEGMENTS_PER_RANGE;

    localparam block_idx_width = $clog2(MAX_RANGE_NUMBER); 

    reg [block_idx_width-1:0] block_idx; // used to index memory blocks
    reg [block_idx_width-1:0] oldest_valid_ptr; // pointing to oldeest range
    reg [MAX_RANGE_NUMBER-1:0] valid_array; // bit 0 -> block 0 (mask to show which block has valid data)

    // reg [ADDR_WIDTH-1:0] ptr_array[MAX_RANGE_NUMBER-1:0]; // points to the end of each range
    reg [PHY_ADDRESS_WIDTH-1:0] current_range_ptr; // pointer to current location in memory
    reg [PHY_ADDRESS_WIDTH-1:0] out_addr_out_reg;
    // reg update_out_address; // pulse to enable updating output address

    reg addr_active, addr_active_d1;
    wire free_valid;
    reg [ADDR_WIDTH-1:0] address_in_reg;


    // this is a set of done signals that indicate if a time out has been rasied for the block number.
    // counter_done[0] -> block 0
    // counter_done[1] -> block 1 etc..
    wire [MAX_RANGE_NUMBER-1:0] counter_done;
  
    
    // handeling alu read address & current range pointer
    wire inc;
    assign alu_addr_out = current_range_ptr;
    assign inc = (!rst_n || end_accumlated_processing) ? 1 : (change_direction)? ~inc : inc; // latched need to be modified inc must be register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_range_ptr <= 0;
        end 
        else begin
            // handle inc / dec of the pointer
            if ((end_range && (!change_direction)) || end_accumlated_processing) begin
                current_range_ptr <= block_idx * MAX_OUTPUTWORDS_PER_RANGE;
            end
            else begin
                if (en) begin
                    if (inc)
                        current_range_ptr <= current_range_ptr + 1'b1;
                    else
                        current_range_ptr <= current_range_ptr - 1'b1;
                end
                else begin
                    current_range_ptr <= current_range_ptr;             
                end
            end
        end   
    end

    // current index pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_idx <= 0;
        end
        else begin    
            if ((end_range && (!change_direction)) || end_accumlated_processing) begin
                if (block_idx == MAX_RANGE_NUMBER-1) begin
                    block_idx <= 0;
                end
                else begin
                    block_idx <= block_idx + 1;    
                end
            end
            else block_idx <= block_idx;
        end
    end

    // handle output address
    assign out_addr_out = out_addr_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            out_addr_out_reg <= 0;
        end
        else begin
            // if (update_out_address) begin
            out_addr_out_reg <= address_in + oldest_valid_ptr * MAX_OUTPUTWORDS_PER_RANGE;
            // end
            // else begin
            //    out_addr_out_reg <= out_addr_out_reg;
            // end
        end
    end

    // this block test if the address_in is moving or no
    // what a solution !!!!!!!!!
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_in_reg <= 0;
            addr_active <= 0;
            addr_active_d1 <= 0;
            
        end
        else begin
            address_in_reg <= address_in;
            addr_active <= (address_in != address_in_reg);
            addr_active_d1 <= addr_active;
        end
    end
    assign free_valid = (!addr_active) && addr_active_d1;
    

    // output valid case
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            oldest_valid_ptr <= 0;
            // update_out_address <= 0;
            valid_array <= 0;
        end
        else begin
            if (((end_range && (!change_direction)) || end_accumlated_processing )&& free_valid) begin
                valid_array[block_idx] <= 1;
                valid_array[oldest_valid_ptr] <= 0;
            end
            
            else if ((end_range && (!change_direction)) || end_accumlated_processing) begin
                valid_array[block_idx] <= 1;
            end
  
            else if (free_valid) begin
                valid_array[oldest_valid_ptr] <= 0;
            end

            else if (|counter_done) begin
                valid_array <= valid_array & ~counter_done;
            end

            // valid pointer handling logic
            if ((!valid_array[oldest_valid_ptr] || free_valid) && (|valid_array)) begin
                // update_out_address <= 0;
                if (oldest_valid_ptr == MAX_RANGE_NUMBER-1)begin
                    oldest_valid_ptr <= 0;
                end
                else begin
                    oldest_valid_ptr <= oldest_valid_ptr + 1;
                end    
            end
            else begin
                // update_out_address <= 1;
                oldest_valid_ptr <= oldest_valid_ptr;
            end

        end
    end



    assign output_valid = valid_array[oldest_valid_ptr];

    // Time_out counters
    // making done signal up for two cycles to avoid conflect with valid update duo to data done
    counter_array #(
        .NUM_COUNTERS (MAX_RANGE_NUMBER),      // number of counters to generate
        .MAX_COUNT    (MAX_DOWNSTREAM_DELAY)      // count target for every instance
    ) u_counter_array (
        .clk         (clk),
        .rst_n       (rst_n),
        .keep_count  (valid_array),   
        .done        (counter_done)          
    );
endmodule