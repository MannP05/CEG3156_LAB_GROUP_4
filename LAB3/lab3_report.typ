#set document(
  title: "CEG 3156 - Lab #3: Pipelined RISC Processor",
  author: ("Mann Patel (300363879) and Surya Vasudev (300358602)"),
)

#set page(
  paper: "us-letter",
  margin: (x: 1in, y: 1in),
  numbering: "1",
)

#set text(font: "Times New Roman", size: 11pt)
#set heading(numbering: "1.1.")
#set par(justify: true, leading: 0.65em)


// ─── Title Page ───
#align(center)[
  #v(2fr)
  #text(size: 16pt, weight: "bold")[CEG 3156: Computer Systems Design\ (Winter 2026)]
  #v(0.5em)
  #text(size: 14pt)[Prof.~Rami Abielmona]
  #v(1em)
  #line(length: 60%, stroke: 0.5pt)
  #v(0.5em)
  #text(size: 20pt, weight: "bold")[Lab \#3:\ Pipelined MIPS Processor]
  #v(1em)
  #line(length: 60%, stroke: 0.5pt)
  #v(2em)
  #text(size: 12pt)[
    *Submitted by:*\
    Mann Patel --- 300363879\
    Surya Vasudev --- 300358602\
    #v(1em)
    *Date:* April 8#super("th"), 2026
  ]
  #v(2fr)
]

#pagebreak()

// ─── Table of Contents ───
#outline(title: [Table of Contents], indent: auto, depth: 3)
#pagebreak()


// ════════════════════════════════════════════════════════════
= Introduction
// ════════════════════════════════════════════════════════════

The objective of this laboratory is to design, implement, and verify a pipelined MIPS processor in VHDL. The processor is built on top of the single-cycle processor from Lab 2 and supports the same subset of the MIPS instruction set:

- *Memory-reference instructions:* `lw` (load word) and `sw` (store word)
- *Arithmetic/logic instructions:* `add`, `sub`, `and`, `or`, and `slt`
- *Control-flow instructions:* `beq` (branch if equal) and `j` (unconditional jump)

The design keeps the same *8-bit data paths* and *32-bit instruction widths* from Lab 2. The key addition is a five-stage pipeline with four pipeline registers, a forwarding unit to resolve data hazards, and a hazard detection unit to handle load-use stalls.


// ════════════════════════════════════════════════════════════
= Design Overview
// ════════════════════════════════════════════════════════════

The processor divides execution into five overlapping stages, allowing a new instruction to be issued every clock cycle once the pipeline is full:

+ *IF (Instruction Fetch):* The PC addresses instruction memory and PC+1 is computed for the next cycle.
+ *ID (Instruction Decode):* The fetched instruction is decoded, source registers are read, and all control signals are generated.
+ *EX (Execute):* The ALU performs its operation. Forwarding muxes select the correct operands. The branch target address is calculated.
+ *MEM (Memory Access):* Data memory is read or written. The branch outcome is resolved here.
+ *WB (Write Back):* The ALU result or memory read data is written back to the register file.

Between each adjacent pair of stages sits a pipeline register (IF/ID, ID/EX, EX/MEM, MEM/WB) that captures all data and control signals needed by downstream stages. A forwarding unit and a hazard detection unit are added to keep the pipeline correct in the presence of data and control hazards.



// ════════════════════════════════════════════════════════════
= Component Design <sec-components>
// ════════════════════════════════════════════════════════════

== Pipeline Registers

Four pipeline registers partition the datapath. Each is built entirely from `dFF_reset` flip-flops and `reg_8` registers and carries both data and control signals forward.

#figure(
  caption: [Pipeline register contents.],
  kind: table,
)[
  #table(
    columns: (auto, 3fr),
    inset: 5pt,
    table.header([*Register*], [*Contents*]),
    [IF/ID],  [32-bit instruction, PC+4. Supports stall (load-enable) and flush (reset).],
    [ID/EX],  [All nine control signals, PC+4, ReadData1, ReadData2, sign-extended immediate, jump address, rs/rt/rd register numbers, funct field.],
    [EX/MEM], [MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump, branch target, jump address, Zero flag, ALU result, ReadData2, destination register.],
    [MEM/WB], [MemtoReg, RegWrite, memory read data, ALU result, destination register.],
  )
]

All pipeline registers assert `int_reset = i_reset OR i_flush` so that a global reset and a pipeline flush share the same synchronous reset path.

== Control Unit (`Control_Unit`)

The control unit is unchanged from Lab 2. It decodes the 6-bit opcode and produces nine control signals. In the pipelined design, these signals enter the ID/EX register immediately after being generated and travel with the instruction through the pipeline.

#figure(
  caption: [Control signal truth table.],
  kind: table,
  placement: auto,
)[
  #table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    inset: 4pt,
    align: center,
    table.header(
      [*Instr.*], [*RegDst*], [*ALUSrc*], [*MemtoReg*], [*RegWrite*], [*MemRead*], [*MemWrite*], [*Branch*], [*Jump*], [*ALUOp*],
    ),
    [R-type], [1], [0], [0], [1], [0], [0], [0], [0], [10],
    [`lw`],   [0], [1], [1], [1], [1], [0], [0], [0], [00],
    [`sw`],   [×], [1], [×], [0], [0], [1], [0], [0], [00],
    [`beq`],  [×], [0], [×], [0], [0], [0], [1], [0], [01],
    [`j`],    [×], [×], [×], [0], [0], [0], [0], [1], [××],
  )
]

When a load-use stall is active, all nine control signals are AND-gated with `NOT haz_ctrl_flush` before entering the ID/EX register, effectively inserting a NOP bubble without disrupting the instruction already in ID/EX.

== ALU and ALU Control

The ALU and ALU control units are identical to Lab 2. The ALU control decodes `ALUOp` combined with the `funct` field to produce a 3-bit operation code. The 8-bit ALU supports AND, OR, addition/subtraction, and set-less-than, and produces a `Zero` flag used for branch resolution.

In the pipelined design, `ALUOp` and `funct` travel through the ID/EX register. The forwarding muxes sit between the ID/EX outputs and the ALU inputs, selecting the correct operand from the register file, the MEM/WB write-back path, or the EX/MEM ALU result.

== Instruction Memory (`instruction_memory`)

The instruction memory is a 256×32 LPM ROM, identical to Lab 2. It is clocked on the inverted clock (`NOT GClock`) so that the address is latched on the falling edge and the 32-bit instruction output is combinatorially available before the next rising edge.

== Data Memory (`data_memory`)

The data memory is a 256×8 LPM RAM DQ. It is also clocked on the inverted clock for the same timing reason. Writes are registered on the falling edge; reads are combinatorial. The `wren` input is driven by `exmem_ctrl_MemWrite`.

== Register File (`register_file`)

The register file is unchanged from Lab 2: eight 8-bit registers with two read ports and one write port, with register 0 hardwired to zero. In the pipelined design, writes are driven by MEM/WB stage signals (`memwb_ctrl_RegWrite`, `memwb_write_reg`, `wb_write_data`), while reads are driven by the IF/ID instruction fields.

== Sign Extension Unit (`sign_extended`)

The sign extension unit passes the lower 8 bits of the 16-bit immediate field through to the 8-bit datapath, identical to Lab 2.

== Branch and Jump Resolution

Branches are resolved in the MEM stage. The signal `mem_take_branch = exmem_ctrl_Branch AND exmem_zero` selects the branch target over the sequential PC and triggers a pipeline flush, cancelling the two instructions fetched speculatively after the branch.

Jumps are resolved in the ID stage. The lower 8 bits of the instruction word form the jump target address. When `id_ctrl_Jump_s` is asserted, `pipeline_flush` is set, flushing the IF/ID register. Both flush sources are combined as:

```
pipeline_flush = mem_take_branch OR id_jump_taken
```

== Output Debug Multiplexer

The debug multiplexer is identical in function to Lab 2. `ValueSelect[2:0]` selects among PC, ALU result, ReadData1, ReadData2, WriteData, and a packed control information word. The control word carries `RegDst`, `Jump`, `MemRead`, `MemtoReg`, `ALUOp[1:0]`, and `ALUSrc` sourced from the ID/EX register.

#figure(
  caption: [Output multiplexer selection.],
  kind: table,
)[
  #table(
    columns: (auto, auto, auto),
    inset: 5pt,
    align: center,
    table.header([*ValueSelect*], [*MuxOut*], [*Description*]),
    [`000`], [`PC[7:0]`],         [Current program counter],
    [`001`], [`ALUResult[7:0]`],  [EX stage ALU result],
    [`010`], [`ReadData1[7:0]`],  [Register file read port 1],
    [`011`], [`ReadData2[7:0]`],  [Register file read port 2],
    [`100`], [`WriteData[7:0]`],  [WB stage write data],
    [other], [Control word],      [`{0, RegDst, Jump, MemRead, MemtoReg, ALUOp, ALUSrc}`],
  )
]


// ════════════════════════════════════════════════════════════
= Benchmark Program and Cycle Trace <sec-benchmark>
// ════════════════════════════════════════════════════════════

The following benchmark was loaded into instruction memory. Data memory was pre-initialized with `mem[0x00] = 0x55` and `mem[0x01] = 0xAA`.

#figure(
  caption: [Cycle-by-cycle execution trace of the benchmark program.],
  kind: table,
  placement: auto,
)[
  #table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    inset: 3.5pt,
    align: center,
    table.header(
      [*Cycle*], [*PC*], [*Instruction*], [*ALU Result*], [*Zero*], [*Branch*], [*MemW*], [*RegW*], [*Hazard*],
    ),
    [1],  [`00`], [`lw $2, 0`],         [`00`],  [0], [0], [0], [1], [None],
    [2],  [`01`], [`lw $3, 1`],         [`01`],  [0], [0], [0], [1], [None],
    [3],  [`02`], [`sub $1,$2,$3`],     [`AB`],  [0], [0], [0], [1], [Load-use stall on \$2],
    [4],  [`03`], [`or $4,$1,$3`],      [`FF`],  [0], [0], [0], [1], [EX/MEM forward on \$1],
    [5],  [`04`], [`beq $1,$1,20`],     [`00`],  [1], [1], [0], [0], [Control hazard, 2-cycle flush],
    [6],  [`05`], [`sw $4, 3`],         [--],    [--],[--],[--],[--], [Flushed],
    [7],  [`06`], [`add $1,$2,$3`],     [`FF`],  [0], [0], [0], [1], [Branch target],
    [8],  [`07`], [`sw $1, 4`],         [`04`],  [0], [0], [1], [0], [EX/MEM forward on \$1],
    [9],  [`08`], [`lw $2, 3`],         [`03`],  [0], [0], [0], [1], [None],
    [10], [`09`], [`lw $3, 4`],         [`04`],  [0], [0], [0], [1], [None],
    [11], [`0A`], [`j 11`],             [--],    [--],[0], [0], [0], [Jump, 1-cycle flush],
    [12], [`0B`], [`beq $1,$1,−44`],   [--],    [--],[--],[--],[--], [Flushed],
    [13], [`11`], [`beq $1,$2,−8`],    [`00`],  [1], [1], [0], [0], [Branch taken, 2-cycle flush],
  )
] <tab-trace>


// ════════════════════════════════════════════════════════════
= Timing Analysis and CPU Execution Time <sec-timing>
// ════════════════════════════════════════════════════════════

== Critical Path Analysis

In the pipelined design, the clock period is determined by the slowest individual stage rather than the total datapath. Examining each stage:

#figure(
  caption: [Per-stage delay breakdown.],
  kind: table,
)[
  #table(
    columns: (auto, auto, auto),
    inset: 5pt,
    align: (left, center, left),
    table.header([*Stage*], [*Delay (ps)*], [*Limiting component*]),
    [IF],  [200], [Instruction memory read],
    [ID],  [100], [Register file read],
    [EX],  [100], [8-bit ALU (80 ps adder + 20 ps mux overhead)],
    [MEM], [200], [Data memory read or write],
    [WB],  [100], [Register file write],
  )
]

The slowest stages are IF and MEM at 200 ps each, giving:

$ T_"clock" = 200 "ps" $
$ f_"max" = 1 / (200 "ps") = 5 "GHz" $


=== Gate-Level Delay of the 8-Bit Ripple-Carry Adder

Each 1-bit full adder has a carry propagation of one gate delay (0.01 ns). For 8 cascaded stages:

$ t_"adder" = 8 times 0.01 "ns" = 0.08 "ns" = 80 "ps" $

=== ALU Worst-Case Delay

$ t_"ALU" = t_"adder" + t_"mux" = 80 "ps" + 20 "ps" = 100 "ps" $

== CPI and CPU Execution Time

An ideal pipeline achieves CPI = 1. Hazards add stall cycles:

#figure(
  caption: [Hazard penalty summary for the benchmark program.],
  kind: table,
)[
  #table(
    columns: (2fr, auto, 2fr),
    inset: 5pt,
    align: (left, center, left),
    table.header([*Hazard*], [*Penalty (cycles)*], [*Cause*]),
    [Load-use stall (lw then sub)],       [1 to 2], [Loaded value not ready for next instruction],
    [Branch taken (resolves in MEM)],     [2],      [Two speculatively fetched instructions flushed],
    [Jump (resolves in ID)],              [1],      [One speculatively fetched instruction flushed],
  )
]

For 13 instructions with approximately 5 to 6 extra stall cycles:

$ "CPI"_"pipelined" approx (13 + 6) / 13 approx 1.46 $

$ T_"CPU" = "IC" times "CPI" times T_"clock" = 13 times 1.46 times 200 "ps" approx 3796 "ps" approx 3.8 "ns" $

== Comparison with Single-Cycle Processor

The single-cycle processor from Lab 2 had a clock period equal to the full critical path:

$ T_"cycle,single" = 200 + 100 + 100 + 200 + 100 = 700 "ps" $
$ T_"CPU,single" = 11 times 1 times 700 "ps" = 7700 "ps" = 7.7 "ns" $

The pipelined processor is approximately *2× faster* on this benchmark. Without any hazard penalties the theoretical speedup would be 3.5×, which shows how significantly stalls and flushes reduce the benefit of pipelining in short programs.


// ════════════════════════════════════════════════════════════
= Simulation Results <sec-sim>
// ════════════════════════════════════════════════════════════

Functional simulation was performed in Quartus II 13.1. The simulation verified correct pipelined execution of the benchmark program by observing the following signals at each clock cycle:

- `InstructionOut[31:0]` with varying `InstrSelect`: confirmed that the correct instruction appears in each pipeline stage at the expected cycle.
- `MuxOut[7:0]` with varying `ValueSelect`: confirmed correct PC progression, ALU results, register file read/write data, and control signal values.
- `BranchOut`, `ZeroOut`, `MemWriteOut`, `RegWriteOut`: confirmed correct control signal assertion per instruction.
- Stall and flush behaviour: confirmed that the PC and IF/ID register freeze correctly on a load-use hazard, and that IF/ID and ID/EX are cleared correctly on a taken branch or jump.

#figure(
  caption: [Simulation waveforms (Quartus II functional simulation).],
  kind: image,
)[
  #grid(
    columns: 1,
    rows: 4,
    gutter: 0.5em,
    [*Waveform 1 --- PC and InstructionOut (InstrSelect = 000)*\ #image("images/waveform_PC.png", width: 100%)],
    [*Waveform 2 --- ALU Result and control signals (ValueSelect = 100)*\ #image("images/waveform_ALU.png", width: 100%)],
  )
] <fig-sim>


// ════════════════════════════════════════════════════════════
= Design Challenges and Solutions <sec-challenges>
// ════════════════════════════════════════════════════════════

Several design obstacles were encountered during implementation:


+ *Coordinating Jump and Branch Flushes:*
  Jumps resolve in the ID stage, one stage earlier than branches. Both flush sources needed to be combined without either masking the other. This was solved by OR-ing them into a single `pipeline_flush` signal that feeds the flush input of all affected pipeline registers.

+ *Load-Use Stall Interacting with a Flush:*
  A load-use stall and a pipeline flush can coincide in the same clock cycle. Inside each pipeline register, the flush is wired to the synchronous reset input and the stall is wired to the load-enable input. Synchronous reset takes priority over load-enable in the `reg_8` and `dFF_reset` components, so the flush always wins cleanly without additional arbitration logic.



// ════════════════════════════════════════════════════════════
= Conclusion
// ════════════════════════════════════════════════════════════

A fully functional 8-bit pipelined RISC processor was  designed, implemented in structural VHDL, and verified in simulation. The processor executes all supported MIPS instructions across a five-stage pipeline with forwarding and hazard detection.

The critical path analysis gives a maximum theoretical clock frequency of 5 GHz (200 ps clock period), constrained by the instruction and data memory stages. The CPU execution time for the benchmark program is approximately 3.8 ns, representing roughly a 2× improvement over the single-cycle processor from Lab 2. The theoretical maximum speedup without hazards would be 3.5×, and the gap between that and the achieved speedup reflects the cost of load-use stalls and branch/jump flush penalties in this short benchmark.
\
\
\
\

Note: The complete VHDL source code for all components is included in the GitHub repository: https://github.com/MannP5/CEG3156_LAB_GROUP_4
