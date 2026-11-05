`timescale 1ns/1ps

// Deterministic pin-level checks for the existing zero-wait-state APB RAM.
// The original class, randomization and coverage environment remains in tb_top.sv.
module tb_apb_portable;
    reg PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    apb_if bus(PCLK);
    apb_ram dut(bus);
    reg [31:0] expected_mem [0:63];
    integer checks = 0;
    integer i;

    task automatic check_bus;
        input [31:0] expected_data;
        input string stage;
        begin
            #1;
            if (bus.PREADY !== 1'b1 || bus.PSLVERR !== 1'b0 ||
                bus.PRDATA !== expected_data)
                $fatal(1, "APB mismatch %s addr=%02h sel=%b enable=%b write=%b got=%08h/%b/%b expected=%08h/1/0",
                       stage, bus.PADDR, bus.PSEL, bus.PENABLE, bus.PWRITE,
                       bus.PRDATA, bus.PREADY, bus.PSLVERR, expected_data);
            checks = checks + 1;
        end
    endtask

    task automatic idle_bus;
        begin
            bus.PSEL = 1'b0;
            bus.PENABLE = 1'b0;
            bus.PWRITE = 1'b0;
            bus.PADDR = 8'h00;
            bus.PWDATA = 32'h0000_0000;
            check_bus(32'h0000_0000, "idle");
        end
    endtask

    task automatic write_word;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(negedge PCLK);
            bus.PSEL = 1'b1;
            bus.PENABLE = 1'b0;
            bus.PWRITE = 1'b1;
            bus.PADDR = addr;
            bus.PWDATA = data;
            check_bus(32'h0000_0000, "write setup");
            @(posedge PCLK);
            check_bus(32'h0000_0000, "write setup edge");
            @(negedge PCLK);
            bus.PENABLE = 1'b1;
            check_bus(32'h0000_0000, "write access");
            @(posedge PCLK);
            expected_mem[addr[7:2]] = data;
            check_bus(32'h0000_0000, "write completion");
            @(negedge PCLK);
            idle_bus();
        end
    endtask

    task automatic read_word;
        input [7:0] addr;
        reg [31:0] expected;
        begin
            expected = expected_mem[addr[7:2]];
            @(negedge PCLK);
            bus.PSEL = 1'b1;
            bus.PENABLE = 1'b0;
            bus.PWRITE = 1'b0;
            bus.PADDR = addr;
            bus.PWDATA = 32'hDEAD_BEEF;
            check_bus(expected, "read setup");
            @(posedge PCLK);
            check_bus(expected, "read setup edge");
            @(negedge PCLK);
            bus.PENABLE = 1'b1;
            check_bus(expected, "read access");
            @(posedge PCLK);
            check_bus(expected, "read completion");
            @(negedge PCLK);
            idle_bus();
        end
    endtask

    initial begin
        #200000;
        $fatal(1, "APB portable test timeout");
    end

    initial begin
        bus.PRESETn = 1'b1;
        bus.PSEL = 1'b0;
        bus.PENABLE = 1'b0;
        bus.PWRITE = 1'b0;
        bus.PADDR = 8'h00;
        bus.PWDATA = 32'h0000_0000;
        for (i = 0; i < 64; i = i + 1)
            expected_mem[i] = 32'h0000_0000;

        // A falling reset edge clears all 64 words before the next clock edge.
        #1 bus.PRESETn = 1'b0;
        check_bus(32'h0000_0000, "initial reset");
        repeat (2) @(posedge PCLK);
        @(negedge PCLK);
        bus.PRESETn = 1'b1;

        // Read every word after reset, then write and read all 64 words.
        for (i = 0; i < 64; i = i + 1)
            read_word(i * 4);
        for (i = 0; i < 64; i = i + 1) begin
            write_word(i * 4, 32'h9E37_79B9 ^ (i * 32'h0101_0101));
            read_word(i * 4);
        end

        // These are pin guards, not claims about legal APB master behavior.
        // An unselected access or abandoned SETUP must not change RAM.
        @(negedge PCLK);
        bus.PSEL = 1'b0;
        bus.PENABLE = 1'b1;
        bus.PWRITE = 1'b1;
        bus.PADDR = 8'h80;
        bus.PWDATA = 32'hFFFF_FFFF;
        check_bus(32'h0000_0000, "unselected access");
        @(posedge PCLK);
        @(negedge PCLK);
        idle_bus();
        read_word(8'h80);

        @(negedge PCLK);
        bus.PSEL = 1'b1;
        bus.PENABLE = 1'b0;
        bus.PWRITE = 1'b1;
        bus.PADDR = 8'h80;
        bus.PWDATA = 32'hFFFF_FFFF;
        check_bus(32'h0000_0000, "abandoned setup");
        @(posedge PCLK);
        @(negedge PCLK);
        idle_bus();
        read_word(8'h80);

        // The RTL ignores low address bits. Record this implemented aliasing,
        // without treating unaligned addresses as valid APB protocol coverage.
        read_word(8'h03);
        write_word(8'hFD, 32'h1234_5678);
        read_word(8'hFC);
        read_word(8'hFF);

        // Assert reset during a would-be ACCESS write; check all words again.
        @(negedge PCLK);
        bus.PSEL = 1'b1;
        bus.PENABLE = 1'b1;
        bus.PWRITE = 1'b1;
        bus.PADDR = 8'hFC;
        bus.PWDATA = 32'hFFFF_FFFF;
        #2 bus.PRESETn = 1'b0;
        for (i = 0; i < 64; i = i + 1)
            expected_mem[i] = 32'h0000_0000;
        check_bus(32'h0000_0000, "asynchronous reset during access");
        repeat (2) @(posedge PCLK);
        @(negedge PCLK);
        bus.PRESETn = 1'b1;
        idle_bus();
        for (i = 0; i < 64; i = i + 1)
            read_word(i * 4);

        $display("PORTABLE_TEST_PASS APB checks=%0d", checks);
        $finish;
    end
endmodule
