`timescale 1ns/1ps
// Independent 64-word memory oracle and pre-edge APB acceptance monitor.
module apb64_contract_test;
  logic PCLK=0;
  always #5 PCLK=~PCLK;
  apb_if bus(PCLK);
  apb_ram dut(bus);
  logic [31:0] reference_mem[0:63];
  bit setup_seen=0;
  logic [7:0] setup_addr;
  logic [31:0] setup_data;
  bit setup_write;
  int checks=0, issued=0, accepted=0, writes=0, reads=0;
  int alias_probes=0, reset_cases=0, back_to_back=0;
  int protocol_violations;
  apb64_monitor #(.FATAL(1)) protocol(PCLK,bus.PRESETn,bus.PSEL,bus.PENABLE,
      bus.PWRITE,bus.PADDR,bus.PWDATA,protocol_violations);
  int unsigned rng=32'h28ab6407;

  function automatic logic [31:0] next_word();
    rng ^= rng << 13;
    rng ^= rng >> 17;
    rng ^= rng << 5;
    return rng;
  endfunction
  task automatic clear_reference;
    for(int i=0;i<64;i++) reference_mem[i]=0;
  endtask
  task automatic idle;
    bus.PSEL=0; bus.PENABLE=0; bus.PWRITE=0;
    bus.PADDR=0; bus.PWDATA=0;
  endtask
  task automatic check_pins(input string label);
    logic [31:0] wanted;
    wanted=(bus.PSEL && !bus.PWRITE) ? reference_mem[bus.PADDR[7:2]] : 0;
    #1;
    if(bus.PREADY !== 1 || bus.PSLVERR !== 0 || bus.PRDATA !== wanted)
      $fatal(1,"APB64_MISMATCH %s addr=%02h sel=%b en=%b wr=%b expected=%08h observed=%08h/%b/%b",
             label,bus.PADDR,bus.PSEL,bus.PENABLE,bus.PWRITE,wanted,bus.PRDATA,bus.PREADY,bus.PSLVERR);
    checks++;
  endtask

  // This model observes acceptance independently of driver intent.
  always @(posedge PCLK or negedge bus.PRESETn) begin
    if(!bus.PRESETn) begin
      clear_reference();
      setup_seen=0;
    end else begin
      if(bus.PSEL && !bus.PENABLE) begin
        setup_seen=1;
        setup_addr=bus.PADDR; setup_data=bus.PWDATA; setup_write=bus.PWRITE;
      end else if(bus.PSEL && bus.PENABLE && bus.PREADY) begin
        if(!setup_seen || bus.PADDR !== setup_addr || bus.PWRITE !== setup_write ||
           (bus.PWRITE && bus.PWDATA !== setup_data))
          $fatal(1,"APB64_MASTER_SEQUENCE access without stable setup");
        accepted++;
        if(bus.PWRITE) begin
          reference_mem[bus.PADDR[7:2]]=bus.PWDATA;
          writes++;
        end else reads++;
        setup_seen=0;
      end else if(!bus.PSEL) setup_seen=0;
    end
  end

  task automatic transfer(input logic [7:0] address,input bit write_enable,
                          input logic [31:0] value,input bit hold_select);
    @(negedge PCLK);
    bus.PSEL=1; bus.PENABLE=0; bus.PWRITE=write_enable;
    bus.PADDR=address; bus.PWDATA=value;
    check_pins("setup");
    @(negedge PCLK); bus.PENABLE=1;
    check_pins("access before acceptance");
    @(posedge PCLK); #1;
    issued++;
    if(accepted != issued) $fatal(1,"APB64_ACCEPT_COUNT issued=%0d accepted=%0d",issued,accepted);
    check_pins("post acceptance");
    if(!hold_select) begin
      @(negedge PCLK); idle(); check_pins("idle");
    end else back_to_back++;
  endtask

  task automatic read_all(input string label);
    for(int i=0;i<64;i++) transfer((i*4),0,0,0);
  endtask

  task automatic reset_and_read(input int mode);
    if(mode==0) begin
      @(negedge PCLK); idle(); #2; bus.PRESETn=0;
    end else if(mode==1) begin
      @(negedge PCLK); bus.PSEL=1; bus.PENABLE=0;
      bus.PWRITE=1; bus.PADDR=8'hFC; bus.PWDATA=32'hBADC0FFE;
      #2; bus.PRESETn=0;
    end else begin
      @(negedge PCLK); bus.PSEL=1; bus.PENABLE=0;
      bus.PWRITE=1; bus.PADDR=8'h00; bus.PWDATA=32'hDEADBEEF;
      @(negedge PCLK); bus.PENABLE=1;
      #2; bus.PRESETn=0;
    end
    reset_cases++;
    #1; idle(); check_pins("during reset");
    repeat(2) @(posedge PCLK);
    @(negedge PCLK); bus.PRESETn=1;
    read_all("after reset");
  endtask

  initial begin
    bus.PRESETn=0; idle(); clear_reference();
    repeat(3) @(posedge PCLK);
    @(negedge PCLK); bus.PRESETn=1;
    check_pins("initial idle");
    if($test$plusargs("WAVE_ONLY")) begin
      transfer(8'h00,1,32'h12345678,1);
      transfer(8'h00,0,0,1);
      transfer(8'h04,1,32'hA5A55A5A,1);
      transfer(8'h04,0,0,0);
      $display("APB64_WAVE_PASS transfers=%0d checks=%0d",issued,checks);
      $finish;
    end

    read_all("power-on clear");
    for(int i=0;i<64;i++) transfer(i*4,1,next_word() ^ i,0);
    read_all("all words filled");
    for(int i=0;i<64;i++) transfer(i*4,1,(i&1) ? 32'hAAAAAAAA : 32'h55555555,0);
    read_all("overwritten values");

    // Alias all four low address bits at boundary and middle words.
    for(int choice=0;choice<4;choice++) begin
      int index;
      case(choice)
        0:index=0; 1:index=1; 2:index=31; 3:index=63;
      endcase
      for(int low=0;low<4;low++) begin
        transfer((index*4+low),1,next_word(),0); alias_probes++;
        for(int other=0;other<4;other++) begin
          transfer((index*4+other),0,0,0); alias_probes++;
        end
      end
    end

    // PSEL remains high while each new SETUP follows the previous ACCESS.
    transfer(8'h00,0,0,1); // R-R
    transfer(8'hFC,0,0,1); // R-W
    transfer(8'h00,1,32'h10101010,1); // W-W
    transfer(8'h04,1,32'h20202020,1); // W-R
    transfer(8'h04,0,0,0);
    transfer(8'hFC,1,32'h30303030,1); // same-address write/read
    transfer(8'hFC,0,0,0);

    // Unselected and SETUP-only writes cannot change memory.
    @(negedge PCLK); bus.PSEL=0; bus.PENABLE=1; bus.PWRITE=1;
    bus.PADDR=8'h00; bus.PWDATA=32'hFEEDFACE;
    repeat(3) begin @(posedge PCLK); #1; check_pins("unselected write guard"); end
    @(negedge PCLK); bus.PSEL=1; bus.PENABLE=0;
    repeat(3) begin @(posedge PCLK); #1; check_pins("setup-only guard"); end
    @(negedge PCLK); idle();
    transfer(8'h00,0,0,0);
    read_all("guard preservation");

    // Reset in each phase, checking all 64 words after each cancellation.
    for(int mode=0;mode<3;mode++) begin
      transfer(8'h00,1,32'hA0000000 | mode,0);
      reset_and_read(mode);
      transfer(8'hFC,1,32'hB0000000 | mode,0);
      transfer(8'hFC,0,0,0);
    end

    if(protocol_violations != 0) $fatal(1,"APB64_MONITOR_FALSE_POSITIVE count=%0d",protocol_violations);
    $display("APB64_CONTRACT_PASS checks=%0d issued=%0d accepted=%0d writes=%0d reads=%0d aliases=%0d back_to_back=%0d resets=%0d seed=0x28AB6407",
             checks,issued,accepted,writes,reads,alias_probes,back_to_back,reset_cases);
    $finish;
  end
  initial begin #1000000; $fatal(1,"APB64_TIMEOUT"); end
endmodule
