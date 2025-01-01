`timescale 1ns / 1ps

module game_top(
    input clk,
    input rst,
    input [4:0] btn,
    input CLK100MHZ,
    input PS2_CLK,
    input PS2_DATA,
    output UART_TXD,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync, 
    output vsync, 
    output a, b, c, d, e, f, g,
    output [7:0] an
    );

    // Draw wires
    wire [3:0] draw_r;
    wire [3:0] draw_g;
    wire [3:0] draw_b;
    wire [10:0] curr_x;
    wire [10:0] curr_y;
    wire kb_up, kb_down, kb_left, kb_right;

    // Apple wires & registers
    reg new;
    wire [10:0] newapple_x;
    wire [10:0] newapple_y;
    reg [10:0] applepos_x = 11'd656;
    reg [10:0] applepos_y = 11'd498;

    // Wall wires
    wire [10:0] newwall_x;
    wire [10:0] newwall_y;
    reg [10:0] wallpos_x = 11'd32;
    reg [10:0] wallpos_y = 11'd128;

    // Game wires & registers
    reg [26:0] clk_div;
    reg game_clk;
    wire lose;
    wire [5:0] points;
    wire win;
    wire pixclk;
    reg CLK50MHZ=0;    
    wire [31:0]keycode;


    // Snake registers
    reg [252:0] snakepos_x, snakepos_y;
    reg [53:0] direction; // 0 = right, 1 = down, 2 = left, 3 = up
    reg [5:0] length = 9;
    reg [5:0] i;

    // Seven segment display registers
    reg [3:0] num_1, num_2;

    // Clock generator
    clk_wiz_0 inst
    (
        .clk_out1(pixclk),
        .clk_in1(clk)
    );

    // Setting up key variables
    initial begin
        for (i = 0; i < 22; i = i + 1) begin
            snakepos_x[i*11 +: 11] = 11'd784 - (i * 11'd32);
            snakepos_y[i*11 +: 11] = 11'd464;
        end 
        direction = 54'd0;
        length = 5'd1;
        num_1 = 4'h1;
        num_2 = 4'h0;
    end

    // Game clock generation
    always @(posedge clk) begin
    CLK50MHZ<=~CLK50MHZ;
        if (!rst) begin
            clk_div <= 0;
            game_clk <= 0;
        end else begin
            if (clk_div == 27'd10600000) begin
                clk_div <= 0;
                game_clk <= !game_clk;
            end else begin
                clk_div <= clk_div + 1;
            end
        end
    end
    

    // Direction choice and block movement
    always @(posedge game_clk) begin
        if (btn[0]) begin
            direction = 54'd0;
            length = 5'd1;
            new = 1;
            num_1 = 4'h1;
            num_2 = 4'h0;
            for (i = 0; i < 22; i = i + 1) begin
                snakepos_x[i*11 +: 11] = 11'd784 - (i * 11'd32);
                snakepos_y[i*11 +: 11] = 11'd464;
            end 
        end else begin
        if (points != length) begin
            if (points > length) begin
                // INCREMENT 7-seg display
                if (num_1 + 1 == 10) begin
                    num_1 <= 4'h0;
                    num_2 <= num_2 + 4'h1;
                end else begin 
                    num_1 <= num_1 + 4'h1;
                end
            end else if (points < length) begin
                // DECREMENT 7-seg display
                if (num_1 == 4'h0) begin
                    num_1 <= 4'h9;
                    if (num_2 > 0)
                        num_2 <= num_2 - 4'h1;
                end else begin
                    num_1 <= num_1 - 4'h1;
                end
            end
            // Finally update the snake's length
            length <= points;
            applepos_x = newapple_x;
            applepos_y = newapple_y;
            wallpos_x = newwall_x;
            wallpos_y = newwall_y;
        end

            // Direction assignment 
            for (i = 22; i > 0; i = i - 1) begin
                direction[2*i +: 2] = direction[2*(i-1) +: 2];
            end
            
        //----------------------------------------
        // 1) Keyboard-based direction
        //----------------------------------------
        // We'll interpret W=up, A=left, S=down, D=right
        // (from your scancode logic)
        if (kb_left  == 1 && direction[1:0] != 2'd0) direction[1:0] = 2'd2; 
        if (kb_right == 1 && direction[1:0] != 2'd2) direction[1:0] = 2'd0;
        if (kb_up    == 1 && direction[1:0] != 2'd1) direction[1:0] = 2'd3;
        if (kb_down  == 1 && direction[1:0] != 2'd3) direction[1:0] = 2'd1;
        //----------------------------------------
        // 2) Button-based direction 
        //------------------------------
            case (btn[4:1])
                4'b0010: if (direction[1:0] != 2'd0) direction[1:0] = 2'd2; // Turn left
                4'b0100: if (direction[1:0] != 2'd2) direction[1:0] = 2'd0; // Turn right
                4'b0001: if (direction[1:0] != 2'd1) direction[1:0] = 2'd3; // Turn up
                4'b1000: if (direction[1:0] != 2'd3) direction[1:0] = 2'd1; // Turn down
            endcase

            // Movement logic
            for (i = 0; i < 22; i = i + 1) begin
                if (direction[2*i +: 2] == 2'd0) // Right
                    snakepos_x[11*i +: 11] <= (snakepos_x[11*i +: 11] < 11'd1392) ? snakepos_x[11*i +: 11] + 11'd32 : 11'd16;
                else if (direction[2*i +: 2] == 2'd1) // Down
                    snakepos_y[11*i +: 11] <= (snakepos_y[11*i +: 11] < 11'd848) ? snakepos_y[11*i +: 11] + 11'd32 : 11'd16;
                else if (direction[2*i +: 2] == 2'd2) // Left
                    snakepos_x[11*i +: 11] <= (snakepos_x[11*i +: 11] > 11'd16) ? snakepos_x[11*i +: 11] - 11'd32 : 11'd1392;
                else if (direction[2*i +: 2] == 2'd3) // Up
                    snakepos_y[11*i +: 11] <= (snakepos_y[11*i +: 11] > 11'd16) ? snakepos_y[11*i +: 11] - 11'd32 : 11'd848;
            end
        end
    end

    seginterface seg_inst(
        .clk(clk),
        .rst(rst), 
        .num_1(4'h2),
        .num_2(4'h2),
        .num_3(num_1),
        .num_4(num_2),
        .an(an), 
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g)
    );

    apple apple_inst(
       .clk(clk),
       .btnrst(btn[0]),
       .snakehead_x(snakepos_x[10:0]),
       .snakehead_y(snakepos_y[10:0]),

       // Pass wall position in
       .wallpos_x(wallpos_x),
       .wallpos_y(wallpos_y),

       .newapple_x(newapple_x),
       .newapple_y(newapple_y)
    );


    Wall wall_inst(
        .clk(clk),
        .btnrst(btn[0]),
        .snakehead_x(snakepos_x[10:0]),
        .snakehead_y(snakepos_y[10:0]),
        .newwall_x(newwall_x),
        .newwall_y(newwall_y)
    );

    collisioncon collision_inst(
        .clk(game_clk),                               
        .reset(btn[0]),    
        .applepos_x(applepos_x),
        .applepos_y(applepos_y),
        .wallpos_x(wallpos_x),
        .wallpos_y(wallpos_y),                                  
        .snakepos_x(snakepos_x),                 
        .snakepos_y(snakepos_y),                 
        .length(length),                                                  
        .curr_x(curr_x),                      
        .curr_y(curr_y),
        .points(points),                                               
        .lose(lose),
        .win(win) 
    );

    drawcon drawcon_inst (
        .clk(pixclk),
        .rst(rst),
        .snakepos_x(snakepos_x),
        .snakepos_y(snakepos_y),
        .length(length),
        .applepos_x(applepos_x),
        .applepos_y(applepos_y),
        .wallpos_x(wallpos_x),
        .wallpos_y(wallpos_y),
        .curr_x(curr_x),
        .curr_y(curr_y),
        .lose(lose),
        .win(win),
        .draw_r(draw_r),
        .draw_g(draw_g),
        .draw_b(draw_b)
    );

    vga vga_inst (
        .clk(pixclk),
        .rst(rst),
        .draw_r(draw_r),
        .draw_g(draw_g),
        .draw_b(draw_b),
        .pix_r(pix_r),
        .pix_g(pix_g),
        .pix_b(pix_b),
        .curr_x(curr_x),
        .curr_y(curr_y),
        .hsync(hsync), 
        .vsync(vsync)
    ); 
    
  PS2Receiver keyboard (
    .clk(CLK50MHZ),
    .kclk(PS2_CLK),
    .kdata(PS2_DATA),
    .keycodeout(keycode[31:0]),
    .up(kb_up),
    .down(kb_down),
    .left(kb_left),
    .right(kb_right)
  );

endmodule
