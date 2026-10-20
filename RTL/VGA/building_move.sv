// (c) Technion IIT, Department of Electrical Engineering 2025 
// Updated for building Movement

module building_move (
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // short pulse every start of frame (e.g. 60Hz)
    input  logic reset_positions,      
    input  logic [2:0] xBuildingSpeed,
    output logic signed [10:0] topLeftX      // output the top left X position
);

parameter int INITIAL_X = 640;

// Movement limits 
const int X_FRAME_LEFT = -193; // Reset after it goes completely off the left screen


int Xposition;
logic [2:0] bg_speed;

assign bg_speed = (xBuildingSpeed >= 3) ? (xBuildingSpeed - 2) : ((xBuildingSpeed == 0) ? 0 : 3'd1); // make sure the speed is not negative
 
always_ff @(posedge clk or negedge resetN)
begin
    if (resetN == 1'b0) begin 
        Xposition <= INITIAL_X; 
    end 
	else begin
        if (reset_positions) begin
            Xposition <= INITIAL_X; 
        end
        else if (startOfFrame) begin
            Xposition <= Xposition - bg_speed;
            
            if (Xposition <= X_FRAME_LEFT) begin
                Xposition <= Xposition + 852;
            end
        end
    end 
end

assign topLeftX = Xposition[10:0];

endmodule
