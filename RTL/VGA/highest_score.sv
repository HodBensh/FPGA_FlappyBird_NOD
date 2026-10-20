module highest_score (
    input  logic clk,
    input  logic resetN,
    input  logic show_game_over, 
    input  logic [3:0] current_score_ones,      // top left for examine if we need to add a score   
    input  logic [3:0] current_score_tens,      // top left for examine if we need to add a score   
    output logic [3:0] highest_score_ones,  
    output logic [3:0] highest_score_tens,
    output logic newRecord  
);

always @(posedge clk or negedge resetN)
begin
    if (!resetN) begin
        highest_score_ones <= 3'b0; 
        highest_score_tens <= 3'b0;
        newRecord <= 1'b0; 
    end 
    else if (show_game_over) begin
        if (
            (current_score_tens == highest_score_tens && current_score_ones > highest_score_ones)
            ||
            (current_score_tens > highest_score_tens)
        )
        begin
            highest_score_ones <= current_score_ones; 
            highest_score_tens <= current_score_tens; 
            newRecord <= 1'b1; 
        end
    end
    else begin
        newRecord <= 1'b0; 
    end
end

endmodule