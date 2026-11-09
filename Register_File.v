module Register_File(
    input wire clk,
    input wire we,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [4:0] waddr,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

reg [31:0] register [31:0];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) begin
        register[i] = 32'b0; 
    end
end

assign read_data1 = (raddr1 == 5'b0)? 32'b0:register[raddr1];
assign read_data2 = (raddr2 == 5'b0)? 32'b0:register[raddr2];

always @(posedge clk) if (we & waddr != 5'b0) register[waddr] <= write_data; 

endmodule