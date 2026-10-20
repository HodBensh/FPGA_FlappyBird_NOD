module building_rgb_merge (
    input  logic [7:0] rgb1,
    input  logic [7:0] rgb2,
    input  logic [7:0] rgb3,
    input  logic [7:0] rgb4,
    output logic [7:0] rgb_out
);

    assign rgb_out = rgb1 & rgb2 & rgb3 & rgb4;

endmodule
