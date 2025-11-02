module inv_mixcolumns256 (
    input  [255:0] state_in,
    output [255:0] state_out
);
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction
    
    function [7:0] mul9;
        input [7:0] b;
        reg [7:0] t;
        begin
            t = xtime(b);
            t = xtime(t);
            t = xtime(t);
            mul9 = t ^ b;
        end
    endfunction
    
    function [7:0] mul11;
        input [7:0] b;
        reg [7:0] t2, t4, t8;
        begin
            t2 = xtime(b);
            t4 = xtime(t2);
            t8 = xtime(t4);
            mul11 = t8 ^ t2 ^ b;
        end
    endfunction
    
    function [7:0] mul13;
        input [7:0] b;
        reg [7:0] t2, t4, t8;
        begin
            t2 = xtime(b);
            t4 = xtime(t2);
            t8 = xtime(t4);
            mul13 = t8 ^ t4 ^ b;
        end
    endfunction
    
    function [7:0] mul14;
        input [7:0] b;
        reg [7:0] t2, t4, t8;
        begin
            t2 = xtime(b);
            t4 = xtime(t2);
            t8 = xtime(t4);
            mul14 = t8 ^ t4 ^ t2;
        end
    endfunction
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : mixcol_loop
            wire [7:0] s0, s1, s2, s3;
            
            assign s0 = state_in[i*32 +: 8];
            assign s1 = state_in[i*32 + 8 +: 8];
            assign s2 = state_in[i*32 + 16 +: 8];
            assign s3 = state_in[i*32 + 24 +: 8];
            
            assign state_out[i*32 +: 8]      = mul14(s0) ^ mul11(s1) ^ mul13(s2) ^ mul9(s3);
            assign state_out[i*32 + 8 +: 8]  = mul9(s0)  ^ mul14(s1) ^ mul11(s2) ^ mul13(s3);
            assign state_out[i*32 + 16 +: 8] = mul13(s0) ^ mul9(s1)  ^ mul14(s2) ^ mul11(s3);
            assign state_out[i*32 + 24 +: 8] = mul11(s0) ^ mul13(s1) ^ mul9(s2)  ^ mul14(s3);
        end
    endgenerate
endmodule
