`timescale 1ns/1ps
// Pre-edge master sequencing checker; FATAL=0 is for isolated negative tests.
module apb64_monitor #(parameter bit FATAL=1)(
  input logic PCLK,PRESETn,PSEL,PENABLE,PWRITE,
  input logic [7:0] PADDR,
  input logic [31:0] PWDATA,
  output int violations
);
  bit setup_seen;
  logic [7:0] held_addr;
  logic [31:0] held_data;
  bit held_write;
  task automatic bad(input string reason);
    violations++;
    $display("APB64_MONITOR_VIOLATION %s",reason);
    if(FATAL) $fatal(1,"APB64_MONITOR %s",reason);
  endtask
  always @(posedge PCLK or negedge PRESETn) begin
    if(!PRESETn) begin
      setup_seen=0; violations=0;
      held_addr=0; held_data=0; held_write=0;
    end else if(PSEL && PENABLE) begin
      if(!setup_seen) bad("ACCESS_WITHOUT_SETUP");
      else if(PADDR !== held_addr || PWRITE !== held_write ||
              (PWRITE && PWDATA !== held_data)) bad("CONTROL_CHANGED_IN_ACCESS");
      setup_seen=0;
    end else if(PSEL && !PENABLE) begin
      setup_seen=1;
      held_addr=PADDR; held_write=PWRITE; held_data=PWDATA;
    end else setup_seen=0;
  end
endmodule
