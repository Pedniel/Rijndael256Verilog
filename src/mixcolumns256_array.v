module mixcolumns256_array (
    input [7:0]  state_in[0:31],
    output [7:0] state_out[0:31]
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
        for (i = 0; i < 8; i = i + 1) begin : mixcol_loop
            assign state_out[i*4]     = xtime(state_in[i*4])   ^ mul3(state_in[i*4+1]) ^
                                        state_in[i*4+2]        ^ state_in[i*4+3];
            assign state_out[i*4 + 1] = state_in[i*4]          ^ xtime(state_in[i*4+1]) ^
                                        mul3(state_in[i*4+2])  ^ state_in[i*4+3];
            assign state_out[i*4 + 2] = state_in[i*4]          ^ state_in[i*4+1] ^
                                        xtime(state_in[i*4+2]) ^ mul3(state_in[i*4+3]);
            assign state_out[i*4 + 3] = mul3(state_in[i*4])    ^ state_in[i*4+1] ^
                                        state_in[i*4+2]        ^ xtime(state_in[i*4+3]);
        end
    endgenerate

endmodule
