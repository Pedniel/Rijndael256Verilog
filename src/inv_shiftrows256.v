// Create diffusion by mixing bytes
// Inverse is just a shifting in the opposite direction as before
module inv_shiftrows256 (
    input wire [255:0] state_in,
    output wire [255:0] state_out
);
    // follow  same byte ordering as your main module
    // state_in[255:248] = state[0], state_in[247:240] = state[1], etc.
    
   assign state_out[255 - 0*8 -: 8] = state_in[255 - 0*8 -: 8];   
    assign state_out[255 - 4*8 -: 8] = state_in[255 - 4*8 -: 8];  
    assign state_out[255 - 8*8 -: 8] = state_in[255 - 8*8 -: 8];  
    assign state_out[255 - 12*8 -: 8] = state_in[255 - 12*8 -: 8];
    assign state_out[255 - 16*8 -: 8] = state_in[255 - 16*8 -: 8];
    assign state_out[255 - 20*8 -: 8] = state_in[255 - 20*8 -: 8];
    assign state_out[255 - 24*8 -: 8] = state_in[255 - 24*8 -: 8];
    assign state_out[255 - 28*8 -: 8] = state_in[255 - 28*8 -: 8];
    
// shift by 1
    assign state_out[255 - 1*8 -: 8] = state_in[255 - 5*8 -: 8];   
    assign state_out[255 - 5*8 -: 8] = state_in[255 - 9*8 -: 8];   
    assign state_out[255 - 9*8 -: 8] = state_in[255 - 13*8 -: 8];  
    assign state_out[255 - 13*8 -: 8] = state_in[255 - 17*8 -: 8]; 
    assign state_out[255 - 17*8 -: 8] = state_in[255 - 21*8 -: 8]; 
    assign state_out[255 - 21*8 -: 8] = state_in[255 - 25*8 -: 8]; 
    assign state_out[255 - 25*8 -: 8] = state_in[255 - 29*8 -: 8]; 
    assign state_out[255 - 29*8 -: 8] = state_in[255 - 1*8 -: 8];  
    
    // Row 2: Shift left by 3
    assign state_out[255 - 2*8 -: 8] = state_in[255 - 14*8 -: 8];  
    assign state_out[255 - 6*8 -: 8] = state_in[255 - 18*8 -: 8];  
    assign state_out[255 - 10*8 -: 8] = state_in[255 - 22*8 -: 8]; 
    assign state_out[255 - 14*8 -: 8] = state_in[255 - 26*8 -: 8]; 
    assign state_out[255 - 18*8 -: 8] = state_in[255 - 30*8 -: 8]; 
    assign state_out[255 - 22*8 -: 8] = state_in[255 - 2*8 -: 8];  
    assign state_out[255 - 26*8 -: 8] = state_in[255 - 6*8 -: 8];  
    assign state_out[255 - 30*8 -: 8] = state_in[255 - 10*8 -: 8]; 
    
    // Row 3: Shift left by 4
    assign state_out[255 - 3*8 -: 8] = state_in[255 - 19*8 -: 8];  
    assign state_out[255 - 7*8 -: 8] = state_in[255 - 23*8 -: 8];  
    assign state_out[255 - 11*8 -: 8] = state_in[255 - 27*8 -: 8]; 
    assign state_out[255 - 15*8 -: 8] = state_in[255 - 31*8 -: 8]; 
    assign state_out[255 - 19*8 -: 8] = state_in[255 - 3*8 -: 8];  
    assign state_out[255 - 23*8 -: 8] = state_in[255 - 7*8 -: 8];  
    assign state_out[255 - 27*8 -: 8] = state_in[255 - 11*8 -: 8]; 
    assign state_out[255 - 31*8 -: 8] = state_in[255 - 15*8 -: 8]; 
endmodule
