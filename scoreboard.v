`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.01.2025 20:17:53
// Design Name: 
// Module Name: scoreboard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module scoreboard(
    input wire clk,
    input wire rst,
    input wire [5:0] points,  // From collisioncon 

    // Outputs to pass into drawcon
    output reg [5:0] scoreboardCount,          // How many score apples to display
    output reg [10:0] scoreboardX [0:15],      // X positions of each scoreboard apple
    output reg [10:0] scoreboardY [0:15]       // Y positions of each scoreboard apple
);

parameter MAX_SCORE           = 16;   // Maximum scoreboard apples
parameter SCORE_START_X       = 20;   // Where to place the first apple
parameter SCORE_START_Y       = 20;
parameter SCORE_APPLE_SPACING = 40;   // Horizontal gap between scoreboard apples

// Internally track the old points to detect increments
reg [5:0] oldPoints;
integer i;

initial begin
    scoreboardCount = 0;
    oldPoints       = 0;

    // Pre-fill scoreboard positions so we know where each apple
    // should appear whenever scoreboardCount increments.
    for (i = 0; i < MAX_SCORE; i = i + 1) begin
        scoreboardX[i] = SCORE_START_X + i * SCORE_APPLE_SPACING;
        scoreboardY[i] = SCORE_START_Y;
    end
end

always @(posedge clk) begin
    if (rst) begin
        scoreboardCount <= 0;
        oldPoints       <= 0;
    end else begin
        // Detect when points increments
        if (points > oldPoints) begin
            // Example: if points jumps from 3 to 5, scoreboardCount increments by 2
            scoreboardCount <= scoreboardCount + (points - oldPoints);
        end
        oldPoints <= points;
    end
end

endmodule
