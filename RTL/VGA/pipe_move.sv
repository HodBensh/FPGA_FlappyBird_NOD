// (c) Technion IIT, Department of Electrical Engineering 2025 
// Updated for Pipe Movement

module pipe_move (
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // short pulse every start of frame (e.g. 60Hz)
    input  logic upKeyPressed,        
    input  logic downKeyPressed,    
    input  logic game_active,      
    input  logic reset_positions,      
    input  logic [2:0] xPipeSpeed,
    input  logic [7:0] randomY,
    input  logic [1:0] difficulty,
    
    
    output logic signed [10:0] topLeftX,      
    output logic signed [10:0] transparentGapY,  
    output logic [7:0]  gap_height        
);

parameter int INITIAL_X = 640;
parameter int INITIAL_Y = 210; 

// const int X_FRAME_LEFT = -60; 
const int X_FRAME_LEFT = -100;  // -100 so spacing between pipes is ok.
const int Y_MIN = 50;
const int Y_MAX_LIMIT = 430; // (480 total height) - (150 gap) - (50 bottom border) = 280
const int RESET_X = 640;

int Y_MAX;
assign Y_MAX = Y_MAX_LIMIT - gap_height;

int y_speed;
always_comb begin
    case (difficulty)
        2'd0: y_speed = 6;   // Normal
        2'd1: y_speed = 8;   // Medium
        2'd2: y_speed = 10;  // Hard
        2'd3: y_speed = 14;  // Ultra
        default: y_speed = 6;
    endcase
end


int Xposition;
int Yposition;

// logic upKeyPressed_D;
// logic downKeyPressed_D;
 
always_ff @(posedge clk or negedge resetN)
begin
    if (resetN == 1'b0) begin 
        Xposition        <= INITIAL_X; 
        Yposition        <= INITIAL_Y; 
        gap_height       <= 8'd150; // Normal
//        upKeyPressed_D   <= 1'b0;
//        downKeyPressed_D <= 1'b0;
    end 
    else if (reset_positions) begin
        Xposition        <= INITIAL_X; 
        Yposition        <= INITIAL_Y; 
        gap_height       <= 8'd150; // Normal
//        upKeyPressed_D   <= 1'b0;
//        downKeyPressed_D <= 1'b0;
    end
	else begin
        // upKeyPressed_D   <= upKeyPressed;
        // downKeyPressed_D <= downKeyPressed;

        if (startOfFrame) begin
            Xposition <= Xposition - xPipeSpeed;
				
            
            if (Xposition <= X_FRAME_LEFT) begin
                Xposition <= RESET_X;
                Yposition <= Y_MIN + (randomY * 5);
                case (difficulty)
                    2'd0: gap_height <= 8'd150;  // Normal
                    2'd1: gap_height <= 8'd145;  // Medium
                    2'd2: gap_height <= 8'd140;  // Hard
                    2'd3: gap_height <= 8'd135;  // Ultra
                    default: gap_height <= 8'd150;
                endcase
            end
        end
        
//        if (upKeyPressed && !upKeyPressed_D && game_active) begin
		  if (upKeyPressed && startOfFrame && game_active) begin
            if (Yposition - y_speed >= Y_MIN) begin
                Yposition <= Yposition - y_speed;
            end 
			/*
			needed only if the initial Y position is not aligen with the 40 gap.
			*/
				else begin
                Yposition <= Y_MIN;
            end 
        end
        
//        if (downKeyPressed && !downKeyPressed_D && game_active) begin
		  if (downKeyPressed && startOfFrame && game_active) begin
            if (Yposition + y_speed <= Y_MAX) begin
                Yposition <= Yposition + y_speed;
            end
			/*
				needed only if the initial Y position is not aligen with the 40 gap.
			*/ 
				else begin
                Yposition <= Y_MAX;
            end
        end
    end 
end

assign topLeftX        = Xposition[10:0];
assign transparentGapY = Yposition[10:0];

endmodule
