module star_move (  
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,
    input  logic upKeyPressed,        
    input  logic downKeyPressed,
    input  logic shootKeyPressed,
    input  logic star_start,        // 1-clk pulse from game_controller
    input  logic collision_bird_star,          // 1-clk pulse from game_controller
    input  logic reset_positions,
    input  int   Xspeed,            // from powerBarController (= 370 + level*170)
    output logic signed [10:0] topLeftX, 
    output logic signed [10:0] topLeftY,
    output logic star_visible,      // gate for starBitmap
    output logic aiming,            // gate for powerBarBitMap
    output logic star_done          // 1-clk pulse (hit / floor / left edge)
);

parameter int INITIAL_X  = 580;
parameter int INITIAL_Y  = 224;     // vertical center: (480-32)/2
parameter int GRAVITY    = 8;

const logic signed [10:0] FIXED_POINT_MULTIPLIER = 64;
const int OBJECT_HIGHT_Y = 32;
const int Y_MIN = 2 * FIXED_POINT_MULTIPLIER;
const int X_MIN = 2 * FIXED_POINT_MULTIPLIER;
const int Y_MAX = (479 - 2 - OBJECT_HIGHT_Y) * FIXED_POINT_MULTIPLIER;
const int player_Yspeed = 256;

enum logic [2:0] {
    HIDDEN_ST,
    AIM_ST,
    MOVE_ST,
    POSITION_CHANGE_ST,
    POSITION_LIMITS_ST,
    DONE_ST
} SM_Star;

int Xspeed_latched;   // latched at shoot time
int Yspeed;
int Yposition;
int Xposition;
int topLeftX_tmp; 
int topLeftY_tmp;

logic shoot_d;    // previous value of shoot key (edge detect)

always_ff @(posedge clk or negedge resetN) begin
    if (resetN == 1'b0) begin 
        SM_Star        <= HIDDEN_ST;
        Xspeed_latched <= 0;
        Yspeed         <= 0; 
        Xposition      <= INITIAL_X * FIXED_POINT_MULTIPLIER; 
        Yposition      <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
        shoot_d        <= 1'b0;
        star_done      <= 1'b0;
    end
    else if (reset_positions) begin
        SM_Star   <= HIDDEN_ST;
        star_done <= 1'b0;
    end
    else begin
        shoot_d   <= shootKeyPressed;
        star_done <= 1'b0; // default (pulse)

        case(SM_Star)

            HIDDEN_ST: begin
                if (star_start) begin
                    Xposition      <= INITIAL_X * FIXED_POINT_MULTIPLIER; 
                    Yposition      <= INITIAL_Y * FIXED_POINT_MULTIPLIER;
                    Xspeed_latched <= 0;
                    Yspeed         <= 0;
                    SM_Star        <= AIM_ST;
                end
            end

            AIM_ST: begin
                if (startOfFrame && upKeyPressed) begin
                    if (Yposition - player_Yspeed >= Y_MIN)
                        Yposition <= Yposition - player_Yspeed;
                    else
                        Yposition <= Y_MIN;
                end
                if (startOfFrame && downKeyPressed) begin
                    if (Yposition + player_Yspeed <= Y_MAX)
                        Yposition <= Yposition + player_Yspeed;
                    else
                        Yposition <= Y_MAX;
                end

                // key 5 rising edge -> shoot
                if (shootKeyPressed && !shoot_d) begin
                    Xspeed_latched <= Xspeed;  // latch current speed
                    Yspeed         <= 0;
                    SM_Star        <= MOVE_ST;
                end
            end

            MOVE_ST: begin // wait for startOfFrame (fixes frame-skip bug)
                if (startOfFrame)
                    SM_Star <= POSITION_CHANGE_ST;
            end

            POSITION_CHANGE_ST: begin
                Xposition <= Xposition - Xspeed_latched;
                Yposition <= Yposition + Yspeed;
                Yspeed    <= Yspeed + GRAVITY;
                SM_Star   <= POSITION_LIMITS_ST;
            end

            POSITION_LIMITS_ST: begin
                if (Yposition > Y_MAX || Xposition < X_MIN)
                    SM_Star <= DONE_ST;
                else
                    SM_Star <= MOVE_ST;
            end

            DONE_ST: begin
                star_done <= 1'b1;
                SM_Star   <= HIDDEN_ST;
            end

            default: SM_Star <= HIDDEN_ST;
        endcase

        // hit during flight -> finish immediately
        if (collision_bird_star && (SM_Star == MOVE_ST || SM_Star == POSITION_CHANGE_ST
                         || SM_Star == POSITION_LIMITS_ST))
            SM_Star <= DONE_ST;
    end 
end

assign star_visible = (SM_Star != HIDDEN_ST) && (SM_Star != DONE_ST);
assign aiming       = (SM_Star == AIM_ST);

assign topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER;   
assign topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER;   
assign topLeftX = {topLeftX_tmp[10:0]};   
assign topLeftY = {topLeftY_tmp[10:0]};

endmodule
