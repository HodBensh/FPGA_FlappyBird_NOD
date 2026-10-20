module audioDecoder
	 (
	 input logic clk,
	 input logic resetN,
	 input logic startMode,
	 input logic gameOverMode,
	 input logic score_signal,
	 input logic darkMode,
	
	 output logic toneSignal,
	 output logic [3:0] toneValue   
);
logic startMode_d = 1'b0;
logic gameOverMode_d = 1'b0;
logic darkMode_d = 1'b0;


always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        startMode_d <= 1'b0;
		  gameOverMode_d <= 1'b0;
		  darkMode_d <= 1'b0;
		  toneSignal <= 1'b0;
    end else begin
			startMode_d <= startMode;
			gameOverMode_d <= gameOverMode;
			darkMode_d <= darkMode;
			if (startMode || (!gameOverMode_d && gameOverMode) || (!darkMode_d && darkMode) || score_signal) begin
				toneSignal <= 1'b1;
			end
			else begin
				toneSignal <= 1'b0;
			end
			if (startMode && !startMode_d) begin
				toneValue <= 4'd0; 
		   end
			else if (!startMode && startMode_d) begin
				toneValue <= 4'd15; 
		   end
		   else if (gameOverMode) begin
				toneValue <= 4'd3; 
			end
			else if (!darkMode_d && darkMode) begin
				toneValue <= 4'd2; 
			end
			else if (score_signal) begin
				toneValue <= 4'd1; 
			end
	 end
end



	 
endmodule