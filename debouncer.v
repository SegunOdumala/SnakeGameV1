`timescale 1ns / 1ps

module debouncer(
    input  clk,
    input  I0,
    input  I1,
    output reg O0,
    output reg O1
);
    // Number of bits used to filter noise
    // Larger WIDTH => longer "settling" time
    parameter WIDTH = 16;

    // Shift registers for each input
    reg [WIDTH-1:0] shift0 = 0;
    reg [WIDTH-1:0] shift1 = 0;

    always @(posedge clk) begin
        // Shift in the latest sample of I0
        shift0 <= {shift0[WIDTH-2:0], I0};

        // If all bits are 1, we declare the debounced output = 1
        // If all bits are 0, we declare the debounced output = 0
        if (shift0 == {WIDTH{1'b1}})
            O0 <= 1'b1;
        else if (shift0 == {WIDTH{1'b0}})
            O0 <= 1'b0;

        // Shift in the latest sample of I1
        shift1 <= {shift1[WIDTH-2:0], I1};

        if (shift1 == {WIDTH{1'b1}})
            O1 <= 1'b1;
        else if (shift1 == {WIDTH{1'b0}})
            O1 <= 1'b0;
    end

endmodule
