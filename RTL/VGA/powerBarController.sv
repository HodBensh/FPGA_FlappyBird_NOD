module powerBarController (
    input  logic       clk,
    input  logic       resetN,
    input  logic       reset_positions,
    input  logic       powerDown,    
    input  logic       powerUp,    

    output logic [3:0] power_level,     
    output int         Xspeed          
);

parameter int MIN_XSPEED = 370;
parameter int SPEED_STEP = 170;


logic key4_d, key6_d;


always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        power_level <= 4'd5; 
        key4_d      <= 1'b0;
        key6_d      <= 1'b0;
    end
    else if (reset_positions) begin
        power_level <= 4'd5;
    end
    else begin
        key4_d <= powerDown;
        key6_d <= powerUp;

        if (powerDown && !key4_d && power_level > 4'd0)
            power_level <= power_level - 4'd1;

        if (powerUp && !key6_d && power_level < 4'd9)
            power_level <= power_level + 4'd1;
    end
end

// ---- speed output (active always, star_move latches at shoot) ----
assign Xspeed = MIN_XSPEED + int'(power_level) * SPEED_STEP;

endmodule
