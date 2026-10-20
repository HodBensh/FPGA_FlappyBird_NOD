// Bird movement module - dynamic mid-air bouncing to a random target
module bird_move (  
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,      // Short pulse representing the start of a new frame[cite: 2]
    input  logic unsigned [9:0] target_hover_y,
    input  logic show_game_over,
    input  logic reset_positions,

    output logic signed [10:0] topLeftX, 
    output logic signed [10:0] topLeftY  
);

// Initial position and speed parameters
parameter int INITIAL_X = 100;     // Fixed position on the left side of the screen
parameter int INITIAL_Y = 240;     // Default starting height (matches the random module default)
parameter int JUMP_SPEED = -180;   // Upward speed applied at the bottom of each bounce
parameter int GRAVITY = 10;        // Downward pull

const int MAX_Y_SPEED = 400;       
const logic signed [10:0] FIXED_POINT_MULTIPLIER = 64; //[cite: 2]

// Absolute screen boundaries to prevent escaping the screen
const int OBJECT_HIGHT_Y = 32;
const int y_FRAME_TOP = 2 * FIXED_POINT_MULTIPLIER;
const int y_FRAME_BOTTOM = (479 - 2 - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER; //[cite: 2]

// Simplified state machine
enum logic [1:0] {
    IDLE_ST,             
    MOVE_ST,             
    POSITION_CHANGE_ST,  
    POSITION_LIMITS_ST   
} SM_Motion;

int Yspeed; 
int Yposition;  
int Xposition; 

// Temporary variables to resolve synthesis bit-extraction error
int topLeftX_tmp; 
int topLeftY_tmp;  

// Dynamic hover target converted to fixed-point for internal math
int dynamic_hover_bottom;
assign dynamic_hover_bottom = target_hover_y * FIXED_POINT_MULTIPLIER;

always_ff @(posedge clk or negedge resetN) begin
    if (resetN == 1'b0) begin 
        SM_Motion <= IDLE_ST; 
        Yspeed <= 0; 
        Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER; 
        Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
    end     
    else begin
        if (show_game_over) begin
            Yspeed <= 0; 
        end
        else if (reset_positions) begin
            Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER; 
            SM_Motion <= IDLE_ST; 
        end
        else begin
        case(SM_Motion)
        
            IDLE_ST: begin
                Yspeed  <= 0; 
                Xposition <= INITIAL_X * FIXED_POINT_MULTIPLIER; 
                Yposition <= INITIAL_Y * FIXED_POINT_MULTIPLIER; 

                if (startOfFrame) 
                    SM_Motion <= MOVE_ST;
					 end
    
            MOVE_ST: begin     
                if (startOfFrame) begin
                    SM_Motion <= POSITION_CHANGE_ST; 
                end 
            end 
        
            POSITION_CHANGE_ST: begin  
                Yposition <= Yposition + Yspeed; 
             
                // Apply gravity - increases downward speed every frame
                if (Yspeed < MAX_Y_SPEED) begin
                    Yspeed <= Yspeed + GRAVITY; 
                end
                
                SM_Motion <= POSITION_LIMITS_ST; 
            end
        
            POSITION_LIMITS_ST: begin  
                // 1. Absolute Ceiling limit (Safety)
                if (Yposition < y_FRAME_TOP) begin
                    Yposition <= y_FRAME_TOP;
                    Yspeed <= 0;
                end
                
                // 2. Absolute Floor limit (Safety)
                else if (Yposition > y_FRAME_BOTTOM) begin
                    Yposition <= y_FRAME_BOTTOM;
                    Yspeed <= JUMP_SPEED; // Force a jump if it somehow hits the actual floor
                end
                
                // 3. Dynamic Mid-Air Bouncing Logic:
                // Only flap if we are at or below the target height AND we are falling (Yspeed >= 0).
                // This allows the bird to climb naturally using multiple jumps without teleporting.
                if (Yposition >= dynamic_hover_bottom && Yspeed >= 0) begin 
                    Yspeed <= JUMP_SPEED; 
                end 

                SM_Motion <= MOVE_ST; 
            end
        endcase 
        end
    end 
end 

// Return from FIXED point trunc back to standard pixel format
assign topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER;   
assign topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER;   
assign topLeftX = {topLeftX_tmp[10:0]};   
assign topLeftY = {topLeftY_tmp[10:0]};    

endmodule
