// 10 floors = gnd + 9
module lift_controller(
    input clk,
    input rst,
    input [9:0] floor_req,
    input emer_stop,

    output reg move_up,
    output reg move_down,
    output reg motor_stop,

    output reg [3:0] current_floor
);


parameter IDLE      = 2'b00;
parameter MOVE_UP   = 2'b01;
parameter MOVE_DOWN = 2'b10;
parameter EMER      = 2'b11;

reg [1:0] current_state, next_state;
reg [3:0] target_floor;

// Priority Logic
// Highest priority given to lowest floor number

always @(*) begin

    target_floor = current_floor;

    if (floor_req[0])
        target_floor = 4'd0;
    else if (floor_req[1])
        target_floor = 4'd1;
    else if (floor_req[2])
        target_floor = 4'd2;
    else if (floor_req[3])
        target_floor = 4'd3;
    else if (floor_req[4])
        target_floor = 4'd4;
    else if (floor_req[5])
        target_floor = 4'd5;
    else if (floor_req[6])
        target_floor = 4'd6;
    else if (floor_req[7])
        target_floor = 4'd7;
    else if (floor_req[8])
        target_floor = 4'd8;
    else if (floor_req[9])
        target_floor = 4'd9;

end

// Present State Logic
always @(posedge clk) begin

    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;

end

// Floor Tracking Logic

always @(posedge clk) begin

    if (rst)
        current_floor <= 4'd0;

    else begin
        // Move up only if target not reached
        if (!emer_stop && current_state == MOVE_UP && current_floor < target_floor)
            current_floor <= current_floor + 1'b1;

        // Move down only if target not reached
        else if (!emer_stop && current_state == MOVE_DOWN && current_floor > target_floor)
            current_floor <= current_floor - 1'b1;

    end

end

// Next State Logic

always @(*) begin

    next_state = current_state;

    if (emer_stop)
        next_state = EMER;

    else begin

        case (current_state)

            IDLE: begin

                if (target_floor > current_floor)
                    next_state = MOVE_UP;

                else if (target_floor < current_floor)
                    next_state = MOVE_DOWN;

            end

            MOVE_UP: begin

                if (target_floor == current_floor)
                    next_state = IDLE;
                else
                    next_state = MOVE_UP;

            end

            MOVE_DOWN: begin

                if (target_floor == current_floor)
                    next_state = IDLE;
                else
                    next_state = MOVE_DOWN;

            end

            EMER: begin

                if (!emer_stop)
                    next_state = IDLE;
                else
                    next_state = EMER;

            end

            default:
                next_state = IDLE;

        endcase

    end

end

// Output Logic

always @(*) begin
    move_up   = 1'b0;
    move_down = 1'b0;
    motor_stop = 1'b0;

    case (current_state)

        MOVE_UP:
            move_up = 1'b1;

        MOVE_DOWN:
            move_down = 1'b1;

        EMER:
            motor_stop = 1'b1;

        IDLE:
            motor_stop = 1'b1;

    endcase
end
endmodule
