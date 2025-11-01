// Create diffusion by mixing bytes
// Inverse is just a shifting in the opposite direction as before
module inv_shiftrows (
                  input [255:0]  state_in,
                  output [255:0] state_out
                  );

   wire [7:0]                    input_byte[0:31];
   wire [7:0]                    output_byte[0:31];

   genvar                        i;
   generate
      for (i = 0; i < 32; i = i + 1)
        assign input_byte[i] = state_in[8*(31-i) +: 8]; // Split 256-bit input into bytes
   endgenerate

// Inverse ShiftRows
   // No shift
   assign output_byte[0] = input_byte[0];   assign output_byte[1] = input_byte[1];
   assign output_byte[2] = input_byte[2];   assign output_byte[3] = input_byte[3];
   assign output_byte[4] = input_byte[4];   assign output_byte[5] = input_byte[5];
   assign output_byte[6] = input_byte[6];   assign output_byte[7] = input_byte[7];

   // shift right by 1
   assign output_byte[8]  = input_byte[15]; assign output_byte[9]  = input_byte[8];
   assign output_byte[10] = input_byte[9];  assign output_byte[11] = input_byte[10];
   assign output_byte[12] = input_byte[11]; assign output_byte[13] = input_byte[12];
   assign output_byte[14] = input_byte[13]; assign output_byte[15] = input_byte[14];

   // shift right by 3
   assign output_byte[16] = input_byte[21]; assign output_byte[17] = input_byte[22];
   assign output_byte[18] = input_byte[23]; assign output_byte[19] = input_byte[16];
   assign output_byte[20] = input_byte[17]; assign output_byte[21] = input_byte[18];
   assign output_byte[22] = input_byte[19]; assign output_byte[23] = input_byte[20];

   // shift right by 4
   assign output_byte[24] = input_byte[28]; assign output_byte[25] = input_byte[29];
   assign output_byte[26] = input_byte[30]; assign output_byte[27] = input_byte[31];
   assign output_byte[28] = input_byte[24]; assign output_byte[29] = input_byte[25];
   assign output_byte[30] = input_byte[26]; assign output_byte[31] = input_byte[27];

   generate
      for (i = 0; i < 32; i = i + 1)
        assign state_out[8*(31-i) +: 8] = output_byte[i]; // 256 bit output
   endgenerate
endmodule
