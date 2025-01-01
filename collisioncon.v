`timescale 1ns / 1ps

module collisioncon(
    input clk,       
    input reset,
    
    input [10:0] applepos_x,
    input [10:0] applepos_y,
    
    input [10:0] wallpos_x,
    input [10:0] wallpos_y,
    
    input [252:0] snakepos_x,
    input [252:0] snakepos_y,
    input [5:0] length,
    
    input [10:0] curr_x,
    input [10:0] curr_y,
    
    output [5:0] points, // Snake head hits apple
    output lose,         // Snake head hits body or wall
    output win
);

    reg [5:0] i;
    reg lost;
    reg [5:0] hit;
    reg win_r;

    // Initialize registers
    initial begin
        i = 0;
        lost = 0;
        hit = 2; // Starting points
        win_r = 0;
    end

    // Combined points, win, and loss logic
    always @(posedge clk) begin
        if (reset) begin 
            hit <= 2;
            lost <= 0;
            win_r <= 0;
        end else begin
            // Points and win logic
            if ((snakepos_x[10:0] == applepos_x) && (snakepos_y[10:0] == applepos_y)) begin
                hit <= hit + 1; 
                if (hit == 8) begin  // Winning condition when points reach 8
                    win_r <= 1;
                end                                                                                          
            end
            
            // Loss conditions
            for (i = 1; i < length && i <= 22; i = i + 1) begin // Limit `i` to valid range
                if ((snakepos_x[10:0] == snakepos_x[11*i +: 11]) && 
                    (snakepos_y[10:0] == snakepos_y[11*i +: 11])) begin
                    lost <= 1;
                end
            end
            
            // Wall collision
            if ((snakepos_x[10:0] == wallpos_x) && (snakepos_y[10:0] == wallpos_y)) begin
                if (hit > 0) begin
                    hit <= hit - 1; // Decrement points on wall collision
                end
                
                if (hit == 1) begin // Trigger loss if points reach 0 after decrement
                    lost <= 1;
                end
            end
        end
    end

    assign lose = lost;
    assign points = hit;
    assign win = win_r;

endmodule

