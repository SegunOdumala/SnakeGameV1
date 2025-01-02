`timescale 1ns / 1ps

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
    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b
);

// Parameters
parameter BLK_SIZE_X = 32, BLK_SIZE_Y = 32;
parameter APPLE_SIZE_X = 32, APPLE_SIZE_Y = 32;
parameter WALL_SIZE_X = 32, WALL_SIZE_Y = 32;
parameter MAX_SEGMENTS = 23; // Max number of snake segments (252 bits / 11 bits per segment)
// Parameters for image sizes and screen centering
parameter SCREEN_WIDTH = 1440;
parameter SCREEN_HEIGHT = 900;
parameter GAMEOVER_WIDTH = 707;
parameter GAMEOVER_HEIGHT = 500;
parameter WINNER_WIDTH = 789;
parameter WINNER_HEIGHT = 450;
parameter CREDITS_WIDTH = 317;
parameter CREDITS_HEIGHT = 100;
parameter GAMENAME_WIDTH = 317;
parameter GAMENAME_HEIGHT = 100;

// Image offsets for centering
parameter GAMEOVER_X_OFFSET = (SCREEN_WIDTH - GAMEOVER_WIDTH) / 2; // Centered X position
parameter GAMEOVER_Y_OFFSET = (SCREEN_HEIGHT - GAMEOVER_HEIGHT) / 2; // Centered Y position
parameter WINNER_X_OFFSET = (SCREEN_WIDTH - WINNER_WIDTH) / 2; // Centered X position
parameter WINNER_Y_OFFSET = (SCREEN_HEIGHT - WINNER_HEIGHT) / 2; // Centered Y position
// Offset for Credits image at the bottom left
parameter CREDITS_X_OFFSET = 11'd0; // Bottom-left corner, X = 0
parameter CREDITS_Y_OFFSET = SCREEN_HEIGHT - CREDITS_HEIGHT; // Bottom-left corner, Y = SCREEN_HEIGHT - CREDITS_HEIGHT
parameter GAMENAME_X_OFFSET = (SCREEN_WIDTH - GAMEOVER_WIDTH) / 2; // Bottom-left corner, X = 0
parameter GAMENAME_Y_OFFSET = SCREEN_HEIGHT - CREDITS_HEIGHT; // Bottom-left corner, Y = SCREEN_HEIGHT - CREDITS_HEIGHT
// Registers and wires
reg [3:0] blk_r, blk_g, blk_b;
reg [3:0] bg_r, bg_g, bg_b;
reg [13:0] addr = 0; // Address for apple memory
wire [11:0] rom_pixelA; // Output pixel from apple block memory
reg [13:0] addrHEAD = 0; // Address for snake head
wire [11:0] rom_pixelHEAD; // Output pixel for snake head
reg [13:0] addrBODY = 0; 
wire [11:0] rom_pixelBODY;  
reg [13:0] addrGRASS;
wire [11:0] rom_pixelGRASS;  // Pixel data for grass
reg [13:0] addrWALL;
wire [11:0] rom_pixelWALL;  // Pixel data for grass
reg [15:0] addrCredits;
wire [11:0] rom_pixelCredits;  // Pixel data for image at bottom left of the screen
reg [15:0] addrGameName;
wire [11:0] rom_pixelGameName;  // Pixel data for image at bottom left of the screen
reg [13:0] addr_gameover, addr_winner; // Wires for image pixels
wire [11:0] rom_pixel_gameover, rom_pixel_winner; // Wires for image pixels
reg [5:0] i;
reg placed;
reg game_end; // Single driver for game_end

    //background colour
    always@* begin
        if ((curr_x < 11'd25) || (curr_x > 11'd525) || (curr_y < 11'd1) || (curr_y > 11'd101)) begin
             bg_r <= rom_pixelCredits[11:8];
             bg_g <= rom_pixelCredits[7:4];
             bg_b <= rom_pixelCredits[3:0];
        end
        if ((curr_x < 11'd1281) || (curr_x > 11'd892) || (curr_y < 11'd1) || (curr_y > 11'd101)) begin
             bg_r <= rom_pixelGameName[11:8];
             bg_g <= rom_pixelGameName[7:4];
             bg_b <= rom_pixelGameName[3:0];
        end        
        game_end = win || lose;
        if(!lose) begin
            if(win) begin
                bg_r <= 4'b0000;
                bg_g <= 4'b1111;
                bg_b <= 4'b0000;
            end else begin
                if ((curr_x < 11'd16) || (curr_x > 11'd1424) || (curr_y < 11'd16) || (curr_y > 11'd780)) begin
                    bg_r <= 4'b1111;
                    bg_g <= 4'b1111;
                    bg_b <= 4'b1111;
                end else begin
                    bg_r <= 4'b0000;
                    bg_g <= 4'b0000;
                    bg_b <= 4'b0000;
                end
            end
        end else begin
            bg_r <= 4'b1111;
            bg_g <= 4'b0000;
            bg_b <= 4'b0000;
        end
    end


// Main rendering logic
always @(posedge clk) begin
    if (!rst) begin
        // Reset all signals
        blk_r <= 4'b0000;
        blk_g <= 4'b0000;
        blk_b <= 4'b0000;
        addr <= 0;
        addrHEAD <= 0;
        addrBODY <= 0;
        addrGRASS <= 0;
        addrCredits <= 0;
        addrGameName <= 0;
        placed <= 0;
    end else begin
        placed <= 0; // Reset placement flag for the new frame

// Apple rendering
if (!game_end && 
    (curr_x >= applepos_x) && (curr_x < applepos_x + APPLE_SIZE_X) &&
    (curr_y >= applepos_y) && (curr_y < applepos_y + APPLE_SIZE_Y)) begin
    placed <= 1;

    // Dynamically calculate address for the current pixel
    addr <= ((curr_x - applepos_x) + 
             (curr_y - applepos_y) * APPLE_SIZE_X);

    // Fetch and render the pixel
    if (rom_pixelA != 12'h000) begin // Render non-black pixels
        blk_r <= rom_pixelA[11:8];
        blk_g <= rom_pixelA[7:4];
        blk_b <= rom_pixelA[3:0];
    end else begin // Render grass for black pixels
        addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
        blk_r <= rom_pixelGRASS[11:8];
        blk_g <= rom_pixelGRASS[7:4];
        blk_b <= rom_pixelGRASS[3:0];
    end
end

// Wall rendering
if (!game_end && 
    (curr_x >= wallpos_x) && (curr_x < wallpos_x + WALL_SIZE_X) &&
    (curr_y >= wallpos_y) && (curr_y < wallpos_y + WALL_SIZE_Y)) begin
    placed <= 1;

    // Dynamically calculate address for the current pixel
    addrWALL <= ((curr_x - wallpos_x) + 
             (curr_y - wallpos_y) * WALL_SIZE_X);

    // Fetch and render the pixel
    if (rom_pixelWALL != 12'h000) begin // Render non-black pixels
        blk_r <= rom_pixelWALL[11:8];
        blk_g <= rom_pixelWALL[7:4];
        blk_b <= rom_pixelWALL[3:0];
    end 
end

// Snake head rendering
else if (!game_end &&
    (curr_x >= snakepos_x[10:0]) && 
    (curr_x < snakepos_x[10:0] + BLK_SIZE_X) &&
    (curr_y >= snakepos_y[10:0]) && 
    (curr_y < snakepos_y[10:0] + BLK_SIZE_Y)) begin
    placed <= 1;

    // Dynamically calculate address for the current pixel
    addrHEAD <= ((curr_x - snakepos_x[10:0]) + 
                 (curr_y - snakepos_y[10:0]) * BLK_SIZE_X);

    // Fetch and render the pixel
    if (rom_pixelHEAD != 12'h000) begin // Render non-black pixels
        blk_r <= rom_pixelHEAD[11:8];
        blk_g <= rom_pixelHEAD[7:4];
        blk_b <= rom_pixelHEAD[3:0];
    end else begin // Render grass for black pixels
        addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
        blk_r <= rom_pixelGRASS[11:8];
        blk_g <= rom_pixelGRASS[7:4];
        blk_b <= rom_pixelGRASS[3:0];
    end
end


// Snake body rendering
else begin
    for (i = 1; i < length && i < MAX_SEGMENTS; i = i + 1) begin
        if (!game_end &&
            (curr_x >= snakepos_x[11*i +: 11]) &&
            (curr_x < snakepos_x[11*i +: 11] + BLK_SIZE_X) &&
            (curr_y >= snakepos_y[11*i +: 11]) &&
            (curr_y < snakepos_y[11*i +: 11] + BLK_SIZE_Y)) begin
            placed <= 1;
            addrBODY <= ((curr_x - snakepos_x[11*i +: 11]) + 
                         (curr_y - snakepos_y[11*i +: 11]) * BLK_SIZE_X);
            if (rom_pixelBODY != 12'h000) begin // Render snake body pixel if not black
                blk_r <= rom_pixelBODY[11:8];
                blk_g <= rom_pixelBODY[7:4];
                blk_b <= rom_pixelBODY[3:0];
            end else begin // Render grass pixel if snake body pixel is black
                addrGRASS <= (curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440;
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end
    end
end   
               // Credits image rendering
        if ((curr_x >= CREDITS_X_OFFSET) && (curr_x < CREDITS_X_OFFSET + CREDITS_WIDTH) &&
            (curr_y >= CREDITS_Y_OFFSET) && (curr_y < CREDITS_Y_OFFSET + CREDITS_HEIGHT)) begin
            placed <= 1;

            // Dynamically calculate address for the current pixel
            addrCredits <= ((curr_x - CREDITS_X_OFFSET -  0) +  //95
                           (curr_y - CREDITS_Y_OFFSET + 5) * CREDITS_WIDTH);

            // Fetch and render the pixel
            if (rom_pixelCredits != 12'h000) begin // Render non-black pixels
                blk_r <= rom_pixelCredits[11:8];
                blk_g <= rom_pixelCredits[7:4];
                blk_b <= rom_pixelCredits[3:0];
            end else begin // Render grass for black pixels
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end
        
        if ((curr_x >= GAMENAME_X_OFFSET) && (curr_x < GAMENAME_X_OFFSET + GAMENAME_WIDTH) &&
            (curr_y >= GAMENAME_Y_OFFSET) && (curr_y < GAMENAME_Y_OFFSET + GAMENAME_HEIGHT)) begin
            placed <= 1;

            // Dynamically calculate address for the current pixel
            addrGameName <= ((curr_x - GAMENAME_X_OFFSET -  0) +  //95
                           (curr_y - GAMENAME_Y_OFFSET + 5) * GAMENAME_WIDTH);

            // Fetch and render the pixel
            if (rom_pixelCredits != 12'h000) begin // Render non-black pixels
                blk_r <= rom_pixelGameName[11:8];
                blk_g <= rom_pixelGameName[7:4];
                blk_b <= rom_pixelGameName[3:0];
            end else begin // Render grass for black pixels
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end

        // Render grass background if nothing else is placed
        if (!placed) begin
            addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
            blk_r <= rom_pixelGRASS[11:8];
            blk_g <= rom_pixelGRASS[7:4];
            blk_b <= rom_pixelGRASS[3:0];
        end
    end
end

// Output assignments
assign draw_r = (blk_r != 4'b0000) ? blk_r : bg_r;
assign draw_g = (blk_g != 4'b0000) ? blk_g : bg_g;
assign draw_b = (blk_b != 4'b0000) ? blk_b : bg_b;

// Memory instances
blk_mem_gen_1 apple_inst (
    .clka(clk),
    .addra(addr),
    .douta(rom_pixelA)
);

blk_mem_gen_0 snakehead_inst (
    .clka(clk),
    .addra(addrHEAD),
    .douta(rom_pixelHEAD)
);

blk_mem_gen_2 snakebody_inst (
    .clka(clk),
    .addra(addrBODY),
    .douta(rom_pixelBODY)
);

blk_mem_gen_3 grass_inst (
    .clka(clk),
    .addra(addrGRASS),
    .douta(rom_pixelGRASS)
);

blk_mem_gen_4 gameover_inst (
    .clka(clk),
    .addra(addr_gameover),
    .douta(rom_pixel_gameover)
);

blk_mem_gen_5 winner_inst (
    .clka(clk),
    .addra(addr_winner),
    .douta(rom_pixel_winner)
);

blk_mem_gen_6 wall_inst (
    .clka(clk),
    .addra(addrWALL),
    .douta(rom_pixelWALL)
);

blk_mem_gen_7 credits_inst (
    .clka(clk),
    .addra(addrCredits),
    .douta(rom_pixelCredits)
);

blk_mem_gen_8 gamename_inst (
    .clka(clk),
    .addra(addrGameName),
    .douta(rom_pixelGameName)
);

endmodule