`timescale 1ns/1ps

module rijndael256_top(
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire         enc_dec,       // 0=encrypt, 1=decrypt
    input wire [255:0] data_in,
    input wire         key_mode,                       
    input wire [255:0] key,
    output reg [255:0] data_out,
    output reg         busy,
    output reg         done
);

   localparam Nrounds = 14;
   
   localparam IDLE             = 4'd0;
   localparam ENC_INIT_ROUND   = 4'd1;
   localparam ENC_SUB_BYTES    = 4'd2;
   localparam ENC_SHIFT_ROWS   = 4'd3;
   localparam ENC_MIX_COLS     = 4'd4;
   localparam ENC_ADD_ROUNDKEY = 4'd5;
   
   localparam DEC_INIT_ROUND   = 4'd6;
   localparam DEC_INV_SHIFT_ROWS=4'd7;
   localparam DEC_INV_SUB_BYTES= 4'd8;
   localparam DEC_ADD_ROUNDKEY = 4'd9;
   localparam DEC_INV_MIX_COLS = 4'd10;
   
   localparam FINAL_ROUND      = 4'd11;

   reg [3:0]  state_fsm;
   reg [7:0]  state [0:31];
   reg [7:0]  state_next [0:31];
   reg [4:0]  round;
   integer    i;

   wire [3839:0] expanded_keys_flat;
   wire [255:0] state_flat;
   wire [255:0] subbytes_out, shiftrows_out, mixcols_out, addroundkey_out;
   wire [255:0] inv_subbytes_out, inv_shiftrows_out, inv_mixcols_out;
   wire [255:0] current_roundkey;

   wire [7:0] key_schedule [0:479];
   
   key_expansion_dual keyexp_inst (
       .key_mode(key_mode), .key_in(key), .round_keys_flat(expanded_keys_flat)
   );

   // Encryption 
   subbytes256    subbytes_inst (.state_in(state_flat), .state_out(subbytes_out));
   shiftrows256   shiftrows_inst(.state_in(state_flat), .state_out(shiftrows_out));
   mixcolumns256  mixcols_inst  (.state_in(state_flat), .state_out(mixcols_out));
   addroundkey256 addroundkey_inst(.state_in(state_flat), .roundkey(current_roundkey), .state_out(addroundkey_out));

   // Decryption 
   inv_subbytes256    inv_subbytes_inst (.state_in(state_flat), .state_out(inv_subbytes_out));
   inv_shiftrows256   inv_shiftrows_inst(.state_in(state_flat), .state_out(inv_shiftrows_out));
   inv_mixcolumns256  inv_mixcols_inst  (.state_in(state_flat), .state_out(inv_mixcols_out));

   genvar j;
   generate
      for (j = 0; j < 32; j = j + 1) begin : state_conv
         assign state_flat[255 - j*8 -: 8] = state[j];
      end
   endgenerate

   generate
      for (j = 0; j < 120; j = j + 1) begin : key_expand
         assign key_schedule[j*4]     = expanded_keys_flat[32*j + 31 -: 8];
         assign key_schedule[j*4 + 1] = expanded_keys_flat[32*j + 23 -: 8];
         assign key_schedule[j*4 + 2] = expanded_keys_flat[32*j + 15 -: 8];
         assign key_schedule[j*4 + 3] = expanded_keys_flat[32*j +  7 -: 8];
      end
   endgenerate

   // round key selection for both encryption and decryption
   wire [4:0] effective_round;
   assign effective_round = (state_fsm == ENC_INIT_ROUND) ? 5'd0 :
                           (state_fsm == DEC_INIT_ROUND) ? Nrounds :
                           (state_fsm == DEC_INV_SHIFT_ROWS || 
                            state_fsm == DEC_INV_SUB_BYTES || 
                            state_fsm == DEC_ADD_ROUNDKEY ||
                            state_fsm == DEC_INV_MIX_COLS) ? (Nrounds - round) :
                           round;

   generate
      for (j = 0; j < 32; j = j + 1) begin : roundkey_conv
         assign current_roundkey[255 - j*8 -: 8] = key_schedule[effective_round * 32 + j];
      end
   endgenerate

   always @(*) begin
      case (state_fsm)
         ENC_INIT_ROUND, DEC_INIT_ROUND: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = addroundkey_out[255 - i*8 -: 8];
            
         ENC_SUB_BYTES: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = subbytes_out[255 - i*8 -: 8];
         ENC_SHIFT_ROWS: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = shiftrows_out[255 - i*8 -: 8];
         ENC_MIX_COLS: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = mixcols_out[255 - i*8 -: 8];
         ENC_ADD_ROUNDKEY: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = addroundkey_out[255 - i*8 -: 8];
            
         DEC_INV_SHIFT_ROWS: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = inv_shiftrows_out[255 - i*8 -: 8];
         DEC_INV_SUB_BYTES: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = inv_subbytes_out[255 - i*8 -: 8];
         DEC_ADD_ROUNDKEY: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = addroundkey_out[255 - i*8 -: 8];
         DEC_INV_MIX_COLS: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = inv_mixcols_out[255 - i*8 -: 8];
            
         default: 
            for (i = 0; i < 32; i = i + 1) state_next[i] = state[i];
      endcase
   end

   // FSM for encryption and decryption
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         state_fsm <= IDLE;
         busy <= 1'b0;
         done <= 1'b0;
         round <= 5'd0;
         data_out <= 256'd0;
         for (i = 0; i < 32; i = i + 1) state[i] <= 8'd0;
      end else begin
         case (state_fsm)
           IDLE: begin
              done <= 1'b0;
              if (start) begin
                 busy <= 1'b1;
                 for (i = 0; i < 32; i = i + 1) state[i] <= data_in[255 - i*8 -: 8];
                 round <= 5'd0;
                 
                 if (enc_dec) 
                    state_fsm <= DEC_INIT_ROUND;  // Start decryption
                 else 
                    state_fsm <= ENC_INIT_ROUND;  // Start encryption
              end
           end

           // ENCRYPTION
           ENC_INIT_ROUND: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              round <= 5'd1;
              state_fsm <= ENC_SUB_BYTES;
           end

           ENC_SUB_BYTES: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= ENC_SHIFT_ROWS;
           end

           ENC_SHIFT_ROWS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= (round == Nrounds) ? ENC_ADD_ROUNDKEY : ENC_MIX_COLS;
           end

           ENC_MIX_COLS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= ENC_ADD_ROUNDKEY;
           end

           ENC_ADD_ROUNDKEY: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              if (round == Nrounds)
                 state_fsm <= FINAL_ROUND;
              else begin
                 round <= round + 5'd1;
                 state_fsm <= ENC_SUB_BYTES;
              end
           end

           // DECRYPTION
           DEC_INIT_ROUND: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              round <= 5'd1;
              state_fsm <= DEC_INV_SHIFT_ROWS;
           end

           DEC_INV_SHIFT_ROWS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= DEC_INV_SUB_BYTES;
           end

           DEC_INV_SUB_BYTES: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= DEC_ADD_ROUNDKEY;
           end

           DEC_ADD_ROUNDKEY: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              if (round == Nrounds)
                 state_fsm <= FINAL_ROUND;
              else begin
                 state_fsm <= DEC_INV_MIX_COLS;
              end
           end

           DEC_INV_MIX_COLS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              round <= round + 5'd1;
              state_fsm <= DEC_INV_SHIFT_ROWS;
           end

           FINAL_ROUND: begin
              for (i = 0; i < 32; i = i + 1) data_out[255 - i*8 -: 8] <= state[i];
              done <= 1'b1;
              busy <= 1'b0;
              state_fsm <= IDLE;
           end

           default: state_fsm <= IDLE;
         endcase
      end
   end

endmodule
