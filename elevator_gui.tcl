package require Tk

namespace eval elevator {
    variable currentFloor 0
    variable statusText   "IDLE"
}

wm title . "10 Floor Elevator FSM"

proc set_buttons_state {state} {
    for {set i 0} {$i <= 9} {incr i} {
        .b$i configure -state $state
    }
    .emer  configure -state $state
    .reset configure -state $state
    .wave  configure -state $state
}

proc run_simulation {tb_body} {
    set fp [open "temp_tb.v" w]
    puts $fp $tb_body
    close $fp

    if {[catch {exec iverilog -o lift_sim elevator_fsm.v temp_tb.v} err]} {
        set elevator::statusText "COMPILE ERROR"
        tk_messageBox \
            -title   "Compile Error" \
            -icon    error \
            -message "iverilog failed:\n$err"
        return ""
    }

    if {[catch {exec vvp lift_sim} simout]} {
        if {$simout eq ""} {
            set elevator::statusText "SIM ERROR"
            tk_messageBox \
                -title   "Simulation Error" \
                -icon    error \
                -message "vvp produced no output."
            return ""
        }
        return $simout
    }
    return $simout
}

proc run_lift {floor} {
    set_buttons_state disabled
    set elevator::statusText "Simulating → Floor $floor …"
    update idletasks   ;

    set req_val [expr {1 << $floor}]

    set distance [expr {abs($floor - $elevator::currentFloor)}]
    set travel   [expr {max($distance, 1) * 80}]  ;
    set settle   100                               ;

    set tb_top {
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
    #30;
    rst = 0;
    #10;
}

    set tb_mid "    floor_req = 10'd${req_val};\n    #${travel};\n    floor_req = 10'd0;\n    #${settle};"
    set tb_bot {
    $display("FINAL_FLOOR=%0d", current_floor);
    $finish;
  end
endmodule
}
    set tb_body "${tb_top}\n${tb_mid}\n${tb_bot}"

    set simout [run_simulation $tb_body]

    if {$simout ne ""} {
        if {[regexp {FINAL_FLOOR=(\d+)} $simout -> parsed]} {
            set elevator::currentFloor $parsed
            set elevator::statusText   "Arrived at Floor $parsed"
        } else {
            set elevator::currentFloor $floor
            set elevator::statusText   "Moved to Floor $floor (unverified)"
        }
    }

    set_buttons_state normal
}

proc emergency_stop {} {
    set_buttons_state disabled
    set elevator::statusText "EMERGENCY STOP in progress …"
    update idletasks

    set tb_body {
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
    #30;
    rst       = 0;
    #10;
    emer_stop = 1;   // assert emergency
    #100;
    emer_stop = 0;   // release
    #50;
    $display("FINAL_FLOOR=%0d", current_floor);
    $finish;
  end
endmodule
}

    set simout [run_simulation $tb_body]

    if {$simout ne ""} {
        if {[regexp {FINAL_FLOOR=(\d+)} $simout -> parsed]} {
            set elevator::currentFloor $parsed
        }
    }
    set elevator::statusText "EMERGENCY STOP – halted at Floor $elevator::currentFloor"

    tk_messageBox \
        -title   "Emergency" \
        -icon    warning \
        -message "Emergency Stop executed!\nElevator halted at Floor $elevator::currentFloor."

    set_buttons_state normal
}

proc reset_lift {} {
    set_buttons_state disabled
    set elevator::statusText "Resetting …"
    update idletasks

    set tb_body {
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
    #60;           
    rst = 0;
    #40;
    $display("FINAL_FLOOR=%0d", current_floor);
    $finish;
  end
endmodule
}

    set simout [run_simulation $tb_body]
    set elevator::currentFloor 0
    set elevator::statusText   "RESET – back at Ground Floor"
    set_buttons_state normal
}

wm geometry . "600x500"

for {set c 0} {$c <= 4} {incr c} {
    grid columnconfigure . $c -weight 1 -minsize 100
}

for {set r 0} {$r <= 7} {incr r} {
    grid rowconfigure . $r -pad 4
}

label .title \
    -text "10 Floor Elevator Controller" \
    -font "Helvetica 18 bold"
grid .title -row 0 -column 0 -columnspan 5 -pady 10

label .floorLabel \
    -text "Current Floor:" \
    -font "Helvetica 14"
label .floorDisplay \
    -textvariable elevator::currentFloor \
    -width 5 \
    -bg black \
    -fg lime \
    -font "Helvetica 20 bold"
grid .floorLabel   -row 1 -column 0 -columnspan 2
grid .floorDisplay -row 1 -column 2 -columnspan 2

label .status \
    -textvariable elevator::statusText \
    -width 40 \
    -bg navy \
    -fg white \
    -font "Helvetica 12 bold"
grid .status -row 2 -column 0 -columnspan 5 -pady 10

for {set i 0} {$i <= 9} {incr i} {
    button .b$i \
        -text    "Floor $i" \
        -width   12 \
        -height  2 \
        -command "run_lift $i"
    set r [expr {3 + ($i / 5)}]
    set c [expr {$i % 5}]
    grid .b$i -row $r -column $c -padx 5 -pady 5
}

button .emer \
    -text    "EMERGENCY" \
    -bg      red \
    -fg      white \
    -width   15 \
    -height  2 \
    -command emergency_stop
grid .emer -row 6 -column 0 -columnspan 2 -pady 10

button .reset \
    -text    "RESET" \
    -bg      orange \
    -width   15 \
    -height  2 \
    -command reset_lift
grid .reset -row 6 -column 2 -columnspan 2 -pady 10

button .exit \
    -text    "EXIT" \
    -bg      gray \
    -fg      white \
    -width   15 \
    -height  2 \
    -command exit
grid .exit -row 6 -column 4 -pady 10

button .wave \
    -text    "OPEN GTKWAVE" \
    -bg      lightblue \
    -width   15 \
    -height  2 \
    -command {
        if {![file exists wave.vcd]} {
            tk_messageBox \
                -title   "No waveform" \
                -icon    warning \
                -message "wave.vcd not found.\nRun a simulation first."
        } else {
            catch {exec env LIBGL_ALWAYS_SOFTWARE=1 gtkwave wave.vcd &}
        }
    }
grid .wave -row 7 -column 2 -pady 10
