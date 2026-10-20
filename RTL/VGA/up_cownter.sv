// (c) Technion IIT, Department of Electrical Engineering 2022 
// Updated by Mor Dahan - January 2022

// Implements a 4 bits down counter 9 down to 0 with several enable inputs and loadN data.
// It outputs count and asynchronous terminal count, tc, signal 

module up_counter
	(
	input logic clk, 
	input logic resetN, 
	input logic loadN, 
	input logic enable1,
	input logic enable2, 
	input logic enable3, 
	input logic [3:0] datain,
	
	output logic [3:0] count,
	output logic tc
	);

// up counter
always_ff @(posedge clk or negedge resetN)
	begin
			
		if ( !resetN )	begin// Asynchronic reset
			
			count <= 4'h0;
			
		end

		else if (!loadN) begin
				count <= datain;
		end
		
		else if (enable1 && enable2 && enable3) begin 
			if (count == 9) begin
				count <= 4'h0;
			end
			else begin
				count <= count + 4'h1;
			end
		end

	end //always

	
	// Asynchronic tc

	assign tc =  (count == 9) ? 1'b1 : 1'b0; //## initializing a variable to enable compilation, change if needed 

	
endmodule
