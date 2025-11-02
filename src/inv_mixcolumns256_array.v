module inv_mixcolumns256_array (
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

   function [7:0] mul9;
      input [7:0] b;
      reg [7:0]   t;
      begin
         // Multiply by x (2) three times
         t = xtime(b);   // b * 2
         t = xtime(t);   // b * 4
         t = xtime(t);   // b * 8
         mul9 = t ^ b;
      end
   endfunction

   function [7:0] mul11;
      input [7:0] b;
      reg [7:0]   t2;
      reg [7:0]   t4;
      reg [7:0]   t8;
      begin
         t2 = xtime(b);   // b * 2
         t4 = xtime(t2);   // b * 4
         t8 = xtime(t4);   // b * 8
         mul11 = t8 ^ t2 ^ b;
      end
   endfunction // mul11

   function [7:0] mul13; // For inverse mixcolumns
      input [7:0] b;
      reg [7:0]   t2;
      reg [7:0]   t4;
      reg [7:0]   t8;
      begin
         t2 = xtime(b);   // input * 2
         t4 = xtime(t2);   //input * 4
         t8 = xtime(t4);   // input * 8
         mul13 = t8 ^ t4 ^ b;
      end
   endfunction // mul13

   function [7:0] mul14;
      input [7:0] b;
      reg [7:0]   t2;
      reg [7:0]   t4;
      reg [7:0]   t8;
      begin
         t2 = xtime(b);   // input * 2
         t4 = xtime(t2);   //input * 4
         t8 = xtime(t4);   // input * 8
         mul14 = t8 ^ t4 ^ t2;
      end
   endfunction

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

/* -----\/----- EXCLUDED -----\/-----
   task automatic do_inv_mixcolumns;
      reg [7:0] s0, s1, s2, s3;
      begin
         for (i = 0; i < 8; i = i + 1) begin
            s0 = state[i*4];     s1 = state[i*4 + 1];
            s2 = state[i*4 + 2]; s3 = state[i*4 + 3];

            state_next[i*4]     = mul14(s0) ^ mul11(s1) ^ mul13(s2) ^ mul9(s3);
            state_next[i*4 + 1] = mul9(s0)  ^ mul14(s1) ^ mul11(s2) ^ mul13(s3);
            state_next[i*4 + 2] = mul13(s0) ^ mul9(s1)  ^ mul14(s2) ^ mul11(s3);
            state_next[i*4 + 3] = mul11(s0) ^ mul13(s1) ^ mul9(s2)  ^ mul14(s3);
         end
      end
   endtask -----/\----- EXCLUDED -----/\----- */
