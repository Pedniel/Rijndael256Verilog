// ============================================================================
// Testbench
// ============================================================================
module rijndael256_tb;

   reg clk;
   reg rst_n;
   reg start;
   reg [255:0] plaintext;
   reg [255:0] key;
   wire [255:0] ciphertext;
   wire busy;
   wire done;

   // Instantiate DUT
   rijndael256_top dut (
                        .clk(clk),
                        .rst_n(rst_n),
                        .start(start),
                        .plaintext(plaintext),
                        .key(key),
                        .ciphertext(ciphertext),
                        .busy(busy),
                        .done(done)
                        );

   // Clock generation
   initial begin
      clk = 0;
      forever #5 clk = ~clk;
   end

   // Test sequence
   initial begin
      $dumpfile("rijndael256.vcd");
      $dumpvars(0, rijndael256_tb);

      // Initialize
      rst_n = 0;
      start = 0;
      plaintext = 256'h0;
      key = 256'h0;
      
      #20;
      rst_n = 1;
      #20;

      // ============================================================
      // Test 1: All zeros
      // ============================================================
      $display("\n========================================");
      $display("Test 1: All-zero plaintext and key");
      $display("========================================");
      plaintext = 256'h00000000000000000000000000000000000000000000000000000000000000000;
      key =       256'h00000000000000000000000000000000000000000000000000000000000000000;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      // Wait for completion
      wait(done);
      #10;
      
      $display("Plaintext:  %h", plaintext);
      $display("Key:        %h", key);
      $display("Ciphertext: %h", ciphertext);
      
      #100;

      // ============================================================
      // Test 2: Pattern test
      // ============================================================
      $display("\n========================================");
      $display("Test 2: Pattern plaintext and key");
      $display("========================================");
      plaintext = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
      key =       256'hFEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      // Wait for completion
      wait(done);
      #10;
      
      $display("Plaintext:  %h", plaintext);
      $display("Key:        %h", key);
      $display("Ciphertext: %h", ciphertext);
      
      #100;

      // ============================================================
      // Test 3: All ones
      // ============================================================
      $display("\n========================================");
      $display("Test 3: All-ones plaintext and key");
      $display("========================================");
      plaintext = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      key =       256'603DEB1015CA71BE2B73AEF0857D77811F352C073B6108D72D9810A30914DFF4;
      
      #10;
      start = 1;
      #10;
      start = 0;
      
      // Wait for completion
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
