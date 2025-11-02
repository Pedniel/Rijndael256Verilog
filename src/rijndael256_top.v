`timescale 1ns/1ps

module rijndael256_top(
                        input wire         clk,
                        input wire         rst_n,
                        input wire         start,
                        input wire [255:0] plaintext,
                        input wire         key_mode,
                        input wire [255:0] key,
                        output reg [255:0] ciphertext,
                        output reg busy,
                        output reg done
                       );

   localparam Ncolumns = 8;
   localparam Nrounds = 14;

   localparam IDLE         = 3'd0;
   localparam LOAD_STATE   = 3'd1;
   localparam INIT_ROUND   = 3'd2;
   localparam SUB_BYTES    = 3'd3;
   localparam SHIFT_ROWS   = 3'd4;
   localparam MIX_COLS     = 3'd5;
   localparam ADD_ROUNDKEY = 3'd6;
   localparam FINAL_ROUND  = 3'd7;

   reg [2:0]  state_fsm;
   reg [7:0]  state [0:31];
   reg [4:0]  round;
   integer    i;

   wire [7:0] state_after_subbytes[0:31];
   wire [7:0] state_after_shiftrows[0:31];
   wire [7:0] state_after_mixcols[0:31];
   wire [7:0] state_after_addroundkey[0:31];

   reg [7:0]  key_schedule [0:479];
   wire [3839:0] expanded_keys_flat;
   wire [31:0]   expanded_keys_words[0:119];

   wire [7:0]    roundkey[0:31];

   genvar        j, k;

   generate
      for (j = 0; j < 120; j = j + 1) begin : flatten_words
         assign expanded_keys_words[j] = expanded_keys_flat[32*j +: 32];
      end

      for (k = 0; k < 32; k = k + 1) begin : extract_roundkey
         assign roundkey[k] = key_schedule[round*32 + k];
      end
   endgenerate

   always @(*) begin
      for (i = 0; i < 120; i = i + 1) begin
         key_schedule[i*4]     = expanded_keys_words[i][31:24];
         key_schedule[i*4 + 1] = expanded_keys_words[i][23:16];
         key_schedule[i*4 + 2] = expanded_keys_words[i][15:8];
         key_schedule[i*4 + 3] = expanded_keys_words[i][7:0];
      end
   end

   key_expansion_dual keyexp_inst (
                                   .key_mode(key_mode),
                                   .key_in(key),
                                   .round_keys_flat(expanded_keys_flat)
                                   );

   subbytes256_array sb (
                         .state_in(state),
                         .state_out(state_after_subbytes)
                         );

   shiftrows sr_inst (
                      .state_in(state),
                      .state_out(state_after_shiftrows)
                      );

   mixcolumns256_array mc (
                           .state_in(state),
                           .state_out(state_after_mixcols)
                           );

   addroundkey256_array ark (
                             .state_in(state),
                             .roundkey(roundkey),
                             .state_out(state_after_addroundkey)
                             );

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         state_fsm <= IDLE;
         busy <= 1'b0;
         done <= 1'b0;
         round <= 5'd0;
         ciphertext <= 256'd0;
         for (i = 0; i < 32; i = i + 1) begin
            state[i] <= 8'd0;
         end
      end else begin
         case (state_fsm)
           IDLE: begin
              done <= 1'b0;
              if (start) begin
                 busy <= 1'b1;
                 for (i = 0; i < 32; i = i + 1)
                   state[i] <= plaintext[255 - i*8 -: 8];
                 round <= 5'd0;
                 state_fsm <= LOAD_STATE;
              end
           end

           LOAD_STATE: begin
              state_fsm <= INIT_ROUND;
           end

           INIT_ROUND: begin
              for (i = 0; i < 32; i = i + 1)
                state[i] <= state_after_addroundkey[i];
              round <= 5'd1;
              state_fsm <= SUB_BYTES;
           end

           SUB_BYTES: begin
              for (i = 0; i < 32; i = i + 1)
                state[i] <= state_after_subbytes[i];
              state_fsm <= SHIFT_ROWS;
           end

           SHIFT_ROWS: begin
              for (i = 0; i < 32; i = i + 1)
                state[i] <= state_after_shiftrows[i];
              state_fsm <= (round == Nrounds) ? ADD_ROUNDKEY : MIX_COLS;
           end

           MIX_COLS: begin
              for (i = 0; i < 32; i = i + 1)
                state[i] <= state_after_mixcols[i];
              state_fsm <= ADD_ROUNDKEY;
           end

           ADD_ROUNDKEY: begin
              for (i = 0; i < 32; i = i + 1)
                state[i] <= state_after_addroundkey[i];

              if (round == Nrounds)
                state_fsm <= FINAL_ROUND;
              else begin
                 round <= round + 1;
                 state_fsm <= SUB_BYTES;
              end
           end

           FINAL_ROUND: begin
              for (i = 0; i < 32; i = i + 1)
                ciphertext[255 - i*8 -: 8] <= state[i];
              done <= 1'b1;
              busy <= 1'b0;
              state_fsm <= IDLE;
           end

           default: state_fsm <= IDLE;
         endcase
      end
   end

endmodule
