`timescale 1ns / 1ps

module Wall(
    input clk,
    input btnrst,
    input [10:0] snakehead_x,
    input [10:0] snakehead_y,
    
    output [10:0] newwall_x,
    output [10:0] newwall_y
);

    // Example tile size = 32
    localparam TILE_SIZE  = 11'd32;
    
    // Example playing area (must match your VGA resolution / game design):
    // Let's say X from 16 to 1392, Y from 16 to 848 
    // (this is 44 tiles horizontally and 26 tiles vertically).
    localparam MIN_X = 11'd16;   // left boundary
    localparam MAX_X = 11'd1392; // right boundary
    localparam MIN_Y = 11'd16;   // top boundary
    localparam MAX_Y = 11'd848;  // bottom boundary

    // Use different increments than the apple so they don't track each other
    localparam INC_X = 11'd64; 
    localparam INC_Y = 11'd32;

    reg [10:0] x, y;

    // Reset the wall inside the valid area
    always @(posedge clk) begin
        if (btnrst) begin
            x <= MIN_X;  // Start somewhere valid
            y <= 11'd144; // Another valid start
        end 
        else begin
            // Move X by INC_X each step 
            x <= x + INC_X;
            
            // If X goes beyond MAX_X, wrap around to MIN_X
            if (x > (MAX_X - INC_X)) begin
                x <= MIN_X;
            end

            // Move Y by INC_Y each step
            y <= y + INC_Y;
            
            // If Y goes beyond MAX_Y, wrap around to MIN_Y
            if (y > (MAX_Y - INC_Y)) begin
                y <= 11'd144; // or MIN_Y, if you want a consistent wrap
            end
        end
    end

    assign newwall_x = x;
    assign newwall_y = y;
endmodule