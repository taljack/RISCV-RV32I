module alu_decoder (
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input        funct7_5,
    input        is_rtype,      // opcode == 0110011
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000;               // ADD (load/store/AUIPC)
            2'b01: alu_ctrl = 4'b0001;               // SUB (branch)
            default: begin                           // 10 or 11: decode funct3
                case (funct3)
                    3'b000: alu_ctrl = (is_rtype & funct7_5) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b001: alu_ctrl = 4'b0101;      // SLL
                    3'b010: alu_ctrl = 4'b1000;      // SLT
                    3'b011: alu_ctrl = 4'b1001;      // SLTU
                    3'b100: alu_ctrl = 4'b0100;      // XOR
                    3'b101: alu_ctrl = funct7_5 ? 4'b0111 : 4'b0110;              // SRA : SRL
                    3'b110: alu_ctrl = 4'b0011;      // OR
                    3'b111: alu_ctrl = 4'b0010;      // AND
                endcase
            end
        endcase
    end
endmodule

module control_unit(
    input  [31:0] instr,
    input         take,
    output        PCSrc,
    output reg [1:0] ResultSrc,
    output reg    MemWrite,
    output [3:0]  ALUControl,
    output reg    ALUSrcA, ALUSrcB,
    output reg [2:0] ImmSrc,
    output reg    RegWrite,
    output reg    jalr
);
    wire [6:0] op       = instr[6:0];
    wire [2:0] funct3   = instr[14:12];
    wire       funct7_5 = instr[30];

    reg branch, jump;
    reg [1:0] ALUOp;

    always @(*) begin
        RegWrite = 0; ImmSrc = 3'b000; ALUSrcA = 0; ALUSrcB = 0;
        MemWrite = 0; ResultSrc = 2'b00; branch = 0; jump = 0;
        jalr = 0; ALUOp = 2'b00;
        case (op)
            7'b0110011: begin RegWrite = 1; ALUOp = 2'b10; end                          // R
            7'b0010011: begin RegWrite = 1; ALUSrcB = 1; ALUOp = 2'b11; end             // I-ALU
            7'b0000011: begin RegWrite = 1; ALUSrcB = 1; ResultSrc = 2'b01; end         // load
            7'b0100011: begin ImmSrc = 3'b001; ALUSrcB = 1; MemWrite = 1; end           // store
            7'b1100011: begin ImmSrc = 3'b010; branch = 1; ALUOp = 2'b01; end           // branch
            7'b1101111: begin RegWrite = 1; ImmSrc = 3'b100; jump = 1; ResultSrc = 2'b10; end // JAL
            7'b1100111: begin RegWrite = 1; ALUSrcB = 1; jump = 1; jalr = 1; ResultSrc = 2'b10; end // JALR
            7'b0110111: begin RegWrite = 1; ImmSrc = 3'b011; ResultSrc = 2'b11; end     // LUI
            7'b0010111: begin RegWrite = 1; ImmSrc = 3'b011; ALUSrcA = 1; ALUSrcB = 1; end // AUIPC
            default: ;
        endcase
    end

    alu_decoder dec (
        .alu_op(ALUOp), .funct3(funct3), .funct7_5(funct7_5),
        .is_rtype(op == 7'b0110011), .alu_ctrl(ALUControl)
    );

    assign PCSrc = (branch & take) | jump;
endmodule
