`timescale 1ns / 1ps

module apple(
    input clk,
    input btnrst,
    input [10:0] snakehead_x,
    input [10:0] snakehead_y,
    
    // Add these two lines:
    input [10:0] wallpos_x,
    input [10:0] wallpos_y,
    
    output [10:0] newapple_x,
    output [10:0] newapple_y
);

    localparam MIN_X = 11'd16;
    localparam MAX_X = 11'd1392;
    localparam MIN_Y = 11'd16;
    localparam MAX_Y = 11'd848;

    localparam INC_X = 11'd32; 
    localparam INC_Y = 11'd64;

    // Example internal registers for apple position
    reg [10:0] x, randx = 11'd48;  // or wherever you start
    reg [10:0] y, randy = 11'd16;  // or wherever you start

always @(posedge clk) begin
    if (btnrst) begin
        x <= 11'd48;
        y <= 11'd16;
    end else begin
        x <= x + INC_X;
        if (x > (MAX_X - INC_X)) begin
            x <= 11'd48;
        end

        y <= y + INC_Y;
        if (y > (MAX_Y - INC_Y)) begin
            y <= 11'd16;
        end

        // Optional: Check collision with wall and shift if needed
        if ((x == wallpos_x) && (y == wallpos_y)) begin
            x <= x + INC_X;
        end
    end
end


    assign newapple_x = x;
    assign newapple_y = y;
    
endmodule
