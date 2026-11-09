module RS32I(
    input        reset,
    input        clk,
    input        gpio_in,
    output [31:0] Ipp
);

    // ---------- PC ----------
    wire [31:0] pc, next_pc, pc_plus_4, pc_target_w;

    // ---------- Instruction ----------
    wire [31:0] instruction;

    // ---------- Register file ----------
    wire [31:0] read_data1, read_data2;
    wire [31:0] result;                       

    // ---------- Immediate ----------
    wire [31:0] ImExtnd;

    // ---------- ALU ----------
    wire [31:0] a, b, ALU_Result;
    wire        zero;                         // unused

    // ---------- Data memory ----------
    wire [31:0] Read_data;

    // ---------- Control ----------
    wire        take, PCSrc, MemWrite, ALUSrcA, ALUSrcB, RegWrite, jalr;
    wire [1:0]  ResultSrc;
    wire [3:0]  ALUControl;
    wire [2:0]  ImmSrc;

    // ---------- Fetch ----------
    Program_Counter u_pc (
        .clk(clk), .reset(reset), .next_pc(next_pc), .pc(pc)
    );

    Instruction_Memory u_imem (
        .address(pc), .instruction(instruction)
    );

    Pc_Adder u_pcplus4 (
        .pc(pc), .pc_plus_4(pc_plus_4)
    );

    // ---------- Decode ----------
    control_unit u_cu (
        .instr(instruction),
        .take(take),
        .PCSrc(PCSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite),
        .jalr(jalr)
    );

    Register_File u_rf (
        .clk(clk),
        .we(RegWrite),
        .raddr1(instruction[19:15]),
        .raddr2(instruction[24:20]),
        .waddr(instruction[11:7]),
        .write_data(result),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    ImmExtend u_imm (
        .instr(instruction), .immsrc(ImmSrc), .ImExtnd(ImExtnd)
    );

    branch_unit u_branch (
        .funct3(instruction[14:12]),
        .rd1(read_data1),
        .rd2(read_data2),
        .take(take)
    );

    // ---------- Execute ----------
    mux u_alu_a_mux (            
        .A(ALUSrcA), .zero(read_data1), .one(pc), .out(a)
    );

    mux u_alu_b_mux (           
        .A(ALUSrcB), .zero(read_data2), .one(ImExtnd), .out(b)
    );

    alunit u_alu (
        .alu_c(ALUControl),
        .a(a),
        .b(b),
        .zero(zero),
        .ALU_Result(ALU_Result)
    );

    pc_target u_pc_target (      
        .pc(pc),
        .rs1(read_data1),
        .immExt(ImExtnd),
        .jalr(jalr),
        .pc_target(pc_target_w)
    );

    mux u_pc_mux (               
        .A(PCSrc), .zero(pc_plus_4), .one(pc_target_w), .out(next_pc)
    );

    // ---------- Memory ----------
    data_mem u_dmem (
        .clk(clk),
        .address(ALU_Result),
        .Write_data(read_data2),     
        .MemWrite(MemWrite),
        .Read_data(Read_data),
        .gpio_in(gpio_in),
        .IOPINS(Ipp)
    );

    // ---------- Write back ----------
    mux4x1 u_result_mux (
        .A(ResultSrc),
        .oo(ALU_Result),   // 00: ALU
        .oi(Read_data),    // 01: load data
        .io(pc_plus_4),    // 10: JAL/JALR link
        .ii(ImExtnd),      // 11: LUI
        .out(result)
    );

endmodule