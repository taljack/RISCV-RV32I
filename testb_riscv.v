`timescale 1ps/1ps
module TEST_RS32I;
    reg clk,rst,gpio_in;
    wire [31:0] opp;

    RS32I dut(
        .reset(rst),
        .gpio_in(gpio_in),
        .clk(clk),
        .Ipp(opp)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin 
        $dumpfile("testIT.vcd");
        $dumpvars(0,TEST_RS32I);

        rst = 1;
        gpio_in = 1;
        repeat (2) @(negedge clk);
        rst = 0;
        gpio_in = 0;
        repeat (10) @(negedge clk);
        rst = 1;
        gpio_in = 1;
        repeat (2) @(negedge clk);
        $finish;

    end
endmodule

