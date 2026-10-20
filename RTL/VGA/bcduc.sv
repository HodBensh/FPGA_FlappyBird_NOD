// (c) Technion IIT, Department of Electrical Engineering 2022 
// Written By Liat Schwartz August 2018 
// Updated by Mor Dahan - January 2022

// Implements a BCD up counter 0 up to 99 with several enable inputs and loadN data
// having countL, countH and tc outputs
// by instantiating two one bit up-counters


module bcduc
	(
	input  logic clk, 
	input  logic resetN, 
	input  logic loadN, 
	input  logic enable1, 
	input  logic enable2, 
	input  logic score_signal,
    
	output logic [3:0] countL, 
	output logic [3:0] countH,
	output logic tc
   );

	parameter  logic [3:0] datainL = 4'h0 ; 
	parameter  logic [3:0] datainH = 4'h0 ;
	
	logic  tclow, tchigh;// internal variables terminal count 
	
// Low counter instantiation
	up_counter ones(.clk(clk), 
							.resetN(resetN),
							.loadN(loadN),	
							.enable1(enable1), 
							.enable2(enable2),
							.enable3(score_signal), 	
							.datain(datainL), 
							.count(countL), 
							.tc(tclow) );

	
// High counter instantiation

	up_counter tens(.clk(clk), 
							.resetN(resetN),
							.loadN(loadN),	
							.enable1(enable1), 
							.enable2(enable2),
							.enable3(tclow && score_signal), 	
							.datain(datainH), 
							.count(countH), 
							.tc(tchigh) );

//------------------------------------------------------------------------------------------ 
 assign tc =  tclow && tchigh;	//  ## initializing a variable to enable compilation, change if needed 
//--------------------------------------------------------------------------------------------------------------------			

endmodule
