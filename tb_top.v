// ============================================================================
// Testbench
// ============================================================================
module rijndael256_ctr_tb;
   reg clk;
   reg rst_n;
   reg start;
   reg [255:0] nonce;
   reg [255:0] data_in;
   reg key_mode;           // 0 = 192-bit, 1 = 256-bit
   reg [255:0] key;
   wire [255:0] data_out;
   wire busy;
   wire done;
   // Instantiate CTR mode, which is a wrapper around ECB mode

   rijndael256_ctr dut (
                        .clk(clk),
                        .rst_n(rst_n),
                        .start(start),
                        .nonce(nonce),
                        .data_in(data_in),
                        .key_mode(key_mode),
                        .key(key),
                        .data_out(data_out),
                        .busy(busy),
                        .done(done)
                        );

   // 100 MHz clock
   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end

   initial begin
      rst_n = 0;
      start = 0;
      nonce = 256'h0;
      data_in = 256'h0;
      key = 256'h0;
      key_mode = 0;
      
      // Dump waveforms
      // Could be insteresting for side channel analysis or different scripts
      $dumpfile("rijndael256_ctr.vcd");
      $dumpvars(0, rijndael256_ctr_tb);
      
      #20;
      rst_n = 1;
      #20;
      
      $display("========================================");
      $display("Rijndael-256 CTR Mode Testbench");
      $display("========================================\n");
      
      $display("Test 1: All zeros with 192-bit key");
      key_mode = 0;  // 192-bit key
      key = 256'h0;
      nonce = 256'h0;
      data_in = 256'h0;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Plaintext: %064h", data_in);
      $display("Ciphertext:%064h", data_out);
      $display("");
      
      #100;
      
      $display("Test 2: Pattern with 192-bit key");
      key_mode = 0;
      key = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;  // 192 bits
      nonce = 256'h1000000000000000000000000000000000000000000000000000000000000000;
      data_in = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Plaintext: %064h", data_in);
      $display("Ciphertext:%064h", data_out);
      $display("");
      
      #100;
      
      $display("Test 3: Multi-block (counter increment)");
      key_mode = 0;
      key = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
      nonce = 256'h0000000000000000000000000000000000000000000000000000000000000001;
      
      // Block 1
      data_in = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
      start = 1;
      #10;
      start = 0;
      wait(done);
      #10;
      
      $display("Block 1:");
      $display("  Counter:    %064h", nonce);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      
      #100;
      
      // Block 2 (counter should auto-increment in CTR module)
      nonce = nonce + 1;  // Manually increment for test
      data_in = 256'hFFEEDDCCBBAA99887766554433221100FFEEDDCCBBAA99887766554433221100;
      start = 1;
      #10;
      start = 0;
      wait(done);
      #10;
      
      $display("Block 2:");
      $display("  Counter:    %064h", nonce);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      $display("");
      
      #100;
      
/* -----\/----- EXCLUDED -----\/-----
      // Test 4: 256-bit key mode
      $display("Test 4: 256-bit key mode");
      key_mode = 1;  // 256-bit key
      key = 256'h0F1E2D3C4B5A69788796A5B4C3D2E1F00F1E2D3C4B5A69788796A5B4C3D2E1F0;
      nonce = 256'h5000000000000000000000000000000000000000000000000000000000000000;
      data_in = 256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
      
      start = 1;
      #10;
      start = 0;
      wait(done);
      #10;
      
      $display("Key:       %064h", key);
      $display("Nonce:     %064h", nonce);
      $display("Plaintext: %064h", data_in);
      $display("Ciphertext:%064h", data_out);
      $display("");
      
      #100;
 -----/\----- EXCLUDED -----/\----- */
      
      $display("========================================");
      $display("All tests completed!");
      $display("========================================");
      
      #100;
      $finish;
   end
   
   // Timeout watchdog
   initial begin
      #100000;
      $display("ERROR: Simulation timeout!");
      $finish;
   end
   
   // Monitor busy/done signals
   initial begin
      $monitor("Time=%0t | busy=%b done=%b | data_out=%h", 
               $time, busy, done, data_out);
   end

endmodule // rijndael256_tb

/* -----\/----- EXCLUDED -----\/-----
// ECB mode testbench   
 
   // Instantiate DUT, this would be ECB mode!
   rijndael256_top dut (
                        .clk(clk),
                        .rst_n(rst_n),
                        .start(start),
                        .plaintext(plaintext),
                        .key_mode(key_mode),
                        .key(key),
                        .ciphertext(ciphertext),
                        .busy(busy),
                        .done(done)
                        );

   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end

   initial begin
      $dumpfile("rijndael256.vcd");
      $dumpvars(0, rijndael256_tb);

      rst_n = 0;
      start = 0;
      plaintext = 256'h0;
      key = 256'h0;
      
      #20;
      rst_n = 1;
      #20;

      $display("\n========================================");
      $display("Test 1: All-zero plaintext and key");
      $display("========================================");
      plaintext = 256'h00000000000000000000000000000000000000000000000000000000000000000;
      key =       256'h00000000000000000000000000000000000000000000000000000000000000000;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Plaintext:  %h", plaintext);
      $display("Key:        %h", key);
      $display("Ciphertext: %h", ciphertext);
      
      #100;

      $display("\n========================================");
      $display("Test 2: Pattern plaintext and key");
      $display("========================================");
      plaintext = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
      key =       256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Plaintext:  %h", plaintext);
      $display("Key:        %h", key);
      $display("Ciphertext: %h", ciphertext);
      
      #100;

      $display("\n========================================");
      $display("Test 3: All-ones plaintext and key");
      $display("========================================");
      plaintext = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      key =       256'603DEB1015CA71BE2B73AEF0857D77811F352C073B6108D72D9810A30914DFF4;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Plaintext:  %h", plaintext);
      $display("Key:        %h", key);
      $display("Ciphertext: %h", ciphertext);
      
      #100;

      $display("\n========================================");
      $display("All tests completed!");
      $display("========================================\n");
      
      $finish;
   end

   // Timeout watchdog
   initial begin
      #50000;
      $display("ERROR: Simulation timeout!");
      $finish;
   end
   
endmodule
 -----/\----- EXCLUDED -----/\----- */
