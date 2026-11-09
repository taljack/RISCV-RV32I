module branch_unit (
    input  [2:0]  funct3,
    input  [31:0] rd1, rd2,
    output reg    take
);
    wire eq  = (rd1 == rd2);
    wire lt  = ($signed(rd1) < $signed(rd2));
    wire ltu = (rd1 < rd2);

    always @(*) begin
        case (funct3)
            3'b000:  take = eq;     // BEQ
            3'b001:  take = ~eq;    // BNE
            3'b100:  take = lt;     // BLT
            3'b101:  take = ~lt;    // BGE
            3'b110:  take = ltu;    // BLTU
            3'b111:  take = ~ltu;   // BGEU
            default: take = 1'b0;
        endcase
    end
endmodule