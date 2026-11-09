# Single-Cycle RV32I Processor (Verilog)

A single-cycle implementation of the RISC-V RV32I base integer instruction set, written in Verilog from scratch. Every instruction fetches, decodes, executes, accesses memory and writes back within one clock cycle. It includes a small memory-mapped GPIO and a test program that toggles the output pins between `0xAAAAAAAA` and `0x55555555`.

> **Status:** simulated and checked in waveforms with Icarus Verilog and GTKWave. Not yet run on an FPGA. Planned next step: a 5-stage pipeline.

## Features

- RV32I datapath: program counter, instruction memory, register file, immediate generator, ALU, data memory
- Main control unit plus a separate ALU decoder (10 ALU operations, 4-bit `ALUControl`)
- Dedicated branch unit (BEQ, BNE, BLT, BGE, BLTU, BGEU)
- Jumps and upper-immediate instructions: JAL, JALR, LUI, AUIPC
- Memory-mapped GPIO on the top two words of data memory
- Fully combinational instruction and data reads, which is what a single-cycle design needs

## Supported instructions

| Type | Instructions |
|---|---|
| R-type | `add sub and or xor sll srl sra slt sltu` |
| I-type ALU | `addi andi ori xori slli srli srai slti sltiu` |
| Load / store | `lw sw` (word access only) |
| Branch | `beq bne blt bge bltu bgeu` |
| Jump | `jal jalr` |
| Upper immediate | `lui auipc` |

**Not supported yet:** `lb lh lbu lhu sb sh`, the M extension (`mul`/`div`), CSRs, `ecall`/`ebreak`, exceptions and misaligned-access traps.

## Architecture

```
                 +--------------------------------------+
   PC --> Instruction Memory --> instr                   |
    |                              |                     |
    |        +----------+----------+------------+        |
    |        v          v                       v        |
    |   Control Unit  Register File         Imm Extend    |
    |        |          |    |                  |        |
    |        |          |    +--> Branch Unit --+--> take |
    |        |       SrcA / SrcB muxes                   |
    |        |          |                                |
    |        +-------> ALU ---> Data Memory / GPIO       |
    |                     |           |                  |
    +-- PC+4 / target <---+--- Result mux (ALU, mem, PC+4, imm)
```

| Block | Role |
|---|---|
| `Program_Counter` | Holds the PC, with asynchronous reset to 0 |
| `Pc_Adder` | PC + 4 |
| `pc_target` | PC + imm for branches and JAL, (rs1 + imm) & ~1 for JALR |
| `control_unit` / `alu_decoder` | Generate control signals from the opcode, funct3 and funct7[5] |
| `branch_unit` | Produces `take` from funct3 and the two register values |
| `ImmExtend` | Builds I, S, B, U and J immediates (3-bit `ImmSrc`) |
| `alu` | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| `mux`, `mux4x1` | ALU operand muxes, PC mux, and the 4-input write-back mux |

### Control signals

| Signal | Meaning |
|---|---|
| `ALUSrcA` | 0 = rs1, 1 = PC (AUIPC) |
| `ALUSrcB` | 0 = rs2, 1 = immediate |
| `ResultSrc` | 00 = ALU result, 01 = memory data, 10 = PC+4 (JAL/JALR), 11 = immediate (LUI) |
| `ImmSrc` | 000 = I, 001 = S, 010 = B, 011 = U, 100 = J |
| `PCSrc` | `(branch & take) \| jump`, selects PC+4 or the target |
| `jalr` | Selects rs1 as the base of the target adder |

## Memory map

| Memory | Size | Address range | Notes |
|---|---|---|---|
| Instruction memory | 256 words (1 KB) | `0x000` and up | Loaded from `instructions.hex` |
| Data memory | 1024 words (4 KB) | `0x000` to `0xFFF` | Word-addressed with `address[11:2]` |
| GPIO output | word 1023 | `0xFFC` | Drives `IOPINS` when `gpio_in = 0` |
| GPIO input sample | word 1022 | `0xFF8` | Samples `IOPINS` every clock when `gpio_in = 1` |

## Repository layout

```
.
├── top_riscv.v          # top module (RS32I)
├── Program_Counter.v    # PC, PC adder, muxes, pc_target
├── Instruction_Memory.v
├── control_unit.v       # control unit + ALU decoder
├── Register_File.v
├── immExtend.v
├── alu.v
├── branch_unit.v
├── data_memory.v        # data memory + GPIO
├── testb_riscv.v        # testbench
├── program.s            # test program (assembly)
└── instructions.hex     # test program (machine code)
```

## Build and simulate

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) and [GTKWave](https://gtkwave.sourceforge.net/).

```bash
iverilog -o sim testb_riscv.v top_riscv.v Program_Counter.v Instruction_Memory.v \
         control_unit.v Register_File.v immExtend.v alu.v data_memory.v branch_unit.v
vvp sim
gtkwave testIT.vcd
```

Run from the folder that contains `instructions.hex`. The file must be plain hex, one 32-bit word per line, with no `0x` prefix.

## Writing your own programs

Assemble for RV32I only (no compressed instructions) and place the code at address 0:

```bash
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o prog.o prog.s
riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0 -o prog.elf prog.o
riscv64-unknown-elf-objcopy -O binary prog.elf prog.bin
hexdump -v -e '1/4 "%08x\n"' prog.bin > instructions.hex
```

There is no `.data` section: instruction and data memory are separate, so load constants with `li` and write them with `sw`.

## Example program

Alternates `0xAAAAAAAA` and `0x55555555` on GPIO word 1023 with a delay between each write:

```asm
        .globl _start
_start:
        li   t0, 0xFFC          # byte address of word 1023
        li   t1, 0xAAAAAAAA
        li   t2, 0x55555555
Repeat: li   t3, 0xAAA          # delay count
        sw   t1, 0(t0)
loop1:  addi t3, t3, -1
        bnez t3, loop1
        sw   t2, 0(t0)
        li   t3, 0xAAA
loop2:  addi t3, t3, -1
        bnez t3, loop2
        j    Repeat
```

For simulation, lower the delay count (for example `li t3, 10`) so the toggling is visible in a short run.

## Roadmap

- [ ] Self-checking testbench covering every instruction and edge cases
- [ ] Byte and halfword loads and stores (`lb lh lbu lhu sb sh`)
- [ ] M extension (`mul`, `div`, `rem`)
- [ ] 5-stage pipeline with forwarding and hazard detection
- [ ] Run on an FPGA board
- [ ] Pass the official `riscv-arch-test` rv32i suite

## License

Add a license of your choice (for example MIT) before publishing.
