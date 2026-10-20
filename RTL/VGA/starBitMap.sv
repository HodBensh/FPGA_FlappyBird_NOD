// Drawing a symmetric 32x32 Star with clean RTL lookup
module starBitmap (
    input  logic clk,
    input  logic resetN,
    input  logic [10:0] offsetX,         // from pipe_object 
    input  logic [10:0] offsetY,         // from pipe_object 
    input  logic InsideRectangle,        // drawingRequest from pipe_object
    input  logic visible,        // visible in the game

    output logic drawingRequest,
    output logic [7:0] RGBout
);

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

// RGB332 Colors
localparam logic [7:0] COLOR_BLACK  = 8'b000_000_00; 
localparam logic [7:0] COLOR_YELLOW = 8'b111_111_00;
localparam logic [7:0] COLOR_WHITE  = 8'b111_111_10;

logic [7:0] color;
logic [4:0] x;
logic [4:0] y;

// קידוד פנימי נוח לציור בטבלה:
// 0 = שקוף, 1 = שחור (מסגרת/עין), 2 = צהוב (גוף), 3 = לבן (הברקה בעין)
logic [1:0] pixel_code;

// שימוש ב-5 הביטים הנמוכים בלבד (0 עד 31)
assign x = offsetX[4:0];
assign y = offsetY[4:0];

always_comb begin
    pixel_code = 2'd0; // ברירת מחדל: שקוף

    if (offsetX <= 31 && offsetY <= 31) begin
        case (y)
            // --- שפיץ עליון ---
            5'd2:  if (x >= 15 && x <= 16) pixel_code = 2'd1;
            5'd3:  if (x == 14 || x == 17) pixel_code = 2'd1;
                   else if (x >= 15 && x <= 16) pixel_code = 2'd2;
            5'd4:  if (x == 14 || x == 17) pixel_code = 2'd1;
                   else if (x >= 15 && x <= 16) pixel_code = 2'd2;
            5'd5:  if (x == 13 || x == 18) pixel_code = 2'd1;
                   else if (x >= 14 && x <= 17) pixel_code = 2'd2;
            5'd6:  if (x == 13 || x == 18) pixel_code = 2'd1;
                   else if (x >= 14 && x <= 17) pixel_code = 2'd2;
            5'd7:  if (x == 12 || x == 19) pixel_code = 2'd1;
                   else if (x >= 13 && x <= 18) pixel_code = 2'd2;
            5'd8:  if (x == 12 || x == 19) pixel_code = 2'd1;
                   else if (x >= 13 && x <= 18) pixel_code = 2'd2;
            5'd9:  if (x == 11 || x == 20) pixel_code = 2'd1;
                   else if (x >= 12 && x <= 19) pixel_code = 2'd2;
            5'd10: if (x == 11 || x == 20) pixel_code = 2'd1;
                   else if (x >= 12 && x <= 19) pixel_code = 2'd2;

            // --- קו אופקי של הזרועות ---
            5'd11: if ((x >= 1 && x <= 11) || (x >= 20 && x <= 30)) pixel_code = 2'd1;
                   else if (x >= 12 && x <= 19) pixel_code = 2'd2;

            // --- גוף הכוכב והזרועות (כולל עיניים בשורות 14-19) ---
            5'd12: if (x == 1 || x == 30) pixel_code = 2'd1;
                   else if (x >= 2 && x <= 29) pixel_code = 2'd2;
            5'd13: if (x == 2 || x == 29) pixel_code = 2'd1;
                   else if (x >= 3 && x <= 28) pixel_code = 2'd2;
            5'd14, 5'd15: begin
                   if (x == (y - 11) || x == (31 - (y - 11))) pixel_code = 2'd1;
                   else if ((x >= 11 && x <= 12) || (x >= 19 && x <= 20)) pixel_code = 2'd3; // הברקה לבנה בעין
                   else if (x > (y - 11) && x < (31 - (y - 11))) pixel_code = 2'd2;
            end
            5'd16, 5'd17, 5'd18, 5'd19: begin
                   if (x == (y - 11) || x == (31 - (y - 11))) pixel_code = 2'd1;
                   else if ((x >= 11 && x <= 12) || (x >= 19 && x <= 20)) pixel_code = 2'd1; // אישון שחור
                   else if (x > (y - 11) && x < (31 - (y - 11))) pixel_code = 2'd2;
            end
            5'd20: if (x == 9 || x == 22) pixel_code = 2'd1;
                   else if (x >= 10 && x <= 21) pixel_code = 2'd2;

            // --- אגן ופיצול רגליים ---
            5'd21: if (x == 8 || x == 23 || (x >= 15 && x <= 16)) pixel_code = 2'd1;
                   else if ((x >= 9 && x <= 14) || (x >= 17 && x <= 22)) pixel_code = 2'd2;
            5'd22: if (x == 8 || x == 23 || x == 14 || x == 17) pixel_code = 2'd1;
                   else if ((x >= 9 && x <= 13) || (x >= 18 && x <= 22)) pixel_code = 2'd2;
            5'd23: if (x == 7 || x == 24 || x == 13 || x == 18) pixel_code = 2'd1;
                   else if ((x >= 8 && x <= 12) || (x >= 19 && x <= 23)) pixel_code = 2'd2;
            5'd24: if (x == 7 || x == 24 || x == 12 || x == 19) pixel_code = 2'd1;
                   else if ((x >= 8 && x <= 11) || (x >= 20 && x <= 23)) pixel_code = 2'd2;
            5'd25: if (x == 6 || x == 25 || x == 11 || x == 20) pixel_code = 2'd1;
                   else if ((x >= 7 && x <= 10) || (x >= 21 && x <= 24)) pixel_code = 2'd2;
            5'd26: if (x == 6 || x == 25 || x == 10 || x == 21) pixel_code = 2'd1;
                   else if ((x >= 7 && x <= 9) || (x >= 22 && x <= 24)) pixel_code = 2'd2;
            5'd27: if (x == 5 || x == 26 || x == 9 || x == 22) pixel_code = 2'd1;
                   else if ((x >= 6 && x <= 8) || (x >= 23 && x <= 25)) pixel_code = 2'd2;
            5'd28: if (x == 5 || x == 26 || x == 8 || x == 23) pixel_code = 2'd1;
                   else if ((x >= 6 && x <= 7) || (x >= 24 && x <= 25)) pixel_code = 2'd2;
            5'd29: if ((x >= 4 && x <= 7) || (x >= 24 && x <= 27)) pixel_code = 2'd1;

            default: pixel_code = 2'd0;
        endcase
    end

    // המרת הקוד לצבע הסופי
    case (pixel_code)
        2'd1: color = COLOR_BLACK;
        2'd2: color = COLOR_YELLOW;
        2'd3: color = COLOR_WHITE;
        default: color = TRANSPARENT_ENCODING;
    endcase
end

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        RGBout <= 8'h00;
    end else begin
        RGBout <= TRANSPARENT_ENCODING; 
        //if (InsideRectangle == 1'b1 && color != TRANSPARENT_ENCODING) begin 
        if (InsideRectangle == 1'b1 && visible == 1'b1 && color != TRANSPARENT_ENCODING) begin 
            RGBout <= color;
        end     
    end
end

// drawing request
assign drawingRequest = (RGBout != TRANSPARENT_ENCODING) ? 1'b1 : 1'b0; 

endmodule