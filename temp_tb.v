
module tb;
  reg        clk;
  reg        rst;
  reg  [9:0] floor_req;
  reg        emer_stop;
  wire       move_up;
  wire       move_down;
  wire       motor_stop;
  wire [3:0] current_floor;

  lift_controller dut(
    .clk          (clk),
    .rst          (rst),
    .floor_req    (floor_req),
    .emer_stop    (emer_stop),
    .move_up      (move_up),
    .move_down    (move_down),
    .motor_stop   (motor_stop),
    .current_floor(current_floor)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    clk       = 0;
    rst       = 1;
    emer_stop = 0;
    floor_req = 10'd0;
    #60;           // hold reset longer than normal (6 full clock periods)
    rst = 0;
    #40;
    $display("FINAL_FLOOR=%0d", current_floor);
    $finish;
  end
endmodule
