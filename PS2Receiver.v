`timescale 1ns / 1ps



module PS2Receiver(
    input clk,
    input kclk,
    input kdata,
    output [31:0] keycodeout,
//Chinua changes 
    output reg up,     //Direction signal: UP
    output reg down,     //Direction signal: DOWN    
    output reg left,     //Direction signal: LEFT
    output reg right     //Direction signal: RIGHT
    );
    
    
    wire kclkf, kdataf;
    reg [7:0]datacur;
    reg [7:0]dataprev;
    reg [3:0]cnt;
    reg [31:0]keycode;
    reg flag;
    
    initial begin
        keycode[31:0]<=0'h00000000;
        cnt<=4'b0000;
        flag<=1'b0;
        up <= 0;    
        down <= 0;    
        left <= 0;
        right <= 0;
    end
    
debouncer debounce(
    .clk(clk),
    .I0(kclk),
    .I1(kdata),
    .O0(kclkf),
    .O1(kdataf)
);
    
always@(negedge(kclkf))begin
    case(cnt)
    0:;//Start bit
    1:datacur[0]<=kdataf;
    2:datacur[1]<=kdataf;
    3:datacur[2]<=kdataf;
    4:datacur[3]<=kdataf;
    5:datacur[4]<=kdataf;
    6:datacur[5]<=kdataf;
    7:datacur[6]<=kdataf;
    8:datacur[7]<=kdataf;
    9:flag<=1'b1;
    10:flag<=1'b0;
    
    endcase
        if(cnt<=9) cnt<=cnt+1;
        else if(cnt==10) cnt<=0;
        
end

always @(posedge flag)begin
    if (dataprev!=datacur)begin
        keycode[31:24]<=keycode[23:16];
        keycode[23:16]<=keycode[15:8];
        keycode[15:8]<=dataprev;
        keycode[7:0]<=datacur;
        dataprev<=datacur;
    end
end

// Case statement to map scancodes to directional signals
    always @(keycode) begin
        // Reset all directional signals
        up <= 0;
        down <= 0;
        left <= 0;
        right <= 0;

        case (keycode[7:0])  // Checking only the lower byte (the actual scancode)
            8'h1D: up <= 1;    // W key - UP
            8'h1C: left <= 1;  // A key - LEFT
            8'h1B: down <= 1;  // S key - DOWN
            8'h23: right <= 1; // D key - RIGHT
            default: ;         // No change for other keys
        endcase
    end

    assign keycodeout=keycode;


    
endmodule