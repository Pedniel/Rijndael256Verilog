module mixcolumns256_array (
                             input [7:0]  state_in[0:31],
                             output [7:0] state_out[0:31]
                            );
   genvar i;
   wire [7:0] s0, s1, s2, s3;
   function [7:0] xtime;
      input [7:0] b;
      begin
         xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
      end
   endfunction

   // GF(2^8) multiplication by 3
   function [7:0] mul3;
      input [7:0] b;
      begin
         mul3 = xtime(b) ^ b;
      end
   endfunction // mul3

   generate
      for (i = 0; i < 8; i = i + 1) begin : mixcol_loop
         assign s0 = state_in[i*4];
         assign s1 = state_in[i*4 + 1];
         assign s2 = state_in[i*4 + 2];
         assign s3 = state_in[i*4 + 3];

         assign state_out[i*4]     = xtime(s0) ^ mul3(s1) ^ s2 ^ s3;
         assign state_out[i*4 + 1] = s0 ^ xtime(s1) ^ mul3(s2) ^ s3;
         assign state_out[i*4 + 2] = s0 ^ s1 ^ xtime(s2) ^ mul3(s3);
         assign state_out[i*4 + 3] = mul3(s0) ^ s1 ^ s2 ^ xtime(s3);
      end
   endgenerate
endmodule
