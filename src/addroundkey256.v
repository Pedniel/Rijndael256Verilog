module addroundkey256 (
    input wire [255:0] state_in,
    input wire [255:0] roundkey,
    output wire [255:0] state_out
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : xor_loop
            // Big Endian
            assign state_out[255 - i*8 -: 8] = state_in[255 - i*8 -: 8] ^ roundkey[255 - i*8 -: 8];
        end
    endgenerate
endmodule
