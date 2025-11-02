// AS of my current understanding, the CTR mode is basically a wrapper around the existing ECB mode. This could work.
// THIS WORKS BLOCK BY BLOCK! Which makes it quite slow, as we have to do the entire ECB operation per block.
// If we don't care about size, the simple fix is to pipeline Multiple ECB Cores
// This is a future TODO

module rijndael256_ctr(
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire [255:0] nonce,
    input wire [255:0] data_in,
    input wire         key_mode, // 0 = 192 bit, 1 = 256 bit keymode 
    input wire [191:0] key,
    output reg [255:0] data_out,
    output reg         busy,
    output reg         done
);
    
    reg [255:0] counter;
    wire [255:0] keystream;
    wire ecb_busy, ecb_done;
    reg ecb_start;
    
    rijndael256_top ecb_core(
        .clk(clk),
        .rst_n(rst_n),
        .start(ecb_start),
        .enc_dec(1'b0),
        .data_in(counter),
        .key_mode(key_mode),
        .key({64'b0, key}),  // Can pad 192bit key to 256bit key
        .data_out(keystream),
        .busy(ecb_busy),
        .done(ecb_done)
    );
   
    `timescale 1ns/1ps

    localparam IDLE = 2'd0;
    localparam ENCRYPT_CTR = 2'd1;
    localparam XOR_OUTPUT = 2'd2;
    
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            ecb_start <= 0;
            counter <= 0;
            data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        counter <= nonce;
                        busy <= 1;
                        ecb_start <= 1;
                        state <= ENCRYPT_CTR;
                    end
                end
                
                ENCRYPT_CTR: begin
                    ecb_start <= 0;
                    if (ecb_done) begin
                        state <= XOR_OUTPUT;
                    end
                end
                
                XOR_OUTPUT: begin
                    data_out <= data_in ^ keystream;
                    counter <= counter + 1;
                    done <= 1;
                    busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
