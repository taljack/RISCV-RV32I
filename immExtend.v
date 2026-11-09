module ImmExtend(
    input  [31:0] instr,
    input  [2:0]  immsrc,
    output reg [31:0] ImExtnd
);

always @(*) begin
    case (immsrc)
        3'b000: ImExtnd = {{20{instr[31]}}, instr[31:20]};                                         // I
        3'b001: ImExtnd = {{20{instr[31]}}, instr[31:25], instr[11:7]};                            // S
        3'b010: ImExtnd = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};            // B
        3'b011: ImExtnd = {instr[31:12], 12'b0};                                                   // U
        3'b100: ImExtnd = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};          // J
        default: ImExtnd = 32'b0;
    endcase
end
endmodule