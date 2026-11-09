module Program_Counter(
    input clk,
    input reset,
    input [31:0] next_pc,
    output reg [31:0] pc
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0; // Reset the program counter to 0
        end else begin
            pc <= next_pc; // Update the program counter with the next value
        end
    end
endmodule

module Pc_Adder(
    input [31:0] pc,
    output [31:0] pc_plus_4
);
assign pc_plus_4 = pc + 32'd4;
endmodule

module mux(
    input A,
    input [31:0] zero,
    input [31:0] one,
    output [31:0] out
);
assign out = (A == 1'b0) ? zero : one;
endmodule

module mux4x1(
    input [1:0]A,
    input [31:0] oo,
    input [31:0] oi,
    input [31:0] io,
    input [31:0] ii,
    output [31:0] out
);
assign out = (A == 2'b00)? oo:
             (A == 2'b01)? oi:
             (A == 2'b10)? io:ii;
endmodule


module pc_target(
    input  [31:0] pc, rs1, immExt,
    input         jalr,
    output [31:0] pc_target
);
    wire [31:0] sum = (jalr ? rs1 : pc) + immExt;
    assign pc_target = {sum[31:1], sum[0] & ~jalr};
endmodule
