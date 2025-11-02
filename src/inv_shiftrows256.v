// Create diffusion by mixing bytes
// Inverse is just a shifting in the opposite direction as before
module inv_shiftrows256 (
                  input [255:0]  state_in,
                  output [255:0] state_out
                  );
   // Break input into byte array for easier indexing
   wire [7:0]                    s [0:31];
   reg [7:0]                     t [0:31];
   integer                       i;

   generate
      genvar                     j;
      for (j = 0; j < 32; j = j + 1)
        assign s[j] = state_in[j*8 +: 8];
   endgenerate

   always @(*) begin
      // Row 0: no shift
      t[0]  = s[0];   t[4]  = s[4];
      t[8]  = s[8];   t[12] = s[12];
      t[16] = s[16];  t[20] = s[20];
      t[24] = s[24];  t[28] = s[28];

      // Row 1: shift right by 1
      t[1]  = s[29];   t[5]  = s[1];
      t[9]  = s[5];   t[13] = s[9];
      t[17] = s[13];  t[21] = s[17];
      t[25] = s[21];  t[29] = s[25];

      // Row 2: shift right by 3
      t[2]  = s[22];  t[6]  = s[26];
      t[10] = s[30];  t[14] = s[2];
      t[18] = s[6];  t[22] = s[10];
      t[26] = s[14];   t[30] = s[18];

      // Row 3: shift right by 4
      t[3]  = s[19];  t[7]  = s[23];
      t[11] = s[27];  t[15] = s[31];
      t[19] = s[3];   t[23] = s[7];
      t[27] = s[11];  t[31] = s[15];
   end

   // Repack into 256-bit vector
   generate
      for (j = 0; j < 32; j = j + 1)
        assign state_out[j*8 +: 8] = t[j];
   endgenerate
endmodule

/* -----\/----- EXCLUDED -----\/-----
| s0   s4   s8   s12  s16  s20  s24  s28 |   Row 0
| s1   s5   s9   s13  s17  s21  s25  s29 |   Row 1
| s2   s6   s10  s14  s18  s22  s26  s30 |   Row 2
| s3   s7   s11  s15  s19  s23  s27  s31 |   Row 3
  -----/\----- EXCLUDED -----/\----- */
