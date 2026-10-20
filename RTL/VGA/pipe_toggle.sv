module pipe_toggle (
    input logic clk,
    input logic resetN,
    input logic reset_positions,
    input logic score_signal,
    input logic keyIsPressed_2,
    input logic keyIsPressed_8,
    output logic first_2,
    output logic first_8,
    output logic second_2,
    output logic second_8
);

logic toggle;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        toggle <= 1'b0;
    end
	 else if (reset_positions == 1'b1) begin
		  toggle <= 1'b0;
	 end
    else if (score_signal) begin
        toggle <= ~toggle;
    end
end

always_comb begin
    first_2 = 1'b0;
    first_8 = 1'b0;
    second_2 = 1'b0;
    second_8 = 1'b0;
    if (!toggle) begin
        first_2 = keyIsPressed_2;
        first_8 = keyIsPressed_8;
    end
    else begin
        second_2 = keyIsPressed_2;
        second_8 = keyIsPressed_8;
    end
end

endmodule