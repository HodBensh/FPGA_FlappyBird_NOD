module game_controller_fsm (
    input  logic clk,
    input  logic resetN,
    input  logic enter_key,       // "Enter" to start / restart
    input  logic collision_bird_pipe,       // Collision detected
    input  logic collision_bird_star,       // Collision detected
    input  logic [3:0] score_ones,
    input  logic [3:0] score_tens,
	input  logic switch1,
    input  logic star_done,
    input  logic score_signal,

    output logic shieldActive,
    output logic starMode,
    output logic [2:0] xPipeSpeed,    // Feeds into pipes to control movement
    output logic [2:0] xBuildingSpeed,    // Feeds into buildings to control movement
    output logic gameActiveMode,     // 1 during game, 0 otherwise (used to freeze the bird)
    output logic [1:0] difficulty,     
    output logic startMode,      // 1 during START state (to trigger your text drawing)
    output logic gameOverMode,   // 1 during GAME_OVER state (to trigger your text drawing)
    output logic reset_positions,
    output logic dark_mode        // 1 when score >= 50 during active gameplay

);

    // FSM States
    enum logic [3:0] {
        START_SCREEN,
        PLAYING_NORMAL,
        PLAYING_MEDIUM,
        PLAYING_HARD,
        PLAYING_ULTRA,
        STAR_MODE,
        GAME_OVER,
        RESET_POSITION
    } current_state, next_state;

    const logic [2:0] GAME_SPEED = 3'd3; 

    // Threshold where Dark Mode starts: score 50 (score_tens >= 5)
    // In Light mode (00-49): 00-09 Normal, 10-19 Medium, 20-39 Hard, 40-49 Ultra
    // In Dark mode  (50-99): 50-59 Normal, 60-69 Medium, 70-89 Hard, 90-99 Ultra
    const logic [3:0] DARK_MODE_START_TENS = 4'd5;

    // Dark mode is active ONLY during gameplay when score >= 50
    // Automatically disabled during START_SCREEN and GAME_OVER
    assign dark_mode = (gameActiveMode && (score_tens >= DARK_MODE_START_TENS) || switch1) ? 1'b1 : 1'b0;
    
    logic star_armed;
    logic [1:0] shield_counter;

    // resetN
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            current_state <= START_SCREEN;
            star_armed <= 1'b0;
            shield_counter <= 2'd0;
        end else begin
            current_state <= next_state;
            if (score_ones != 4'd5) begin
                star_armed <= 1'b1;
            end
            else if (current_state == STAR_MODE) begin
                star_armed <= 1'b0;
            end
            if (reset_positions) begin
                shield_counter <= 1'b0;
            end
            else if (current_state == STAR_MODE && collision_bird_star) begin
                shield_counter <= 2'd3;
            end
            else if (shield_counter != 2'd0 && score_signal == 1'b1) begin
                shield_counter <= shield_counter - 2'd1;
            end
        end
    end

    assign shieldActive = (shield_counter != 2'd0);
    
    // game controller logic
    always_comb begin
        next_state = current_state;
        xPipeSpeed = 3'd0;
        xBuildingSpeed = 3'd0;
        gameActiveMode = 1'b0;
        starMode = 1'b0;
        startMode = 1'b0;
        gameOverMode = 1'b0;
        reset_positions = 1'b0;
        difficulty = 2'b00;

        case (current_state)
            START_SCREEN: begin
                startMode = 1'b1;
                xBuildingSpeed = GAME_SPEED;
                
                if (enter_key) begin
                    next_state = PLAYING_NORMAL;
                end
            end

            PLAYING_NORMAL: begin
                xPipeSpeed = GAME_SPEED;  
                xBuildingSpeed = GAME_SPEED;
                gameActiveMode = 1'b1;   
                difficulty = 2'b00;
                
                if (collision_bird_pipe) begin
                    next_state = GAME_OVER;
                end 
                else if (star_armed && (score_ones == 4'd5)) begin
                    next_state = STAR_MODE;
                end
                // In Day (0-49): transitions to Medium at 10 (tens >= 1)
                // In Night (50-99): transitions to Medium at 60 (tens >= 6)
                else if ((score_tens >= 4'd1 && score_tens < DARK_MODE_START_TENS) || (score_tens >= 4'd6)) begin
                    next_state = PLAYING_MEDIUM;
                end
            end

            PLAYING_MEDIUM: begin
                xPipeSpeed = GAME_SPEED + 3'd1;  
                xBuildingSpeed = GAME_SPEED + 3'd1;
                gameActiveMode = 1'b1;  
                difficulty = 2'b01; 
                
                if (collision_bird_pipe) begin
                    next_state = GAME_OVER;
                end 
                else if (star_armed && (score_ones == 4'd5)) begin
                    next_state = STAR_MODE;
                end
                // In Day (0-49): transitions to Hard at 20 (tens >= 2)
                // In Night (50-99): transitions to Hard at 70 (tens >= 7)
                else if ((score_tens >= 4'd2 && score_tens < DARK_MODE_START_TENS) || (score_tens >= 4'd7)) begin
                    next_state = PLAYING_HARD;
                end
            end 

            PLAYING_HARD: begin
                xPipeSpeed = GAME_SPEED + 3'd2;  
                xBuildingSpeed = GAME_SPEED + 3'd2;
                gameActiveMode = 1'b1; 
                difficulty = 2'b10;  
                
                if (collision_bird_pipe) begin
                    next_state = GAME_OVER;
                end 
                else if (star_armed && (score_ones == 4'd5)) begin
                    next_state = STAR_MODE;
                end
                // In Day (0-49): transitions to Ultra at 40 (tens >= 4)
                // In Night (50-99): transitions to Ultra at 90 (tens >= 9)
                else if (score_tens == 4'd4 || score_tens >= 4'd9) begin
                    next_state = PLAYING_ULTRA;
                end
            end

            PLAYING_ULTRA: begin
                xPipeSpeed = GAME_SPEED + 3'd4;  
                xBuildingSpeed = GAME_SPEED + 3'd4;
                gameActiveMode = 1'b1; 
                difficulty = 2'b11;
                
                if (collision_bird_pipe) begin
                    next_state = GAME_OVER;
                end 
                else if (star_armed && (score_ones == 4'd5)) begin
                    next_state = STAR_MODE;
                end
                // At score 50 (tens == 5): return to PLAYING_NORMAL in Dark Mode!
                else if (score_tens >= DARK_MODE_START_TENS && score_tens < 4'd6) begin
                    next_state = PLAYING_NORMAL;
                end
            end

            STAR_MODE: begin
                xPipeSpeed = 3'd0;  
                xBuildingSpeed = 3'd1;
                gameActiveMode = 1'b1;   
                starMode = 1'b1;   
                
                if (collision_bird_star || star_done) begin
                    if (score_tens == 4'd0 || score_tens == 4'd5) begin
                        next_state = PLAYING_NORMAL;
                    end 
                    else if (score_tens == 4'd1 || score_tens == 4'd6) begin
                        next_state = PLAYING_MEDIUM;
                    end 
                    else if (score_tens == 4'd2 || score_tens == 4'd3 || score_tens == 4'd7 || score_tens == 4'd8) begin
                        next_state = PLAYING_HARD;
                    end 
                    else begin
                        next_state = PLAYING_ULTRA;
                    end 
                end 
            end

            // DARK_MODE: begin
            //     xPipeSpeed = GAME_SPEED;  
            //     xBuildingSpeed = GAME_SPEED;
            //     gameActiveMode = 1'b1;   
            //     
            //     if (collision) begin
            //         next_state = GAME_OVER;
            //     end 
            // end

            GAME_OVER: begin
                gameOverMode = 1'b1;
                
                if (enter_key) begin
                    next_state = RESET_POSITION; 
                end
            end

            RESET_POSITION: begin
                reset_positions = 1'b1;
                next_state = PLAYING_NORMAL;
            end
        endcase
    end

endmodule
