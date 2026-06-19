module tb_lift_control;

reg clk;
reg rst;
reg [9:0] floor_req;
reg emer_stop;

wire move_up;
wire move_down;
wire motor_stop;
wire [3:0] current_floor;

// DUT Instantiation
lift_controller dut (
    .clk(clk),
    .rst(rst),
    .floor_req(floor_req),
    .emer_stop(emer_stop),
    .move_up(move_up),
    .move_down(move_down),
    .motor_stop(motor_stop),
    .current_floor(current_floor)
);

// Clock Generation
always #5 clk = ~clk;

initial begin

    // Waveform dump
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_lift_control);

    clk = 0;
    rst = 1;
    floor_req = 10'b0000000000;
    emer_stop = 0;

    // Reset release
    #20;
    rst = 0;

    // Test 1 : Move from GND to Floor 9
    #10;
    floor_req = 10'b1000000000;

    #120;
    floor_req = 10'b0000000000;

    // Test 2 : Move down to Floor 3
    #20;
    floor_req = 10'b0010000000;

    #100;
    floor_req = 10'b0000000000;

    // Test 3 : Multiple Requests
    // Lowest floor should get most priority
    #20;
    floor_req = 10'b1010010001;

    #120;
    floor_req = 10'b0000000000;

    // Test 4 : Emergency During Motion
    #20;
    floor_req = 10'b0100000000;

    #30;
    emer_stop = 1;

    #40;
    emer_stop = 0;

    #60;
    floor_req = 10'b0000000000;

    // Test 5 : Reset During Operation
    #20;
    floor_req = 10'b0000100000;

    #30;
    rst = 1;

    #20;
    rst = 0;
    floor_req = 10'b0000000000;

    // Finish simulation
    #100;
    $finish;

end

// Monitor
initial begin

    $monitor(
        "Time=%0t | Floor=%d | Req=%b | Up=%b | Down=%b | Stop=%b | Emer=%b",
        $time,
        current_floor,
        floor_req,
        move_up,
        move_down,
        motor_stop,
        emer_stop
    );

end

endmodule
