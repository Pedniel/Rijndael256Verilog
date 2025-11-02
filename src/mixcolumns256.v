module mixcolumns256 (
    input wire [255:0] state_in,
    output wire [255:0] state_out
);

    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    function [7:0] mul3;
        input [7:0] b;
        begin
            mul3 = xtime(b) ^ b;
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : mix_cols
            wire [7:0] s0 = state_in[255 - (i*4+0)*8 -: 8];
            wire [7:0] s1 = state_in[255 - (i*4+1)*8 -: 8];
            wire [7:0] s2 = state_in[255 - (i*4+2)*8 -: 8];
            wire [7:0] s3 = state_in[255 - (i*4+3)*8 -: 8];
            
            assign state_out[255 - (i*4+0)*8 -: 8] = xtime(s0) ^ mul3(s1) ^ s2 ^ s3;
            assign state_out[255 - (i*4+1)*8 -: 8] = s0 ^ xtime(s1) ^ mul3(s2) ^ s3;
            assign state_out[255 - (i*4+2)*8 -: 8] = s0 ^ s1 ^ xtime(s2) ^ mul3(s3);
            assign state_out[255 - (i*4+3)*8 -: 8] = mul3(s0) ^ s1 ^ s2 ^ xtime(s3);
        end
    endgenerate
endmodule
