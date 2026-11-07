`timescale 1ns/1ps
// Intentional malformed master cases. Each starts in an independent reset epoch.
module apb64_protocol_negative;
  logic PCLK=0,PRESETn=0,PSEL=0,PENABLE=0,PWRITE=0;
  logic [7:0] PADDR=0;
  logic [31:0] PWDATA=0;
  int violations;
  apb64_monitor #(.FATAL(0)) mon(.*);
  always #5 PCLK=~PCLK;
  task automatic reset_case;
    @(negedge PCLK); PRESETn=0; PSEL=0; PENABLE=0;
    repeat(2) @(negedge PCLK);
    PRESETn=1;
  endtask
  initial begin
    reset_case();
    PSEL=1; PENABLE=1; PADDR=8'h00;
    @(posedge PCLK); #1;
    if(violations!==1) $fatal(1,"APB64_NEGATIVE_UNDETECTED ACCESS_WITHOUT_SETUP got=%0d",violations);
    $display("APB64_NEGATIVE_CASE_PASS access_without_setup");

    reset_case();
    PSEL=1; PENABLE=0; PWRITE=0; PADDR=8'h00;
    @(posedge PCLK);
    @(negedge PCLK); PENABLE=1; PADDR=8'h04;
    @(posedge PCLK); #1;
    if(violations!==1) $fatal(1,"APB64_NEGATIVE_UNDETECTED CONTROL_CHANGED got=%0d",violations);
    $display("APB64_NEGATIVE_CASE_PASS address_changed");

    reset_case();
    PSEL=1; PENABLE=0; PWRITE=1; PADDR=8'hFC; PWDATA=32'h12345678;
    @(posedge PCLK);
    @(negedge PCLK); PENABLE=1; PWDATA=32'h87654321;
    @(posedge PCLK); #1;
    if(violations!==1) $fatal(1,"APB64_NEGATIVE_UNDETECTED WRITE_DATA_CHANGED got=%0d",violations);
    $display("APB64_NEGATIVE_CASE_PASS write_data_changed");

    reset_case();
    PSEL=1; PENABLE=0; PWRITE=0; PADDR=8'h00;
    @(posedge PCLK);
    @(negedge PCLK); PENABLE=1;
    @(posedge PCLK);
    @(negedge PCLK); PENABLE=0; PWRITE=1; PADDR=8'hFC; PWDATA=32'hA5A55A5A;
    @(posedge PCLK);
    @(negedge PCLK); PENABLE=1;
    @(posedge PCLK); #1;
    if(violations!==0) $fatal(1,"APB64_MONITOR_FALSE_POSITIVE got=%0d",violations);
    $display("APB64_NEGATIVE_CASE_PASS legal_back_to_back");
    $display("APB64_NEGATIVE_PASS cases=3 legal=1");
    $finish;
  end
  initial begin #10000; $fatal(1,"APB64_NEGATIVE_TIMEOUT"); end
endmodule
