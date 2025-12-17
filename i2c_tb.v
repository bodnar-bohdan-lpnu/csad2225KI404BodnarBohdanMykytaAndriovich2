`timescale 1ns/1ps
module i2c_tb;

    localparam integer CLK_PERIOD_NS = 20; // 50 MHz
    localparam [6:0] DUT_ADDR    = 7'b1010101;
    localparam [7:0] FIRST_DATA  = 8'hA5;
    localparam [7:0] SECOND_DATA = 8'h3C;
    localparam [7:0] SLAVE_TX1   = 8'h5A;

    reg clk;
    reg rst_n;

    reg start_cmd;
    reg [6:0] slave_addr;
    reg rw_bit;
    reg [7:0] data_in;

    wire [7:0] data_out_master;
    wire busy;
    wire scl;
    wire sda;
    wire done;

    wire [7:0] data_received;
    wire data_valid;

    reg [7:0] data_to_send;

    pullup(sda);

    i2c_master #(
        .CLK_HZ(50_000_000),
        .I2C_HZ(100_000)
    ) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start_cmd(start_cmd),
        .slave_addr(slave_addr),
        .rw_bit(rw_bit),
        .data_in(data_in),
        .data_out(data_out_master),
        .busy(busy),
        .scl(scl),
        .sda(sda),
        .done(done)
    );

    i2c_slave u_slave (
        .clk(clk),
        .rst_n(rst_n),
        .my_addr(DUT_ADDR),
        .scl(scl),
        .sda(sda),
        .data_to_send(data_to_send),
        .data_received(data_received),
        .data_valid(data_valid)
    );

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    task automatic i2c_start_transaction(input [6:0] addr, input rw, input [7:0] din);
    begin
        @(negedge clk);
        slave_addr = addr;
        rw_bit     = rw;
        data_in    = din;

        start_cmd  = 1'b1;
        @(negedge clk);
        start_cmd  = 1'b0;

        wait (done == 1'b1);
        @(negedge clk);
    end
    endtask

    initial begin
        rst_n      = 1'b0;
        start_cmd  = 1'b0;
        slave_addr = 7'd0;
        rw_bit     = 1'b0;
        data_in    = 8'd0;
        data_to_send = 8'd0;

        $dumpfile("i2c_tb.vcd");
        $dumpvars(0, i2c_tb);

        #(CLK_PERIOD_NS*10);
        rst_n = 1'b1;

        #(CLK_PERIOD_NS*50);
        $display("=== START I2C TESTS ===");

        // Test 1: master write -> slave receive
        i2c_start_transaction(DUT_ADDR, 1'b0, FIRST_DATA);
        if (data_received == FIRST_DATA)
            $display("✓ Test1 OK: slave got 0x%02h", data_received);
        else
            $display("✗ Test1 FAIL: expected 0x%02h got 0x%02h", FIRST_DATA, data_received);

        #(CLK_PERIOD_NS*200);

        // Test 2: master write -> slave receive
        i2c_start_transaction(DUT_ADDR, 1'b0, SECOND_DATA);
        if (data_received == SECOND_DATA)
            $display("✓ Test2 OK: slave got 0x%02h", data_received);
        else
            $display("✗ Test2 FAIL: expected 0x%02h got 0x%02h", SECOND_DATA, data_received);

        #(CLK_PERIOD_NS*200);

        // Test 3: master read <- slave transmit (Rx check)
        data_to_send = SLAVE_TX1;
        i2c_start_transaction(DUT_ADDR, 1'b1, 8'h00);
        if (data_out_master == SLAVE_TX1)
            $display("✓ Test3 OK: master read 0x%02h", data_out_master);
        else
            $display("✗ Test3 FAIL: expected 0x%02h got 0x%02h", SLAVE_TX1, data_out_master);

        #(CLK_PERIOD_NS*200);

        // Test 4: wrong address => slave should ignore
        data_to_send = 8'hCC;
        i2c_start_transaction(7'b0001111, 1'b1, 8'h00);
        if (data_out_master != 8'hCC)
            $display("✓ Test4 OK: wrong address not served by slave");
        else
            $display("✗ Test4 FAIL: slave responded to wrong address");

        #(CLK_PERIOD_NS*500);
        $display("=== END ===");
        $finish;
    end

    always @(posedge data_valid) begin
        $display("T=%0t ns: Slave received 0x%02h", $time, data_received);
    end

endmodule
