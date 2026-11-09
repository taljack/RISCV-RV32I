module alunit (
    input  [3:0]  alu_c,
    input  [31:0] a,
    input  [31:0] b,
    output        zero,
    output reg [31:0] ALU_Result
);

always @(*) begin
    case (alu_c)
        4'b0000: ALU_Result = a + b;
        4'b0001: ALU_Result = a - b;
        4'b0010: ALU_Result = a & b;
        4'b0011: ALU_Result = a | b;
        4'b0100: ALU_Result = a ^ b;
        4'b0101: ALU_Result = a << b[4:0];
        4'b0110: ALU_Result = a >> b[4:0];
        4'b0111: ALU_Result = $signed(a) >>> b[4:0];
        4'b1000: ALU_Result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        4'b1001: ALU_Result = (a < b) ? 32'd1 : 32'd0;
        default: ALU_Result = 32'd0;
    endcase
end

assign zero = (ALU_Result == 32'd0);
endmodule