module drawcon(
    input clk,
    input rst,
    input [252:0] snakepos_x,
    input [252:0] snakepos_y,
    input [5:0] length,
    input [10:0] applepos_x,
    input [10:0] applepos_y,
    input [10:0] wallpos_x,
    input [10:0] wallpos_y,
    input [53:0] direction,
    input [10:0] curr_x,
    input [10:0] curr_y,
    input lose,
    input win,
    input [5:0] points, // Score input from collisioncon
    output reg [3:0] draw_r,
    output reg [3:0] draw_g,
    output reg [3:0] draw_b
);

    // Parameters
    parameter SCREEN_WIDTH = 1440;
    parameter SCREEN_HEIGHT = 900;
    parameter APPLE_WIDTH = 32;
    parameter APPLE_HEIGHT = 32;
    parameter SCORE_X_OFFSET = 20; // Apples start 20 pixels from the left
    parameter SCORE_Y_OFFSET = 20; // Apples rendered 20 pixels from the top

    // Apple rendering logic for score
    reg placed_apple;
    reg [5:0] apple_index;

    always @(posedge clk) begin
        placed_apple <= 0;

        // Render static apples for the score
        for (apple_index = 0; apple_index < points; apple_index = apple_index + 1) begin
            if ((curr_x >= SCORE_X_OFFSET + apple_index * APPLE_WIDTH) &&
                (curr_x < SCORE_X_OFFSET + apple_index * APPLE_WIDTH + APPLE_WIDTH) &&
                (curr_y >= SCORE_Y_OFFSET) &&
                (curr_y < SCORE_Y_OFFSET + APPLE_HEIGHT)) begin
                placed_apple <= 1;
            end
        end
    end

    // Combine apple rendering with other game elements
    always @* begin
        if (placed_apple) begin
            draw_r = 4'b1111; // Red
            draw_g = 4'b0000;
            draw_b = 4'b0000;
        end else begin
            // Handle rendering for snake, walls, and the game apple
        end
    end
endmodule
