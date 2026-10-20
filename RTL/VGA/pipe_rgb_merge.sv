module pipe_rgb_merge (
    input  logic [7:0] rgb1,
    input  logic [7:0] rgb2,
    output logic [7:0] rgb_out
);

    // Bitwise AND the three color buses together
    assign rgb_out = rgb1 & rgb2;

endmodule
