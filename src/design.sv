`default_nettype none

module tt_um_alizada84_hardware_bloom_filter_for_intrusion_detection (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // --------------------------------------------------------
    // Tiny Tapeout Port Mapping
    // --------------------------------------------------------
    // Map standard TT ports to our custom internal wires
    wire reset = ~rst_n;                  // TT reset is active low, invert it for our logic
    wire [7:0] data_in = ui_in;           // 8-bit data stream uses the 8 standard inputs
    wire train_scan_mode = uio_in[0];     // Use bidirectional pin 0 as the train/scan switch

    wire intrusion_detected;              
    
    // Map our output to standard output pin 0, tie off the rest to 0
    assign uo_out[0] = intrusion_detected; 
    assign uo_out[7:1] = 7'b0;            

    // Tie off unused bidirectional pins (set all to input mode)
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0; 

    // --------------------------------------------------------
    // Bloom Filter Logic (Unchanged)
    // --------------------------------------------------------
    reg [15:0] bloom_array;

    wire [3:0] hash1;
    wire [3:0] hash2;
    wire [3:0] hash3;

    assign hash1 = data_in[7:4] ^ data_in[3:0];
    assign hash2 = {data_in[1:0], data_in[7:6]} ^ data_in[5:2];
    assign hash3 = ~data_in[4:1];

    assign intrusion_detected = (train_scan_mode == 1'b1) ? 
                                (bloom_array[hash1] & bloom_array[hash2] & bloom_array[hash3]) : 
                                1'b0;

    // Notice posedge reset is changed to negedge rst_n to match the standard port
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bloom_array <= 16'b0;
        end 
        else if (train_scan_mode == 1'b0) begin
            bloom_array[hash1] <= 1'b1;
            bloom_array[hash2] <= 1'b1;
            bloom_array[hash3] <= 1'b1;
        end
    end

endmodule
