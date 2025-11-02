// ============================================================================
// Testbench
// ============================================================================

// ALL TEST VECTORS ARE GENERATED WITH THE test_vectors.py SCRIPT
// THIS IS A SOFTWARE 32 BYTE BLOCK SIZE RIJNDAEL IMPLEMENTATION, USED TO COMPARE WITH THIS HARDWARE IMPLEMENTATION
module rijndael256_ctr_tb_roundtrip;
   reg clk;
   reg rst_n;
   reg start;
   reg [255:0] nonce;
   reg [255:0] data_in;
   reg key_mode;           // 0 = 192-bit, 1 = 256-bit
   reg [191:0] key;
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
   reg [255:0] encrypted_data [0:3];
   reg [255:0] test_nonces [0:3];
   integer test_num;
   
   initial begin
      rst_n = 0;
      start = 0;
      nonce = 256'h0;
      data_in = 256'h0;
      key = 192'h0;
      key_mode = 0;
      test_num = 0;
      
      // Dump waveforms
      // Could be insteresting for side channel analysis or different scripts
/* -----\/----- EXCLUDED -----\/-----
      $dumpfile("rijndael256_ctr.vcd");
      $dumpvars(0, rijndael256_ctr_tb);
 -----/\----- EXCLUDED -----/\----- */
      
      #20;
      rst_n = 1;
      #20;
      
      $display("========================================");
      $display("Rijndael-256 CTR Mode Testbench");
      $display("========================================\n");
      
      $display("Test 1: All zeros with 192-bit key");
      key_mode = 0;  // 192-bit key
      key = 192'h0;
      nonce = 256'h0;
      data_in = 256'h0;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[0] = data_out;
      test_nonces[0] = nonce;
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Plaintext: %064h", data_in);
      $display("Ciphertext:%064h", data_out);
      $display("");
      
      #100;
      
      $display("Test 2: Pattern with 192-bit key");
      key_mode = 0;
      key = 192'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;  // 192 bits
      nonce = 256'h1000000000000000000000000000000000000000000000000000000000000000;
      data_in = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[1] = data_out;
      test_nonces[1] = nonce;
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Plaintext: %064h", data_in);
      $display("Ciphertext:%064h", data_out);
      $display("");
      
      #100;

      $display("========================================");
      $display("CTR Mode Round-trip Verification");
      $display("========================================\n");
      
      // Test 3: CTR decrypt = encrypt  ?
      $display("Test 3: Round-trip verification of Test 1");
      key_mode = 0;
      key = 192'h0;
      nonce = test_nonces[0]; 
      data_in = encrypted_data[0];
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Input:     %064h (encrypted data)", data_in);
      $display("Output:    %064h (should be original plaintext)", data_out);
      if (data_out == 256'h0) begin
         $display("✓ SUCCESS: CTR decryption matches original plaintext!");
      end else begin
         $display("✗ FAIL: CTR decryption does not match original plaintext!");
      end
      $display("");
      
      #100;
      
      // Test 4: Verify Test 2 can be decrypted
      $display("Test 4: Round-trip verification of Test 2");
      key_mode = 0;
      key = 192'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
      nonce = test_nonces[1];  
      data_in = encrypted_data[1];  
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("Key:       %048h", key[191:0]);
      $display("Nonce:     %064h", nonce);
      $display("Input:     %064h (encrypted data)", data_in);
      $display("Output:    %064h (should be original plaintext)", data_out);
      if (data_out == 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) begin
         $display("SUCCESS: CTR decryption matches original plaintext!");
      end else begin
         $display("FAIL: CTR decryption does not match original plaintext!");
      end
      $display("");
      
      #100;
      
      $display("========================================");
      $display("All tests completed!");
      $display("========================================");
      
      #100;
      $finish;
   end
   
// watchdog
   initial begin
      #100000;
      $display("ERROR: Simulation timeout!");
      $finish;
   end
   
   initial begin
      $monitor("Time=%0t | busy=%b done=%b | data_out=%h", 
               $time, busy, done, data_out);
   end

endmodule // rijndael256_ctr_tb

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
   end
endmodule
      
// ============================================================================
// Testbench for Rijndael-256 ECB Mode
// ============================================================================
module rijndael256_ecb_tb;
   reg clk;
   reg rst_n;
   reg start;
   reg enc_dec;           // 0=encrypt, 1=decrypt
   reg [255:0] data_in;
   reg key_mode;          // 0 = 192-bit, 1 = 256-bit
   reg [255:0] key;
   wire [255:0] data_out;
   wire busy;
   wire done;

   // Instantiate ECB core
   rijndael256_top dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .enc_dec(enc_dec),
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

   reg [255:0] encrypted_data [0:3];
   integer test_num;

   initial begin
      rst_n = 0;
      start = 0;
      enc_dec = 0;
      data_in = 256'h0;
      key = 256'h0;
      key_mode = 0;
      test_num = 0;
      
      // Dump waveforms
      $dumpfile("rijndael256_ecb.vcd");
      $dumpvars(0, rijndael256_ecb_tb);
      
      #20;
      rst_n = 1;
      #20;
      
      $display("========================================");
      $display("Rijndael-256 ECB Mode Testbench");
      $display("========================================\n");
      
      // Test 1: All zeros with 192-bit key (Encryption)
      $display("Test %0d: All zeros encryption with 192-bit key", test_num+1);
      key_mode = 0;  // 192-bit key
      key = 256'h0;
      data_in = 256'h0;
      enc_dec = 0; 
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[test_num] = data_out;
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 2: Pattern with 192-bit key enc
      $display("Test %0d: Pattern encryption with 192-bit key", test_num+1);
      key_mode = 0;
      key = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;  // 192 bits
      data_in = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      enc_dec = 0;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[test_num] = data_out;
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 3: Random data with 192-bit key enc
      $display("Test %0d: Random data encryption with 192-bit key", test_num+1);
      key_mode = 0;
      key = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
      data_in = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF;
      enc_dec = 0;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[test_num] = data_out;
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 4: 256-bit key mode (Encryption)
      $display("Test %0d: 256-bit key encryption", test_num+1);
      key_mode = 1;  // 256-bit key
      key = 256'h0F1E2D3C4B5A69788796A5B4C3D2E1F00F1E2D3C4B5A69788796A5B4C3D2E1F0;
      data_in = 256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
      enc_dec = 0;
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      encrypted_data[test_num] = data_out;
      #10;
      
      $display("  Key:        %064h", key);
      $display("  Plaintext:  %064h", data_in);
      $display("  Ciphertext: %064h", data_out);
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // ======================================================================
      // DECRYPTION TESTS - Verify we can decrypt what we encrypted
      // ======================================================================
      
      $display("========================================");
      $display("Decryption Tests (Round-trip verification)");
      $display("========================================\n");
      
      // Test 5: Decrypt Test 1 result
      $display("Test %0d: Decrypt Test 1 result", test_num+1);
      key_mode = 0;
      key = 256'h0;
      data_in = encrypted_data[0];  // use encrypted result from Test 1
      enc_dec = 1;   // Decryption
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Ciphertext: %064h", data_in);
      $display("  Plaintext:  %064h", data_out);
      if (data_out == 256'h0) begin
         $display("  SUCCESS: Decryption matches original plaintext!");
      end else begin
         $display("  FAIL: Decryption does not match original plaintext!");
      end
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 6: Decrypt Test 2 result
      $display("Test %0d: Decrypt Test 2 result", test_num+1);
      key_mode = 0;
      key = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
      data_in = encrypted_data[1];  // Use encrypted result from Test 2
      enc_dec = 1;   // Decryption
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Ciphertext: %064h", data_in);
      $display("  Plaintext:  %064h", data_out);
      if (data_out == 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) begin
         $display("  SUCCESS: Decryption matches original plaintext!");
      end else begin
         $display("  FAIL: Decryption does not match original plaintext!");
      end
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 7: Decrypt Test 3 result
      $display("Test %0d: Decrypt Test 3 result", test_num+1);
      key_mode = 0;
      key = 256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
      data_in = encrypted_data[2];  // Use encrypted result from Test 3
      enc_dec = 1;   // Decryption
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Ciphertext: %064h", data_in);
      $display("  Plaintext:  %064h", data_out);
      if (data_out == 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF) begin
         $display("   SUCCESS: Decryption matches original plaintext!");
      end else begin
         $display("  FAIL: Decryption does not match original plaintext!");
      end
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // Test 8: Decrypt Test 4 result
      $display("Test %0d: Decrypt Test 4 result", test_num+1);
      key_mode = 1;
      key = 256'h0F1E2D3C4B5A69788796A5B4C3D2E1F00F1E2D3C4B5A69788796A5B4C3D2E1F0;
      data_in = encrypted_data[3];  // Use encrypted result from Test 4
      enc_dec = 1;   // Decryption
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("  Key:        %064h", key);
      $display("  Ciphertext: %064h", data_in);
      $display("  Plaintext:  %064h", data_out);
      if (data_out == 256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF) begin
         $display("  SUCCESS: Decryption matches original plaintext!");
      end else begin
         $display("  FAIL: Decryption does not match original plaintext!");
      end
      $display("");
      test_num = test_num + 1;
      
      #100;
      
      // ======================================================================
      // ADDITIONAL DECRYPTION-ONLY TEST
      // ======================================================================
      
      $display("Test %0d: Direct decryption without prior encryption", test_num+1);
      key_mode = 0;
      key = 256'h000102030405060708090A0B0C0D0E0F1011121314151617;  // 192-bit key
      data_in = 256'hAAC1D43C8A7C8B511C7F7F5E8E9B7A8B8A7C8B511C7F7F5E8E9B7A8B8A7C8B51;
      enc_dec = 1;   // Decryption
      
      start = 1;
      #10;
      start = 0;
      
      wait(done);
      #10;
      
      $display("  Key:        %048h", key[191:0]);
      $display("  Ciphertext: %064h", data_in);
      $display("  Plaintext:  %064h", data_out);
      // Note: This is just to see what we get, we don't have the expected plaintext
      $display("  Note: This tests standalone decryption capability");
      $display("");
      
      #100;
      
      $display("========================================");
      $display("All %0d tests completed!", test_num);
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
   
   initial begin
      $monitor("Time=%0t | start=%b enc_dec=%b busy=%b done=%b", 
               $time, start, enc_dec, busy, done);
   end

endmodule
