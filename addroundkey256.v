module addroundkey256 (
    input  [255:0] state_in,
    input  [255:0] roundkey,
    output [255:0] state_out
);
    assign state_out = state_in ^ roundkey;
endmodule
