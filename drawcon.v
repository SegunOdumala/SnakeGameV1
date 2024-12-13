`timescale 1ns / 1ps

module drawcon(
    input clk,
    input rst,
    input [252:0] snakepos_x,
    input [252:0] snakepos_y,
    input [5:0] length,
    input [10:0] applepos_x,
    input [10:0] applepos_y,
    input [53:0] direction,
    input [10:0] curr_x,
    input [10:0] curr_y,
    input lose,
    input win,
    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b
);

// Parameters
parameter BLK_SIZE_X = 32, BLK_SIZE_Y = 32;
parameter APPLE_SIZE_X = 32, APPLE_SIZE_Y = 32;
parameter MAX_SEGMENTS = 23; // Max number of snake segments (252 bits / 11 bits per segment)

// Registers and wires
reg [3:0] blk_r, blk_g, blk_b;
reg [3:0] bg_r, bg_g, bg_b;
reg [13:0] addr = 0; // Address for apple memory
wire [11:0] rom_pixelA; // Output pixel from apple block memory
reg [13:0] addrHEAD = 0; // Address for snake head
reg [5:0] segment_index; // Tracks which body segment is being rendered
wire [11:0] rom_pixelHEAD; // Output pixel for snake head
reg [13:0] addrBODY = 0; 
wire [11:0] rom_pixelBODY;  
reg [5:0] i;
reg placed;
reg game_end;

// Background color logic
always @* begin
    game_end = win || lose;
    if (!lose) begin
        if (win) begin // win GREEN
            bg_r = 4'b0000;
            bg_g = 4'b1111;
            bg_b = 4'b0000;
        end else begin
            if ((curr_x < 11'd16) || (curr_x > 11'd1424) || 
                (curr_y < 11'd16) || (curr_y > 11'd880)) begin  //border
                bg_r = 4'b1111;
                bg_g = 4'b1111;
                bg_b = 4'b1111;
            end else begin  // Background (where grass should be)
                bg_r = 4'b0000;
                bg_g = 4'b0000;
                bg_b = 4'b0000;
            end
        end
    end else begin  //loss RED
        bg_r = 4'b1111;
        bg_g = 4'b0000;
        bg_b = 4'b0000;
    end
end

// Image rendering logic
always @(posedge clk) begin
    if (!rst) begin
        blk_r <= 4'b0000;
        blk_g <= 4'b0000;
        blk_b <= 4'b0000;
        addr <= 0;
        addrHEAD <= 0;
        segment_index <= 0;
        placed <= 0;
    end else begin
        placed <= 0; // Reset placement flag for the new frame

        // Apple rendering
        if (!game_end && 
            (curr_x >= applepos_x) && (curr_x < applepos_x + APPLE_SIZE_X) &&
            (curr_y >= applepos_y) && (curr_y < applepos_y + APPLE_SIZE_Y)) begin
            placed = 1;
            blk_r <= rom_pixelA[11:8];
            blk_g <= rom_pixelA[7:4];
            blk_b <= rom_pixelA[3:0];
            addr <= addr + 1;
        end

        // Snake head rendering
        else if (!game_end &&
            (curr_x >= snakepos_x[10:0]) && 
            (curr_x < snakepos_x[10:0] + BLK_SIZE_X) &&
            (curr_y >= snakepos_y[10:0]) && 
            (curr_y < snakepos_y[10:0] + BLK_SIZE_Y)) begin
            placed = 1;
            blk_r <= rom_pixelHEAD[11:8];
            blk_g <= rom_pixelHEAD[7:4];
            blk_b <= rom_pixelHEAD[3:0];
            addrHEAD <= addrHEAD + 1;
        end
// Snake body rendering
else begin
    for (i = 1; i < length && i < MAX_SEGMENTS; i = i + 1) begin
        if (!game_end &&
            (curr_x >= snakepos_x[11*i +: 11]) &&
            (curr_x < snakepos_x[11*i +: 11] + BLK_SIZE_X) &&
            (curr_y >= snakepos_y[11*i +: 11]) &&
            (curr_y < snakepos_y[11*i +: 11] + BLK_SIZE_Y)) begin
            placed = 1;

            // Calculate address within the body segment memory
            addrBODY <= ((curr_x - snakepos_x[11*i +: 11]) + 
                         (curr_y - snakepos_y[11*i +: 11]) * BLK_SIZE_X);

            // Assign color from memory
            blk_r <= rom_pixelBODY[11:8];
            blk_g <= rom_pixelBODY[7:4];
            blk_b <= rom_pixelBODY[3:0];
        end
    end
end

        if (!placed && !game_end) begin
            blk_r <= 4'b0000;
            blk_g <= 4'b0000;
            blk_b <= 4'b0000;
        end
    end
end

// Output assignments
assign draw_r = (blk_r != 4'b0000) ? blk_r : bg_r;
assign draw_g = (blk_g != 4'b0000) ? blk_g : bg_g;
assign draw_b = (blk_b != 4'b0000) ? blk_b : bg_b;

// Memory instance for apple
blk_mem_gen_1 apple_inst(
    .clka(clk),
    .addra(addr),
    .douta(rom_pixelA)
);

// Memory instance for SnakeHead
blk_mem_gen_0 snakehead_inst(
    .clka(clk),
    .addra(addrHEAD),
    .douta(rom_pixelHEAD)
);

// Memory instance for SnakeBody
blk_mem_gen_2 snakebody_inst(
    .clka(clk),
    .addra(addrBODY),
    .douta(rom_pixelBODY)
);


endmodule

