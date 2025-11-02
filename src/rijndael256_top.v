`timescale 1ns/1ps

module rijndael256_top(
    input wire         clk,
    input wire         rst_n,
    input wire         start,
    input wire [255:0] plaintext,
    input wire         key_mode,                       
    input wire [255:0] key,
    output reg [255:0] ciphertext,
    output reg         busy,
    output reg         done
);

   localparam Nrounds = 14;
   localparam IDLE         = 3'd0;
   localparam INIT_ROUND   = 3'd1;
   localparam SUB_BYTES    = 3'd2;
   localparam SHIFT_ROWS   = 3'd3;
   localparam MIX_COLS     = 3'd4;
   localparam ADD_ROUNDKEY = 3'd5;
   localparam FINAL_ROUND  = 3'd6;

   reg [2:0]  state_fsm;
   reg [7:0]  state [0:31];
   reg [7:0]  state_next [0:31];
   reg [4:0]  round;
   integer    i;

   wire [3839:0] expanded_keys_flat;
   wire [255:0] state_flat;
   wire [255:0] subbytes_out, shiftrows_out, mixcols_out, addroundkey_out;
   wire [255:0] current_roundkey;

   wire [7:0] key_schedule [0:479];
   
   key_expansion_dual keyexp_inst (
       .key_mode(key_mode), .key_in(key), .round_keys_flat(expanded_keys_flat)
   );

   subbytes256    subbytes_inst (.state_in(state_flat), .state_out(subbytes_out));
   shiftrows256   shiftrows_inst(.state_in(state_flat), .state_out(shiftrows_out));
   mixcolumns256  mixcols_inst  (.state_in(state_flat), .state_out(mixcols_out));
   addroundkey256 addroundkey_inst(.state_in(state_flat), .roundkey(current_roundkey), .state_out(addroundkey_out));

   genvar j;
   generate
      for (j = 0; j < 32; j = j + 1) begin : state_conv
         assign state_flat[255 - j*8 -: 8] = state[j];
      end
   endgenerate

   generate
      for (j = 0; j < 120; j = j + 1) begin : key_expand
         assign key_schedule[j*4]     = expanded_keys_flat[32*j + 31 -: 8]; // MSB
         assign key_schedule[j*4 + 1] = expanded_keys_flat[32*j + 23 -: 8];
         assign key_schedule[j*4 + 2] = expanded_keys_flat[32*j + 15 -: 8];
         assign key_schedule[j*4 + 3] = expanded_keys_flat[32*j +  7 -: 8]; // LSB
      end
   endgenerate

   // round key selection
   wire [4:0] effective_round = (state_fsm == INIT_ROUND) ? 5'd0 : round;
   generate
      for (j = 0; j < 32; j = j + 1) begin : roundkey_conv
         assign current_roundkey[255 - j*8 -: 8] = key_schedule[effective_round * 32 + j];
      end
   endgenerate

   // output selection
   always @(*) begin
      case (state_fsm)
         INIT_ROUND:   for (i = 0; i < 32; i = i + 1) state_next[i] = addroundkey_out[255 - i*8 -: 8];
         SUB_BYTES:    for (i = 0; i < 32; i = i + 1) state_next[i] = subbytes_out[255 - i*8 -: 8];
         SHIFT_ROWS:   for (i = 0; i < 32; i = i + 1) state_next[i] = shiftrows_out[255 - i*8 -: 8];
         MIX_COLS:     for (i = 0; i < 32; i = i + 1) state_next[i] = mixcols_out[255 - i*8 -: 8];
         ADD_ROUNDKEY: for (i = 0; i < 32; i = i + 1) state_next[i] = addroundkey_out[255 - i*8 -: 8];
         default:      for (i = 0; i < 32; i = i + 1) state_next[i] = state[i];
      endcase
   end

   // FSM
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         state_fsm <= IDLE;
         busy <= 1'b0;
         done <= 1'b0;
         round <= 5'd0;
         ciphertext <= 256'd0;
         for (i = 0; i < 32; i = i + 1) state[i] <= 8'd0;
      end else begin
         case (state_fsm)
           IDLE: begin
              done <= 1'b0;
              if (start) begin
                 busy <= 1'b1;
                 for (i = 0; i < 32; i = i + 1) state[i] <= plaintext[255 - i*8 -: 8];
                 round <= 5'd0;
                 state_fsm <= INIT_ROUND;
              end
           end

           INIT_ROUND: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              round <= 5'd1;
              state_fsm <= SUB_BYTES;
           end

           SUB_BYTES: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= SHIFT_ROWS;
           end

           SHIFT_ROWS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= (round == Nrounds) ? ADD_ROUNDKEY : MIX_COLS;
           end

           MIX_COLS: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              state_fsm <= ADD_ROUNDKEY;
           end

           ADD_ROUNDKEY: begin
              for (i = 0; i < 32; i = i + 1) state[i] <= state_next[i];
              if (round == Nrounds) begin
                 state_fsm <= FINAL_ROUND;
              end else begin
                 round <= round + 5'd1;
                 state_fsm <= SUB_BYTES;
              end
           end

           FINAL_ROUND: begin
              for (i = 0; i < 32; i = i + 1) ciphertext[255 - i*8 -: 8] <= state[i];
              done <= 1'b1;
              busy <= 1'b0;
              state_fsm <= IDLE;
           end

           default: state_fsm <= IDLE;
         endcase
      end
   end
endmodule
