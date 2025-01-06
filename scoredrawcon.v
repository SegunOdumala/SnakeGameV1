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
    // NEW: Points from collisioncon for score display
    input [5:0] points,

    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b
);

// Parameters

parameter BLK_SIZE_X    = 32,
          BLK_SIZE_Y    = 32;
parameter APPLE_SIZE_X  = 32,
          APPLE_SIZE_Y  = 32;
parameter WALL_SIZE_X   = 32,
          WALL_SIZE_Y   = 32;
parameter MAX_SEGMENTS  = 23; // Max snake segments
parameter SCREEN_WIDTH  = 1440;
parameter SCREEN_HEIGHT = 900;

// Game-over, winner, credits, etc.
parameter GAMEOVER_WIDTH   = 300;
parameter GAMEOVER_HEIGHT  = 212;
parameter WINNER_WIDTH     = 300;
parameter WINNER_HEIGHT    = 171;
parameter CREDITS_WIDTH    = 317;
parameter CREDITS_HEIGHT   = 100;
parameter GAMENAME_WIDTH   = 317;
parameter GAMENAME_HEIGHT  = 100;

// Offsets for centering images
parameter GAMEOVER_X_OFFSET = (SCREEN_WIDTH - GAMEOVER_WIDTH) / 2;
parameter GAMEOVER_Y_OFFSET = (SCREEN_HEIGHT - GAMEOVER_HEIGHT) / 2;
parameter WINNER_X_OFFSET   = (SCREEN_WIDTH - WINNER_WIDTH) / 2;
parameter WINNER_Y_OFFSET   = (SCREEN_HEIGHT - WINNER_HEIGHT) / 2;

// Offsets for credits and game name
parameter CREDITS_X_OFFSET  = 11'd0;
parameter CREDITS_Y_OFFSET  = SCREEN_HEIGHT - CREDITS_HEIGHT;
parameter GAMENAME_X_OFFSET = (SCREEN_WIDTH - GAMENAME_WIDTH) / 2;
parameter GAMENAME_Y_OFFSET = SCREEN_HEIGHT - GAMENAME_HEIGHT;


// SCORE DISPLAY PARAMETERS (Static apples at top)

parameter SCORE_APPLE_WIDTH  = 32;
parameter SCORE_APPLE_HEIGHT = 32;
parameter SCORE_X_OFFSET     = 20;  // Start drawing score apples from left
parameter SCORE_Y_OFFSET     = 20;  // Draw score apples near the top


// Internal registers and wires

reg [3:0] blk_r, blk_g, blk_b;
reg [3:0] bg_r,  bg_g,  bg_b;
reg [3:0] gameend_r, gameend_g, gameend_b;

reg [13:0] addr       = 0;
reg [13:0] addrHEAD   = 0;
reg [13:0] addrBODY   = 0;
reg [13:0] addrGRASS  = 0;
reg [13:0] addrWALL   = 0;
reg [15:0] addrCredits    = 0;
reg [15:0] addrGameName   = 0;
reg [15:0] addr_gameover  = 0;
reg [15:0] addr_winner    = 0;

wire [11:0] rom_pixelA;
wire [11:0] rom_pixelHEAD;
wire [11:0] rom_pixelBODY;
wire [11:0] rom_pixelGRASS;
wire [11:0] rom_pixelWALL;
wire [11:0] rom_pixelCredits;
wire [11:0] rom_pixelGameName;
wire [11:0] rom_pixel_gameover;
wire [11:0] rom_pixel_winner;

reg [5:0] i;
reg placed;
reg game_end;

// Background and Overall State Logic (Combinational)
always @* begin
    // Default background color logic before the game-end checks
    // (Your existing logic for credits/game name background, etc.)
    if ((curr_x < 11'd25) || (curr_x > 11'd525) ||
        (curr_y < 11'd1)   || (curr_y > 11'd101)) 
    begin
        bg_r <= rom_pixelCredits[11:8];
        bg_g <= rom_pixelCredits[7:4];
        bg_b <= rom_pixelCredits[3:0];
    end

    if ((curr_x < 11'd1281) || (curr_x > 11'd892) ||
        (curr_y < 11'd1)    || (curr_y > 11'd101)) 
    begin
        bg_r <= rom_pixelGameName[11:8];
        bg_g <= rom_pixelGameName[7:4];
        bg_b <= rom_pixelGameName[3:0];
    end

    // Determine if game is over or won
    game_end = win || lose;

    if (!lose) begin
        if (win) begin
            // Background is green if win
            bg_r <= 4'b0000;
            bg_g <= 4'b1111;
            bg_b <= 4'b0000;
        end 
        else begin
            // Normal boundaries / background if no lose, no win
            if ((curr_x < 11'd16) || (curr_x > 11'd1424) ||
                (curr_y < 11'd16) || (curr_y > 11'd780)) 
            begin
                bg_r <= 4'b1111;
                bg_g <= 4'b1111;
                bg_b <= 4'b1111;
            end 
            else begin
                bg_r <= 4'b0000;
                bg_g <= 4'b0000;
                bg_b <= 4'b0000;
            end
        end
    end 
    else begin
        // If losing, background is red
        bg_r <= 4'b1111;
        bg_g <= 4'b0000;
        bg_b <= 4'b0000;
    end
end

// Main Rendering Logic (Sequential, posedge clk)

always @(posedge clk) begin
    if (!rst) begin
        // Reset signals
        blk_r      <= 4'b0000;
        blk_g      <= 4'b0000;
        blk_b      <= 4'b0000;
        gameend_r  <= 4'b0000;
        gameend_g  <= 4'b0000;
        gameend_b  <= 4'b0000;
        addr       <= 0;
        addrHEAD   <= 0;
        addrBODY   <= 0;
        addrGRASS  <= 0;
        addrWALL   <= 0;
        addrCredits   <= 0;
        addrGameName  <= 0;
        addr_gameover <= 0;
        addr_winner   <= 0;
        placed     <= 0;
    end 
    else begin
        // Every new pixel begins as not placed
        placed <= 0;

        //Apple (in-game) Rendering
        if (!game_end &&
            (curr_x >= applepos_x) && (curr_x < applepos_x + APPLE_SIZE_X) &&
            (curr_y >= applepos_y) && (curr_y < applepos_y + APPLE_SIZE_Y)) 
        begin
            placed <= 1;
            addr <= ((curr_x - applepos_x) +
                    (curr_y - applepos_y) * APPLE_SIZE_X);

            if (rom_pixelA != 12'h000) begin
                blk_r <= rom_pixelA[11:8];
                blk_g <= rom_pixelA[7:4];
                blk_b <= rom_pixelA[3:0];
            end 
            else begin
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end

        //Wall Rendering
        if (!game_end &&
            (curr_x >= wallpos_x) && (curr_x < wallpos_x + WALL_SIZE_X) &&
            (curr_y >= wallpos_y) && (curr_y < wallpos_y + WALL_SIZE_Y)) 
        begin
            placed <= 1;
            addrWALL <= ((curr_x - wallpos_x) +
                        (curr_y - wallpos_y) * WALL_SIZE_X);

            if (rom_pixelWALL != 12'h000) begin
                blk_r <= rom_pixelWALL[11:8];
                blk_g <= rom_pixelWALL[7:4];
                blk_b <= rom_pixelWALL[3:0];
            end
        end

        //Snake Head Rendering
        else if (!game_end &&
                 (curr_x >= snakepos_x[10:0]) && 
                 (curr_x < snakepos_x[10:0] + BLK_SIZE_X) &&
                 (curr_y >= snakepos_y[10:0]) && 
                 (curr_y < snakepos_y[10:0] + BLK_SIZE_Y)) 
        begin
            placed <= 1;
            addrHEAD <= ((curr_x - snakepos_x[10:0]) +
                        (curr_y - snakepos_y[10:0]) * BLK_SIZE_X);

            if (rom_pixelHEAD != 12'h000) begin
                blk_r <= rom_pixelHEAD[11:8];
                blk_g <= rom_pixelHEAD[7:4];
                blk_b <= rom_pixelHEAD[3:0];
            end 
            else begin
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end

        //Snake Body Rendering
        else begin
            for (i = 1; i < length && i < MAX_SEGMENTS; i = i + 1) begin
                if (!game_end &&
                    (curr_x >= snakepos_x[11*i +: 11]) &&
                    (curr_x < snakepos_x[11*i +: 11] + BLK_SIZE_X) &&
                    (curr_y >= snakepos_y[11*i +: 11]) &&
                    (curr_y < snakepos_y[11*i +: 11] + BLK_SIZE_Y)) 
                begin
                    placed <= 1;
                    addrBODY <= ((curr_x - snakepos_x[11*i +: 11]) +
                                (curr_y - snakepos_y[11*i +: 11]) * BLK_SIZE_X);

                    if (rom_pixelBODY != 12'h000) begin
                        blk_r <= rom_pixelBODY[11:8];
                        blk_g <= rom_pixelBODY[7:4];
                        blk_b <= rom_pixelBODY[3:0];
                    end 
                    else begin
                        addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                        blk_r <= rom_pixelGRASS[11:8];
                        blk_g <= rom_pixelGRASS[7:4];
                        blk_b <= rom_pixelGRASS[3:0];
                    end
                end
            end
        end

        //Credits Image Rendering
        if ((curr_x >= CREDITS_X_OFFSET) && (curr_x < CREDITS_X_OFFSET + CREDITS_WIDTH) &&
            (curr_y >= CREDITS_Y_OFFSET) && (curr_y < CREDITS_Y_OFFSET + CREDITS_HEIGHT)) 
        begin
            placed <= 1;
            addrCredits <= ((curr_x - CREDITS_X_OFFSET) +
                           (curr_y - CREDITS_Y_OFFSET) * CREDITS_WIDTH);

            if (rom_pixelCredits != 12'h000) begin
                blk_r <= rom_pixelCredits[11:8];
                blk_g <= rom_pixelCredits[7:4];
                blk_b <= rom_pixelCredits[3:0];
            end 
            else begin
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end

        //Game Name Image Rendering
        if ((curr_x >= GAMENAME_X_OFFSET) && (curr_x < GAMENAME_X_OFFSET + GAMENAME_WIDTH) &&
            (curr_y >= GAMENAME_Y_OFFSET) && (curr_y < GAMENAME_Y_OFFSET + GAMENAME_HEIGHT)) 
        begin
            placed <= 1;
            addrGameName <= ((curr_x - GAMENAME_X_OFFSET) +
                            (curr_y - GAMENAME_Y_OFFSET) * GAMENAME_WIDTH);

            if (rom_pixelGameName != 12'h000) begin
                blk_r <= rom_pixelGameName[11:8];
                blk_g <= rom_pixelGameName[7:4];
                blk_b <= rom_pixelGameName[3:0];
            end 
            else begin
                addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                blk_r <= rom_pixelGRASS[11:8];
                blk_g <= rom_pixelGRASS[7:4];
                blk_b <= rom_pixelGRASS[3:0];
            end
        end

        //Game Over Screen
        if (lose) begin
            if ((curr_x >= GAMEOVER_X_OFFSET) && (curr_x < GAMEOVER_X_OFFSET + GAMEOVER_WIDTH) &&
                (curr_y >= GAMEOVER_Y_OFFSET) && (curr_y < GAMEOVER_Y_OFFSET + GAMEOVER_HEIGHT)) 
            begin
                placed <= 1;
                addr_gameover <= ((curr_x - GAMEOVER_X_OFFSET) +
                                 (curr_y - GAMEOVER_Y_OFFSET) * GAMEOVER_WIDTH);

                if (rom_pixel_gameover != 12'h000) begin
                    gameend_r <= rom_pixel_gameover[11:8];
                    gameend_g <= rom_pixel_gameover[7:4];
                    gameend_b <= rom_pixel_gameover[3:0];
                end 
                else begin
                    addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                    gameend_r <= rom_pixelGRASS[11:8];
                    gameend_g <= rom_pixelGRASS[7:4];
                    gameend_b <= rom_pixelGRASS[3:0];
                end
            end 
            else begin
                gameend_r <= 4'b0000;
                gameend_g <= 4'b0000;
                gameend_b <= 4'b0000;
            end
        end

        //Winner Screen
        if (win) begin
            if ((curr_x >= WINNER_X_OFFSET) && (curr_x < WINNER_X_OFFSET + WINNER_WIDTH) &&
                (curr_y >= WINNER_Y_OFFSET) && (curr_y < WINNER_Y_OFFSET + WINNER_HEIGHT)) 
            begin
                placed <= 1;
                addr_winner <= ((curr_x - WINNER_X_OFFSET) +
                               (curr_y - WINNER_Y_OFFSET) * WINNER_WIDTH);

                if (rom_pixel_winner != 12'h000) begin
                    gameend_r <= rom_pixel_winner[11:8];
                    gameend_g <= rom_pixel_winner[7:4];
                    gameend_b <= rom_pixel_winner[3:0];
                end 
                else begin
                    addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
                    gameend_r <= rom_pixelGRASS[11:8];
                    gameend_g <= rom_pixelGRASS[7:4];
                    gameend_b <= rom_pixelGRASS[3:0];
                end
            end 
            else begin
                gameend_r <= 4'b0000;
                gameend_g <= 4'b0000;
                gameend_b <= 4'b0000;
            end
        end

        //SCORE RENDERING LOGIC (static apples at top)
        begin : score_apples
            integer score_index;
            for (score_index = 0; score_index < points; score_index = score_index + 1) begin
                if ((curr_x >= SCORE_X_OFFSET + score_index * SCORE_APPLE_WIDTH) &&
                    (curr_x <  SCORE_X_OFFSET + score_index * SCORE_APPLE_WIDTH + SCORE_APPLE_WIDTH) &&
                    (curr_y >= SCORE_Y_OFFSET) &&
                    (curr_y <  SCORE_Y_OFFSET + SCORE_APPLE_HEIGHT)) 
                begin
                    placed <= 1;
                    // Example: red apples at the top
                    blk_r <= 4'b1111;
                    blk_g <= 4'b0000;
                    blk_b <= 4'b0000;
                end
            end
        end

        // Grass Fallback
        if (!placed) begin
            addrGRASS <= ((curr_x % 11'd1440) + (curr_y % 11'd900) * 11'd1440);
            blk_r <= rom_pixelGRASS[11:8];
            blk_g <= rom_pixelGRASS[7:4];
            blk_b <= rom_pixelGRASS[3:0];
        end
    end
end


// Output Assignments

assign draw_r = (game_end && gameend_r != 4'b0000) ? gameend_r :
                (blk_r != 4'b0000)                 ? blk_r      : bg_r;
assign draw_g = (game_end && gameend_g != 4'b0000) ? gameend_g :
                (blk_g != 4'b0000)                 ? blk_g      : bg_g;
assign draw_b = (game_end && gameend_b != 4'b0000) ? gameend_b :
                (blk_b != 4'b0000)                 ? blk_b      : bg_b;

// Memory Instances

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
