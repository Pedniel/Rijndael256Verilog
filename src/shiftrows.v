// Create diffusion by mixing bytes
module shiftrows (
    input  [7:0] state_in[0:31],
    output [7:0] state_out[0:31]
);

    // Row 0: no shift
    assign state_out[0] = state_in[0];   assign state_out[1] = state_in[1];
    assign state_out[2] = state_in[2];   assign state_out[3] = state_in[3];
    assign state_out[4] = state_in[4];   assign state_out[5] = state_in[5];
    assign state_out[6] = state_in[6];   assign state_out[7] = state_in[7];

    // Row 1: shift left by 1
    assign state_out[8]  = state_in[9];  assign state_out[9]  = state_in[10];
    assign state_out[10] = state_in[11]; assign state_out[11] = state_in[12];
    assign state_out[12] = state_in[13]; assign state_out[13] = state_in[14];
    assign state_out[14] = state_in[15]; assign state_out[15] = state_in[8];

    // Row 2: shift left by 3
    assign state_out[16] = state_in[19]; assign state_out[17] = state_in[20];
    assign state_out[18] = state_in[21]; assign state_out[19] = state_in[22];
    assign state_out[20] = state_in[23]; assign state_out[21] = state_in[16];
    assign state_out[22] = state_in[17]; assign state_out[23] = state_in[18];

    // Row 3: shift left by 4
    assign state_out[24] = state_in[28]; assign state_out[25] = state_in[29];
    assign state_out[26] = state_in[30]; assign state_out[27] = state_in[31];
    assign state_out[28] = state_in[24]; assign state_out[29] = state_in[25];
    assign state_out[30] = state_in[26]; assign state_out[31] = state_in[27];

endmodule
