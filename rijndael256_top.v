`timescale 1ns/1ps

// Rijndael-256 blocksize Encryption Module
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

   localparam Ncolumns = 8;  // 8 columns for 256bit block
   localparam Nrounds = 14;

   // States
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
   reg [7:0]  state_next [0:31];
   reg [7:0]  key_schedule [0:479]; // round keys (480 bytes)
   reg [4:0]  round;
   integer    i;

   wire [3839:0] expanded_keys_flat; // 32 * 120 = 3840 bits

   key_expansion_dual keyexp_inst (
                                   .key_mode(key_mode),
                                   .key_in(key),
                                   .round_keys_flat(expanded_keys_flat)
                                   );
   
   wire [31:0]   expanded_keys_words[0:119];

   genvar j;
   generate
      for (j = 0; j < 120; j = j + 1) begin : flatten_words
         assign expanded_keys_words[j] = expanded_keys_flat[32*j +: 32];
      end
   endgenerate


   // Convert 32bit words to byte array
   always @(*) begin
      for (i = 0; i < 120; i = i + 1) begin
         key_schedule[i*4]     = expanded_keys_words[i][31:24];
         key_schedule[i*4 + 1] = expanded_keys_words[i][23:16];
         key_schedule[i*4 + 2] = expanded_keys_words[i][15:8];
         key_schedule[i*4 + 3] = expanded_keys_words[i][7:0];
      end
   end

   // inverse S-box
   function [7:0] inv_sbox;
      input [7:0] in;
      begin
         case (in)
            8'h00: inv_sbox = 8'h52; 8'h01: inv_sbox = 8'h09; 8'h02: inv_sbox = 8'h6A; 8'h03: inv_sbox = 8'hD5;
            8'h04: inv_sbox = 8'h30; 8'h05: inv_sbox = 8'h36; 8'h06: inv_sbox = 8'hA5; 8'h07: inv_sbox = 8'h38;
            8'h08: inv_sbox = 8'hBF; 8'h09: inv_sbox = 8'h40; 8'h0A: inv_sbox = 8'hA3; 8'h0B: inv_sbox = 8'h9E;
            8'h0C: inv_sbox = 8'h81; 8'h0D: inv_sbox = 8'hF3; 8'h0E: inv_sbox = 8'hD7; 8'h0F: inv_sbox = 8'hFB;

            8'h10: inv_sbox = 8'h7C; 8'h11: inv_sbox = 8'hE3; 8'h12: inv_sbox = 8'h39; 8'h13: inv_sbox = 8'h82;
            8'h14: inv_sbox = 8'h9B; 8'h15: inv_sbox = 8'h2F; 8'h16: inv_sbox = 8'hFF; 8'h17: inv_sbox = 8'h87;
            8'h18: inv_sbox = 8'h34; 8'h19: inv_sbox = 8'h8E; 8'h1A: inv_sbox = 8'h43; 8'h1B: inv_sbox = 8'h44;
            8'h1C: inv_sbox = 8'hC4; 8'h1D: inv_sbox = 8'hDE; 8'h1E: inv_sbox = 8'hE9; 8'h1F: inv_sbox = 8'hCB;

            8'h20: inv_sbox = 8'h54; 8'h21: inv_sbox = 8'h7B; 8'h22: inv_sbox = 8'h94; 8'h23: inv_sbox = 8'h32;
            8'h24: inv_sbox = 8'hA6; 8'h25: inv_sbox = 8'hC2; 8'h26: inv_sbox = 8'h23; 8'h27: inv_sbox = 8'h3D;
            8'h28: inv_sbox = 8'hEE; 8'h29: inv_sbox = 8'h4C; 8'h2A: inv_sbox = 8'h95; 8'h2B: inv_sbox = 8'h0B;
            8'h2C: inv_sbox = 8'h42; 8'h2D: inv_sbox = 8'hFA; 8'h2E: inv_sbox = 8'hC3; 8'h2F: inv_sbox = 8'h4E;

            8'h30: inv_sbox = 8'h08; 8'h31: inv_sbox = 8'h2E; 8'h32: inv_sbox = 8'hA1; 8'h33: inv_sbox = 8'h66;
            8'h34: inv_sbox = 8'h28; 8'h35: inv_sbox = 8'hD9; 8'h36: inv_sbox = 8'h24; 8'h37: inv_sbox = 8'hB2;
            8'h38: inv_sbox = 8'h76; 8'h39: inv_sbox = 8'h5B; 8'h3A: inv_sbox = 8'hA2; 8'h3B: inv_sbox = 8'h49;
            8'h3C: inv_sbox = 8'h6D; 8'h3D: inv_sbox = 8'h8B; 8'h3E: inv_sbox = 8'hD1; 8'h3F: inv_sbox = 8'h25;

            8'h40: inv_sbox = 8'h72; 8'h41: inv_sbox = 8'hF8; 8'h42: inv_sbox = 8'hF6; 8'h43: inv_sbox = 8'h64;
            8'h44: inv_sbox = 8'h86; 8'h45: inv_sbox = 8'h68; 8'h46: inv_sbox = 8'h98; 8'h47: inv_sbox = 8'h16;
            8'h48: inv_sbox = 8'hD4; 8'h49: inv_sbox = 8'hA4; 8'h4A: inv_sbox = 8'h5C; 8'h4B: inv_sbox = 8'hCC;
            8'h4C: inv_sbox = 8'h5D; 8'h4D: inv_sbox = 8'h65; 8'h4E: inv_sbox = 8'hB6; 8'h4F: inv_sbox = 8'h92;

            8'h50: inv_sbox = 8'h6C; 8'h51: inv_sbox = 8'h70; 8'h52: inv_sbox = 8'h48; 8'h53: inv_sbox = 8'h50;
            8'h54: inv_sbox = 8'hFD; 8'h55: inv_sbox = 8'hED; 8'h56: inv_sbox = 8'hB9; 8'h57: inv_sbox = 8'hDA;
            8'h58: inv_sbox = 8'h5E; 8'h59: inv_sbox = 8'h15; 8'h5A: inv_sbox = 8'h46; 8'h5B: inv_sbox = 8'h57;
            8'h5C: inv_sbox = 8'hA7; 8'h5D: inv_sbox = 8'h8D; 8'h5E: inv_sbox = 8'h9D; 8'h5F: inv_sbox = 8'h84;

            8'h60: inv_sbox = 8'h90; 8'h61: inv_sbox = 8'hD8; 8'h62: inv_sbox = 8'hAB; 8'h63: inv_sbox = 8'h00;
            8'h64: inv_sbox = 8'h8C; 8'h65: inv_sbox = 8'hBC; 8'h66: inv_sbox = 8'hD3; 8'h67: inv_sbox = 8'h0A;
            8'h68: inv_sbox = 8'hF7; 8'h69: inv_sbox = 8'hE4; 8'h6A: inv_sbox = 8'h58; 8'h6B: inv_sbox = 8'h05;
            8'h6C: inv_sbox = 8'hB8; 8'h6D: inv_sbox = 8'hB3; 8'h6E: inv_sbox = 8'h45; 8'h6F: inv_sbox = 8'h06;

            8'h70: inv_sbox = 8'hD0; 8'h71: inv_sbox = 8'h2C; 8'h72: inv_sbox = 8'h1E; 8'h73: inv_sbox = 8'h8F;
            8'h74: inv_sbox = 8'hCA; 8'h75: inv_sbox = 8'h3F; 8'h76: inv_sbox = 8'h0F; 8'h77: inv_sbox = 8'h02;
            8'h78: inv_sbox = 8'hC1; 8'h79: inv_sbox = 8'hAF; 8'h7A: inv_sbox = 8'hBD; 8'h7B: inv_sbox = 8'h03;
            8'h7C: inv_sbox = 8'h01; 8'h7D: inv_sbox = 8'h13; 8'h7E: inv_sbox = 8'h8A; 8'h7F: inv_sbox = 8'h6B;

            8'h80: inv_sbox = 8'h3A; 8'h81: inv_sbox = 8'h91; 8'h82: inv_sbox = 8'h11; 8'h83: inv_sbox = 8'h41;
            8'h84: inv_sbox = 8'h4F; 8'h85: inv_sbox = 8'h67; 8'h86: inv_sbox = 8'hDC; 8'h87: inv_sbox = 8'hEA;
            8'h88: inv_sbox = 8'h97; 8'h89: inv_sbox = 8'hF2; 8'h8A: inv_sbox = 8'hCF; 8'h8B: inv_sbox = 8'hCE;
            8'h8C: inv_sbox = 8'hF0; 8'h8D: inv_sbox = 8'hB4; 8'h8E: inv_sbox = 8'hE6; 8'h8F: inv_sbox = 8'h73;

            8'h90: inv_sbox = 8'h96; 8'h91: inv_sbox = 8'hAC; 8'h92: inv_sbox = 8'h74; 8'h93: inv_sbox = 8'h22;
            8'h94: inv_sbox = 8'hE7; 8'h95: inv_sbox = 8'hAD; 8'h96: inv_sbox = 8'h35; 8'h97: inv_sbox = 8'h85;
            8'h98: inv_sbox = 8'hE2; 8'h99: inv_sbox = 8'hF9; 8'h9A: inv_sbox = 8'h37; 8'h9B: inv_sbox = 8'hE8;
            8'h9C: inv_sbox = 8'h1C; 8'h9D: inv_sbox = 8'h75; 8'h9E: inv_sbox = 8'hDF; 8'h9F: inv_sbox = 8'h6E;

            8'hA0: inv_sbox = 8'h47; 8'hA1: inv_sbox = 8'hF1; 8'hA2: inv_sbox = 8'h1A; 8'hA3: inv_sbox = 8'h71;
            8'hA4: inv_sbox = 8'h1D; 8'hA5: inv_sbox = 8'h29; 8'hA6: inv_sbox = 8'hC5; 8'hA7: inv_sbox = 8'h89;
            8'hA8: inv_sbox = 8'h6F; 8'hA9: inv_sbox = 8'hB7; 8'hAA: inv_sbox = 8'h62; 8'hAB: inv_sbox = 8'h0E;
            8'hAC: inv_sbox = 8'hAA; 8'hAD: inv_sbox = 8'h18; 8'hAE: inv_sbox = 8'hBE; 8'hAF: inv_sbox = 8'h1B;

            8'hB0: inv_sbox = 8'hFC; 8'hB1: inv_sbox = 8'h56; 8'hB2: inv_sbox = 8'h3E; 8'hB3: inv_sbox = 8'h4B;
            8'hB4: inv_sbox = 8'hC6; 8'hB5: inv_sbox = 8'hD2; 8'hB6: inv_sbox = 8'h79; 8'hB7: inv_sbox = 8'h20;
            8'hB8: inv_sbox = 8'h9A; 8'hB9: inv_sbox = 8'hDB; 8'hBA: inv_sbox = 8'hC0; 8'hBB: inv_sbox = 8'hFE;
            8'hBC: inv_sbox = 8'h78; 8'hBD: inv_sbox = 8'hCD; 8'hBE: inv_sbox = 8'h5A; 8'hBF: inv_sbox = 8'hF4;

            8'hC0: inv_sbox = 8'h1F; 8'hC1: inv_sbox = 8'hDD; 8'hC2: inv_sbox = 8'hA8; 8'hC3: inv_sbox = 8'h33;
            8'hC4: inv_sbox = 8'h88; 8'hC5: inv_sbox = 8'h07; 8'hC6: inv_sbox = 8'hC7; 8'hC7: inv_sbox = 8'h31;
            8'hC8: inv_sbox = 8'hB1; 8'hC9: inv_sbox = 8'h12; 8'hCA: inv_sbox = 8'h10; 8'hCB: inv_sbox = 8'h59;
            8'hCC: inv_sbox = 8'h27; 8'hCD: inv_sbox = 8'h80; 8'hCE: inv_sbox = 8'hEC; 8'hCF: inv_sbox = 8'h5F;

            8'hD0: inv_sbox = 8'h60; 8'hD1: inv_sbox = 8'h51; 8'hD2: inv_sbox = 8'h7F; 8'hD3: inv_sbox = 8'hA9;
            8'hD4: inv_sbox = 8'h19; 8'hD5: inv_sbox = 8'hB5; 8'hD6: inv_sbox = 8'h4A; 8'hD7: inv_sbox = 8'h0D;
            8'hD8: inv_sbox = 8'h2D; 8'hD9: inv_sbox = 8'hE5; 8'hDA: inv_sbox = 8'h7A; 8'hDB: inv_sbox = 8'h9F;
            8'hDC: inv_sbox = 8'h93; 8'hDD: inv_sbox = 8'hC9; 8'hDE: inv_sbox = 8'h9C; 8'hDF: inv_sbox = 8'hEF;

            8'hE0: inv_sbox = 8'hA0; 8'hE1: inv_sbox = 8'hE0; 8'hE2: inv_sbox = 8'h3B; 8'hE3: inv_sbox = 8'h4D;
            8'hE4: inv_sbox = 8'hAE; 8'hE5: inv_sbox = 8'h2A; 8'hE6: inv_sbox = 8'hF5; 8'hE7: inv_sbox = 8'hB0;
            8'hE8: inv_sbox = 8'hC8; 8'hE9: inv_sbox = 8'hEB; 8'hEA: inv_sbox = 8'hBB; 8'hEB: inv_sbox = 8'h3C;
            8'hEC: inv_sbox = 8'h83; 8'hED: inv_sbox = 8'h53; 8'hEE: inv_sbox = 8'h99; 8'hEF: inv_sbox = 8'h61;

            8'hF0: inv_sbox = 8'h17; 8'hF1: inv_sbox = 8'h2B; 8'hF2: inv_sbox = 8'h04; 8'hF3: inv_sbox = 8'h7E;
            8'hF4: inv_sbox = 8'hBA; 8'hF5: inv_sbox = 8'h77; 8'hF6: inv_sbox = 8'hD6; 8'hF7: inv_sbox = 8'h26;
            8'hF8: inv_sbox = 8'hE1; 8'hF9: inv_sbox = 8'h69; 8'hFA: inv_sbox = 8'h14; 8'hFB: inv_sbox = 8'h63;
            8'hFC: inv_sbox = 8'h55; 8'hFD: inv_sbox = 8'h21; 8'hFE: inv_sbox = 8'h0C; 8'hFF: inv_sbox = 8'h7D;

            default: inv_sbox = 8'h00;
         endcase
      end
   endfunction

   // sbox lookup table (AES standard), taking from official NIST documentation
   function [7:0] sbox;
      input [7:0] in;
      begin
         case (in)
           8'h00: sbox = 8'h63; 8'h01: sbox = 8'h7c; 8'h02: sbox = 8'h77; 8'h03: sbox = 8'h7b;
           8'h04: sbox = 8'hf2; 8'h05: sbox = 8'h6b; 8'h06: sbox = 8'h6f; 8'h07: sbox = 8'hc5;
           8'h08: sbox = 8'h30; 8'h09: sbox = 8'h01; 8'h0a: sbox = 8'h67; 8'h0b: sbox = 8'h2b;
           8'h0c: sbox = 8'hfe; 8'h0d: sbox = 8'hd7; 8'h0e: sbox = 8'hab; 8'h0f: sbox = 8'h76;
           8'h10: sbox = 8'hca; 8'h11: sbox = 8'h82; 8'h12: sbox = 8'hc9; 8'h13: sbox = 8'h7d;
           8'h14: sbox = 8'hfa; 8'h15: sbox = 8'h59; 8'h16: sbox = 8'h47; 8'h17: sbox = 8'hf0;
           8'h18: sbox = 8'had; 8'h19: sbox = 8'hd4; 8'h1a: sbox = 8'ha2; 8'h1b: sbox = 8'haf;
           8'h1c: sbox = 8'h9c; 8'h1d: sbox = 8'ha4; 8'h1e: sbox = 8'h72; 8'h1f: sbox = 8'hc0;
           8'h20: sbox = 8'hb7; 8'h21: sbox = 8'hfd; 8'h22: sbox = 8'h93; 8'h23: sbox = 8'h26;
           8'h24: sbox = 8'h36; 8'h25: sbox = 8'h3f; 8'h26: sbox = 8'hf7; 8'h27: sbox = 8'hcc;
           8'h28: sbox = 8'h34; 8'h29: sbox = 8'ha5; 8'h2a: sbox = 8'he5; 8'h2b: sbox = 8'hf1;
           8'h2c: sbox = 8'h71; 8'h2d: sbox = 8'hd8; 8'h2e: sbox = 8'h31; 8'h2f: sbox = 8'h15;
           8'h30: sbox = 8'h04; 8'h31: sbox = 8'hc7; 8'h32: sbox = 8'h23; 8'h33: sbox = 8'hc3;
           8'h34: sbox = 8'h18; 8'h35: sbox = 8'h96; 8'h36: sbox = 8'h05; 8'h37: sbox = 8'h9a;
           8'h38: sbox = 8'h07; 8'h39: sbox = 8'h12; 8'h3a: sbox = 8'h80; 8'h3b: sbox = 8'he2;
           8'h3c: sbox = 8'heb; 8'h3d: sbox = 8'h27; 8'h3e: sbox = 8'hb2; 8'h3f: sbox = 8'h75;
           8'h40: sbox = 8'h09; 8'h41: sbox = 8'h83; 8'h42: sbox = 8'h2c; 8'h43: sbox = 8'h1a;
           8'h44: sbox = 8'h1b; 8'h45: sbox = 8'h6e; 8'h46: sbox = 8'h5a; 8'h47: sbox = 8'ha0;
           8'h48: sbox = 8'h52; 8'h49: sbox = 8'h3b; 8'h4a: sbox = 8'hd6; 8'h4b: sbox = 8'hb3;
           8'h4c: sbox = 8'h29; 8'h4d: sbox = 8'he3; 8'h4e: sbox = 8'h2f; 8'h4f: sbox = 8'h84;
           8'h50: sbox = 8'h53; 8'h51: sbox = 8'hd1; 8'h52: sbox = 8'h00; 8'h53: sbox = 8'hed;
           8'h54: sbox = 8'h20; 8'h55: sbox = 8'hfc; 8'h56: sbox = 8'hb1; 8'h57: sbox = 8'h5b;
           8'h58: sbox = 8'h6a; 8'h59: sbox = 8'hcb; 8'h5a: sbox = 8'hbe; 8'h5b: sbox = 8'h39;
           8'h5c: sbox = 8'h4a; 8'h5d: sbox = 8'h4c; 8'h5e: sbox = 8'h58; 8'h5f: sbox = 8'hcf;
           8'h60: sbox = 8'hd0; 8'h61: sbox = 8'hef; 8'h62: sbox = 8'haa; 8'h63: sbox = 8'hfb;
           8'h64: sbox = 8'h43; 8'h65: sbox = 8'h4d; 8'h66: sbox = 8'h33; 8'h67: sbox = 8'h85;
           8'h68: sbox = 8'h45; 8'h69: sbox = 8'hf9; 8'h6a: sbox = 8'h02; 8'h6b: sbox = 8'h7f;
           8'h6c: sbox = 8'h50; 8'h6d: sbox = 8'h3c; 8'h6e: sbox = 8'h9f; 8'h6f: sbox = 8'ha8;
           8'h70: sbox = 8'h51; 8'h71: sbox = 8'ha3; 8'h72: sbox = 8'h40; 8'h73: sbox = 8'h8f;
           8'h74: sbox = 8'h92; 8'h75: sbox = 8'h9d; 8'h76: sbox = 8'h38; 8'h77: sbox = 8'hf5;
           8'h78: sbox = 8'hbc; 8'h79: sbox = 8'hb6; 8'h7a: sbox = 8'hda; 8'h7b: sbox = 8'h21;
           8'h7c: sbox = 8'h10; 8'h7d: sbox = 8'hff; 8'h7e: sbox = 8'hf3; 8'h7f: sbox = 8'hd2;
           8'h80: sbox = 8'hcd; 8'h81: sbox = 8'h0c; 8'h82: sbox = 8'h13; 8'h83: sbox = 8'hec;
           8'h84: sbox = 8'h5f; 8'h85: sbox = 8'h97; 8'h86: sbox = 8'h44; 8'h87: sbox = 8'h17;
           8'h88: sbox = 8'hc4; 8'h89: sbox = 8'ha7; 8'h8a: sbox = 8'h7e; 8'h8b: sbox = 8'h3d;
           8'h8c: sbox = 8'h64; 8'h8d: sbox = 8'h5d; 8'h8e: sbox = 8'h19; 8'h8f: sbox = 8'h73;
           8'h90: sbox = 8'h60; 8'h91: sbox = 8'h81; 8'h92: sbox = 8'h4f; 8'h93: sbox = 8'hdc;
           8'h94: sbox = 8'h22; 8'h95: sbox = 8'h2a; 8'h96: sbox = 8'h90; 8'h97: sbox = 8'h88;
           8'h98: sbox = 8'h46; 8'h99: sbox = 8'hee; 8'h9a: sbox = 8'hb8; 8'h9b: sbox = 8'h14;
           8'h9c: sbox = 8'hde; 8'h9d: sbox = 8'h5e; 8'h9e: sbox = 8'h0b; 8'h9f: sbox = 8'hdb;
           8'ha0: sbox = 8'he0; 8'ha1: sbox = 8'h32; 8'ha2: sbox = 8'h3a; 8'ha3: sbox = 8'h0a;
           8'ha4: sbox = 8'h49; 8'ha5: sbox = 8'h06; 8'ha6: sbox = 8'h24; 8'ha7: sbox = 8'h5c;
           8'ha8: sbox = 8'hc2; 8'ha9: sbox = 8'hd3; 8'haa: sbox = 8'hac; 8'hab: sbox = 8'h62;
           8'hac: sbox = 8'h91; 8'had: sbox = 8'h95; 8'hae: sbox = 8'he4; 8'haf: sbox = 8'h79;
           8'hb0: sbox = 8'he7; 8'hb1: sbox = 8'hc8; 8'hb2: sbox = 8'h37; 8'hb3: sbox = 8'h6d;
           8'hb4: sbox = 8'h8d; 8'hb5: sbox = 8'hd5; 8'hb6: sbox = 8'h4e; 8'hb7: sbox = 8'ha9;
           8'hb8: sbox = 8'h6c; 8'hb9: sbox = 8'h56; 8'hba: sbox = 8'hf4; 8'hbb: sbox = 8'hea;
           8'hbc: sbox = 8'h65; 8'hbd: sbox = 8'h7a; 8'hbe: sbox = 8'hae; 8'hbf: sbox = 8'h08;
           8'hc0: sbox = 8'hba; 8'hc1: sbox = 8'h78; 8'hc2: sbox = 8'h25; 8'hc3: sbox = 8'h2e;
           8'hc4: sbox = 8'h1c; 8'hc5: sbox = 8'ha6; 8'hc6: sbox = 8'hb4; 8'hc7: sbox = 8'hc6;
           8'hc8: sbox = 8'he8; 8'hc9: sbox = 8'hdd; 8'hca: sbox = 8'h74; 8'hcb: sbox = 8'h1f;
           8'hcc: sbox = 8'h4b; 8'hcd: sbox = 8'hbd; 8'hce: sbox = 8'h8b; 8'hcf: sbox = 8'h8a;
           8'hd0: sbox = 8'h70; 8'hd1: sbox = 8'h3e; 8'hd2: sbox = 8'hb5; 8'hd3: sbox = 8'h66;
           8'hd4: sbox = 8'h48; 8'hd5: sbox = 8'h03; 8'hd6: sbox = 8'hf6; 8'hd7: sbox = 8'h0e;
           8'hd8: sbox = 8'h61; 8'hd9: sbox = 8'h35; 8'hda: sbox = 8'h57; 8'hdb: sbox = 8'hb9;
           8'hdc: sbox = 8'h86; 8'hdd: sbox = 8'hc1; 8'hde: sbox = 8'h1d; 8'hdf: sbox = 8'h9e;
           8'he0: sbox = 8'he1; 8'he1: sbox = 8'hf8; 8'he2: sbox = 8'h98; 8'he3: sbox = 8'h11;
           8'he4: sbox = 8'h69; 8'he5: sbox = 8'hd9; 8'he6: sbox = 8'h8e; 8'he7: sbox = 8'h94;
           8'he8: sbox = 8'h9b; 8'he9: sbox = 8'h1e; 8'hea: sbox = 8'h87; 8'heb: sbox = 8'he9;
           8'hec: sbox = 8'hce; 8'hed: sbox = 8'h55; 8'hee: sbox = 8'h28; 8'hef: sbox = 8'hdf;
           8'hf0: sbox = 8'h8c; 8'hf1: sbox = 8'ha1; 8'hf2: sbox = 8'h89; 8'hf3: sbox = 8'h0d;
           8'hf4: sbox = 8'hbf; 8'hf5: sbox = 8'he6; 8'hf6: sbox = 8'h42; 8'hf7: sbox = 8'h68;
           8'hf8: sbox = 8'h41; 8'hf9: sbox = 8'h99; 8'hfa: sbox = 8'h2d; 8'hfb: sbox = 8'h0f;
           8'hfc: sbox = 8'hb0; 8'hfd: sbox = 8'h54; 8'hfe: sbox = 8'hbb; 8'hff: sbox = 8'h16;
           default: sbox = 8'h00;
         endcase
      end
   endfunction

   // GF(2^8) multiplication
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
   endfunction

   task automatic do_subbytes;
      begin
         for (i = 0; i < 32; i = i + 1)
            state_next[i] = sbox(state[i]);
      end
   endtask

   // Shiftrows transformation for 256-bit block (4 rows x 8 columns)
   task automatic do_shiftrows;
      begin
         // row 0: no shift
         state_next[0]  = state[0];  state_next[4]  = state[4];
         state_next[8]  = state[8];  state_next[12] = state[12];
         state_next[16] = state[16]; state_next[20] = state[20];
         state_next[24] = state[24]; state_next[28] = state[28];
         // row 1: shift left by 1
         state_next[1]  = state[5];  state_next[5]  = state[9];
         state_next[9]  = state[13]; state_next[13] = state[17];
         state_next[17] = state[21]; state_next[21] = state[25];
         state_next[25] = state[29]; state_next[29] = state[1];
         // row 2: shift left by 3
         state_next[2]  = state[14]; state_next[6]  = state[18];
         state_next[10] = state[22]; state_next[14] = state[26];
         state_next[18] = state[30]; state_next[22] = state[2];
         state_next[26] = state[6];  state_next[30] = state[10];
         // row 3: shift left by 4
         state_next[3]  = state[19]; state_next[7]  = state[23];
         state_next[11] = state[27]; state_next[15] = state[31];
         state_next[19] = state[3];  state_next[23] = state[7];
         state_next[27] = state[11]; state_next[31] = state[15];
      end
   endtask

   task automatic do_mixcolumns;
      reg [7:0] s0, s1, s2, s3;
      begin
         for (i = 0; i < 8; i = i + 1) begin
            s0 = state[i*4];     s1 = state[i*4 + 1];
            s2 = state[i*4 + 2]; s3 = state[i*4 + 3];
            state_next[i*4]     = xtime(s0) ^ mul3(s1) ^ s2 ^ s3;
            state_next[i*4 + 1] = s0 ^ xtime(s1) ^ mul3(s2) ^ s3;
            state_next[i*4 + 2] = s0 ^ s1 ^ xtime(s2) ^ mul3(s3);
            state_next[i*4 + 3] = mul3(s0) ^ s1 ^ s2 ^ xtime(s3);
         end
      end
   endtask

   task automatic do_addroundkey;
      input integer round_num;
      begin
         for (i = 0; i < 32; i = i + 1)
            state_next[i] = state[i] ^ key_schedule[round_num * 32 + i];
      end
   endtask

   // FSM
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         state_fsm <= IDLE;
         busy <= 1'b0;
         done <= 1'b0;
         round <= 5'd0;
         ciphertext <= 256'd0;
         for (i = 0; i < 32; i = i + 1) begin
            state[i] <= 8'd0;
            state_next[i] <= 8'd0;
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
              do_addroundkey(0);
              for (i = 0; i < 32; i = i + 1)
                 state[i] <= state_next[i];
              round <= 5'd1;
              state_fsm <= SUB_BYTES;
           end

           SUB_BYTES: begin
              do_subbytes();
              for (i = 0; i < 32; i = i + 1)
                 state[i] <= state_next[i];
              state_fsm <= SHIFT_ROWS;
           end

           SHIFT_ROWS: begin
              do_shiftrows();
              for (i = 0; i < 32; i = i + 1)
                 state[i] <= state_next[i];
              state_fsm <= (round == Nrounds) ? ADD_ROUNDKEY : MIX_COLS;
           end

           MIX_COLS: begin
              do_mixcolumns();
              for (i = 0; i < 32; i = i + 1)
                 state[i] <= state_next[i];
              state_fsm <= ADD_ROUNDKEY;
           end

           ADD_ROUNDKEY: begin
              do_addroundkey(round);
              for (i = 0; i < 32; i = i + 1)
                 state[i] <= state_next[i];
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
