module addroundkey256_array (
    input  [7:0] state_in[0:31],
    input  [7:0] roundkey[0:31],
    output [7:0] state_out[0:31]
);
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1)
            assign state_out[i] = state_in[i] ^ roundkey[i];
    endgenerate
endmodule
