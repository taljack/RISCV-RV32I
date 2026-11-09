module Instruction_Memory(
    input  [31:0] address,
    output [31:0] instruction
);
    reg [31:0] memory [0:255];   

    initial begin
        $readmemh("instructions.hex", memory);
    end

    assign instruction = memory[address[9:2]];   
endmodule