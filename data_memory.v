module data_mem(
    input         clk,
    input  [31:0] address,
    input  [31:0] Write_data,
    input         MemWrite,
    input         gpio_in,
    output reg [31:0] Read_data,
    inout reg [31:0] IOPINS
    
);
    reg [31:0] memm [0:1023];
    reg [31:0] io;   

    always @(posedge clk) begin
        if (MemWrite) memm[address[11:2]] <= Write_data;
        if (gpio_in) memm[1022] <= IOPINS;
    end
    always @(*)
        Read_data = memm[address[11:2]];
assign IOPINS = (gpio_in == 1'b0)? memm[1023]:32'd0;
endmodule