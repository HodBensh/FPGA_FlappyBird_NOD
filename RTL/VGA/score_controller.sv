module score_controller (
    input  logic clk,
    input  logic resetN,
    input  logic signed [10:0] topLeftX1,      // top left for examine if we need to add a score   
	 input  logic signed [10:0] topLeftX2,      // top left for examine if we need to add a score   
    output logic  score_signal       
);

parameter int BIRD_POSSITION_X = 100;
// parameter int PIPE_WIDTH = 100;
parameter int PIPE_WIDTH = 60;

logic pipe_passed1;
logic pipe_passed_d1;
logic pipe_passed2;
logic pipe_passed_d2;

assign pipe_passed1 = (BIRD_POSSITION_X > (topLeftX1 + PIPE_WIDTH));
assign pipe_passed2 = (BIRD_POSSITION_X > (topLeftX2 + PIPE_WIDTH));

always @(posedge clk or negedge resetN)
begin
    if (!resetN) begin
        pipe_passed_d1 <= 1'b0;
		  pipe_passed_d2 <= 1'b0;
        score_signal <= 0;
    end else begin
        pipe_passed_d1 <= pipe_passed1;
		  pipe_passed_d2 <= pipe_passed2;
        if ((pipe_passed1 && !pipe_passed_d1) || (pipe_passed2 && !pipe_passed_d2)) begin
            score_signal <= 1; 
        end else begin
            score_signal <= 0;   
        end

        /*
        if (pipe_passed && !pipe_passed_d) begin
            if (game_score_ones == 9) begin
                game_score_ones <= 0;
                if (game_score_tens == 9) begin
                    game_score_tens <= 0;
                end else begin
                    game_score_tens <= game_score_tens + 1;
                end
            end else begin
                game_score_ones <= game_score_ones + 1;
            end
        end
        */

    end
end

endmodule