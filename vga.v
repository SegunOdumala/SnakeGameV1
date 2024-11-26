`timescale 1ns / 1ps

module vga(
    input clk,
    input rst,
    input [3:0] draw_r, 
    input [3:0] draw_g, 
    input [3:0] draw_b,
    output [10:0] curr_x,
    output [10:0] curr_y,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync,
    output vsync
    );

// Internal counters and display region
reg [10:0] hcount = 0;
reg [9:0] vcount = 0;
reg [10:0] curr_x_r;
reg [10:0] curr_y_r;
wire display_region;

// HSync and VSync timings
assign hsync = (hcount < 11'd152);  // Horizontal sync pulse
assign vsync = (vcount < 10'd3);    // Vertical sync pulse
assign display_region = (hcount >= 11'd384 && hcount < 11'd1824) &&
                        (vcount >= 10'd31 && vcount < 10'd931);

// Pixel output
assign pix_r = (display_region) ? draw_r : 4'b0000;
assign pix_g = (display_region) ? draw_g : 4'b0000;
assign pix_b = (display_region) ? draw_b : 4'b0000;

// Horizontal counter
always @(posedge clk or negedge rst) begin
    if (!rst)
        hcount <= 0;
    else if (hcount == 11'd1903)
        hcount <= 0;
    else
        hcount <= hcount + 1;
end

// Vertical counter
always @(posedge clk or negedge rst) begin
    if (!rst)
        vcount <= 0;
    else if (hcount == 11'd1903) begin
        if (vcount == 10'd931)
            vcount <= 0;
        else
            vcount <= vcount + 1;
    end
end

// Current pixel position
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        curr_x_r <= 0;
        curr_y_r <= 0;
    end else if (display_region) begin
        curr_x_r <= hcount - 11'd384;
        curr_y_r <= vcount - 10'd31;
    end
end

assign curr_x = curr_x_r;
assign curr_y = curr_y_r;

endmodule