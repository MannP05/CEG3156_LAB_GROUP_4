#import "@preview/cetz:0.3.4"

#set page(
  paper: "us-letter",
  margin: (x: 1in, y: 0.9in),
  numbering: "1",
  header: align(right)[_CEG 3156 — Lab 3 Pre-Lab_],
)

#set text(
  font: "New Computer Modern",
  size: 11pt,
)

#set par(
  justify: true,
  leading: 0.65em,
)

#set heading(numbering: "1.")
#set table(
  stroke: 0.6pt,
  inset: 6pt,
)

// ─────────────────────────────────────────────
// TITLE PAGE
// ─────────────────────────────────────────────

#v(2fr)
#align(center)[
  #text(size: 18pt, weight: "bold")[CEG 3156: Computer Systems Design] \
  #v(0.3em)
  #text(size: 15pt, weight: "bold")[Laboratory \#3 — Pipelined Processor] \
  #v(0.6em)
  #text(size: 14pt)[Pre-Lab Preparation] \
  #text(size: 14pt)[Hazard Detection Unit & Forwarding Unit]
  #v(2em)
  #text(size: 12pt)[
    *Name:* Your Name Here \
    *Student \#:* 1234567 \
    *Date:* March 2026
  ]
]
#v(3fr)
#pagebreak()

// ─────────────────────────────────────────────
// 1  OBJECTIVE
// ─────────────────────────────────────────────

= Objective

Design the *forwarding unit* and *hazard detection unit* for the 5-stage pipelined MIPS processor. For each unit, present: purpose, inputs/outputs, truth tables, Karnaugh maps, simplified Boolean equations, logic realization diagrams, and a worked sample scenario.

The 5 pipeline stages are:

- IF: Instruction Fetch
- ID: Instruction Decode / Register Read
- EX: Execute / Address Calculation
- MEM: Memory Access
- WB: Write Back

In a pipelined processor, multiple instructions are active simultaneously. This improves throughput, but it introduces *data hazards* when one instruction depends on the result of another instruction still inside the pipeline. These hazards are handled using a forwarding unit and a hazard detection unit.

= Overview of Pipeline Data Hazards

A *data hazard* occurs when an instruction requires a register value that a prior instruction has not yet written back. Two important cases exist:

+ *Forwardable hazard:* the value exists in a later pipeline register and can be routed to the ALU.
+ *Load-use hazard:* a `lw` instruction has not yet read memory, so the value is unavailable and the pipeline must stall one cycle.

The forwarding unit resolves the first case.
The hazard detection unit resolves the second case.

// ─────────────────────────────────────────────
// 3  FORWARDING UNIT
// ─────────────────────────────────────────────

= Forwarding Unit

== Purpose

The forwarding unit selects the most recent value of a register for each ALU input, bypassing the register file when the value has been computed but not yet written back.

For example:

```asm
add #1, #2, #3
sub #4, #1, #5
```

The `sub` instruction needs the value of register 1 before the `add` instruction reaches the WB stage. Instead of waiting for write-back, the result is forwarded from a later pipeline stage.

== Block Diagram

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    rect((0, 0), (10, 5), name: "fwd")
    content((5, 2.5), text(weight: "bold", size: 10pt)[Forwarding Unit])

    let inputs = (
      ("EX/MEM.RegWrite", 4.5),
      ("EX/MEM.RegisterRd", 4.0),
      ("MEM/WB.RegWrite", 3.5),
      ("MEM/WB.RegisterRd", 3.0),
      ("ID/EX.RegisterRs", 1.5),
      ("ID/EX.RegisterRt", 1.0),
    )
    for (label, y) in inputs {
      line((-3.8, y), (0, y), mark: (end: ">", fill: black))
      content((-4.0, y), text(size: 8pt)[#label], anchor: "east")
    }

    let outputs = (
      ("ForwardA[1:0]", 3.8),
      ("ForwardB[1:0]", 1.2),
    )
    for (label, y) in outputs {
      line((10, y), (13.5, y), mark: (end: ">", fill: black))
      content((13.7, y), text(size: 8pt)[#label], anchor: "west")
    }
  }),
  caption: [Forwarding unit — external interface],
) <fwd-block>

== Inputs and Outputs

#table(
  columns: 3,
  [*Signal*], [*Direction*], [*Width*],
  [`EX/MEM.RegWrite`], [Input], [1 bit],
  [`EX/MEM.RegisterRd`], [Input], [3 bits],
  [`MEM/WB.RegWrite`], [Input], [1 bit],
  [`MEM/WB.RegisterRd`], [Input], [3 bits],
  [`ID/EX.RegisterRs`], [Input], [3 bits],
  [`ID/EX.RegisterRt`], [Input], [3 bits],
  [`ForwardA[1:0]`], [Output], [2 bits],
  [`ForwardB[1:0]`], [Output], [2 bits],
)

Output encoding:

#table(
  columns: 2,
  [*Code*], [*Source selected*],
  [`00`], [Normal value from ID/EX pipeline register],
  [`10`], [Forward from EX/MEM (one stage back)],
  [`01`], [Forward from MEM/WB (two stages back)],
)

== Intermediate Definitions

*X* = EX/MEM.RegWrite AND (EX/MEM.Rd is not 0) AND (EX/MEM.Rd = ID/EX.Rs)

*Y* = MEM/WB.RegWrite AND (MEM/WB.Rd is not 0) AND (MEM/WB.Rd = ID/EX.Rs)

*P* = EX/MEM.RegWrite AND (EX/MEM.Rd is not 0) AND (EX/MEM.Rd = ID/EX.Rt)

*Q* = MEM/WB.RegWrite AND (MEM/WB.Rd is not 0) AND (MEM/WB.Rd = ID/EX.Rt)

Priority: when both EX/MEM and MEM/WB match, EX/MEM wins because it holds the most recent result.

== Truth Tables

#figure(
  grid(
    columns: 2,
    gutter: 2em,
    table(
      columns: 5,
      [*X*], [*Y*], [*FA1*], [*FA0*], [*Action*],
      [0], [0], [0], [0], [No fwd],
      [0], [1], [0], [1], [MEM/WB],
      [1], [0], [1], [0], [EX/MEM],
      [1], [1], [1], [0], [EX/MEM],
    ),
    table(
      columns: 5,
      [*P*], [*Q*], [*FB1*], [*FB0*], [*Action*],
      [0], [0], [0], [0], [No fwd],
      [0], [1], [0], [1], [MEM/WB],
      [1], [0], [1], [0], [EX/MEM],
      [1], [1], [1], [0], [EX/MEM],
    ),
  ),
  caption: [Truth tables for ForwardA (left) and ForwardB (right)],
) <fwd-tt>

== Karnaugh Maps

#figure(
  grid(
    columns: 2,
    gutter: 1.5em,
    stack(
      dir: ttb,
      spacing: 0.4em,
      text(weight: "bold", size: 9pt)[ForwardA1],
      table(
        columns: 3,
        [_X \\ Y_], [*0*], [*1*],
        [*0*], [0], [0],
        [*1*], [1], [1],
      ),
    ),
    stack(
      dir: ttb,
      spacing: 0.4em,
      text(weight: "bold", size: 9pt)[ForwardA0],
      table(
        columns: 3,
        [_X \\ Y_], [*0*], [*1*],
        [*0*], [0], [1],
        [*1*], [0], [0],
      ),
    ),
  ),
  caption: [K-maps for ForwardA],
) <fwd-kmap-a>

#figure(
  grid(
    columns: 2,
    gutter: 1.5em,
    stack(
      dir: ttb,
      spacing: 0.4em,
      text(weight: "bold", size: 9pt)[ForwardB1],
      table(
        columns: 3,
        [_P \\ Q_], [*0*], [*1*],
        [*0*], [0], [0],
        [*1*], [1], [1],
      ),
    ),
    stack(
      dir: ttb,
      spacing: 0.4em,
      text(weight: "bold", size: 9pt)[ForwardB0],
      table(
        columns: 3,
        [_P \\ Q_], [*0*], [*1*],
        [*0*], [0], [1],
        [*1*], [0], [0],
      ),
    ),
  ),
  caption: [K-maps for ForwardB],
) <fwd-kmap-b>

== Simplified Boolean Equations

From the K-maps:

- *ForwardA1 = X*
- *ForwardA0 = (NOT X) AND Y*
- *ForwardB1 = P*
- *ForwardB0 = (NOT P) AND Q*

== Internal Logic Diagram

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let comp(pos, label) = {
      rect(
        (pos.at(0) - 1.2, pos.at(1) - 0.5),
        (pos.at(0) + 1.2, pos.at(1) + 0.5),
      )
      content(pos, text(size: 7pt)[#label])
    }

    let andgate(pos, label) = {
      rect(
        (pos.at(0) - 0.8, pos.at(1) - 0.4),
        (pos.at(0) + 0.8, pos.at(1) + 0.4),
      )
      content(pos, text(size: 7pt)[#label])
    }

    content((-2.5, 7.5), text(weight: "bold", size: 9pt)[ForwardA path], anchor: "west")

    comp((3, 6.5), [EQ\ EX/MEM.Rd\ vs ID/EX.Rs])
    comp((3, 5.2), [NZ\ EX/MEM.Rd not 0])
    andgate((7, 5.8), [AND then X])
    line((4.2, 6.5), (6.2, 6.1), mark: (end: ">", fill: black))
    line((4.2, 5.2), (6.2, 5.5), mark: (end: ">", fill: black))
    line((5.0, 7.3), (6.2, 6.2))
    content((5.0, 7.5), text(size: 7pt)[EX/MEM.RegWrite], anchor: "south")

    comp((3, 3.8), [EQ\ MEM/WB.Rd\ vs ID/EX.Rs])
    comp((3, 2.5), [NZ\ MEM/WB.Rd not 0])
    andgate((7, 3.2), [AND then Y])
    line((4.2, 3.8), (6.2, 3.5), mark: (end: ">", fill: black))
    line((4.2, 2.5), (6.2, 2.9), mark: (end: ">", fill: black))
    line((5.0, 4.5), (6.2, 3.6))
    content((5.0, 4.7), text(size: 7pt)[MEM/WB.RegWrite], anchor: "south")

    line((7.8, 5.8), (10.5, 5.8), mark: (end: ">", fill: black))
    content((10.7, 5.8), text(size: 8pt)[ForwardA1 = X], anchor: "west")

    circle((8.8, 4.8), radius: 0.2)
    content((8.8, 4.8), text(size: 7pt)[N])
    line((7.8, 5.6), (8.6, 4.9))

    andgate((10, 4.0), [AND])
    line((9.0, 4.6), (9.2, 4.2), mark: (end: ">", fill: black))
    line((7.8, 3.2), (9.2, 3.8), mark: (end: ">", fill: black))
    line((10.8, 4.0), (12.5, 4.0), mark: (end: ">", fill: black))
    content((12.7, 4.0), text(size: 8pt)[ForwardA0 = NOT(X) AND Y], anchor: "west")
  }),
  caption: [Internal logic of the forwarding unit (ForwardA path shown; ForwardB is identical with Rt substituted for Rs)],
) <fwd-logic>

== Sample Scenario: EX/MEM Forwarding

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let stages = ("IF", "ID", "EX", "MEM", "WB")

    for i in range(7) {
      content((2.2 + i * 2.0, 7.2), text(size: 8pt, weight: "bold")[CC#(i + 1)])
    }
    line((1.5, 6.8), (16.5, 6.8), mark: (end: ">", fill: black))
    content((16.7, 6.8), text(size: 7pt)[Time], anchor: "west")

    content((0.0, 5.5), text(size: 8pt)[add r1,r2,r3], anchor: "east")
    content((0.0, 3.5), text(size: 8pt)[sub r4,r1,r5], anchor: "east")

    let boxw = 1.6
    let boxh = 1.2

    for (i, s) in stages.enumerate() {
      let x = 1.5 + i * 2.0
      let y = 5.5
      rect((x - boxw/2, y - boxh/2), (x + boxw/2, y + boxh/2),
        fill: if s == "MEM" { rgb("#FFD580") } else { white })
      content((x, y), text(size: 8pt)[#s])
    }

    for (i, s) in stages.enumerate() {
      let x = 3.5 + i * 2.0
      let y = 3.5
      rect((x - boxw/2, y - boxh/2), (x + boxw/2, y + boxh/2),
        fill: if s == "EX" { rgb("#FFD580") } else { white })
      content((x, y), text(size: 8pt)[#s])
    }

    line((7.5, 4.9), (7.5, 4.1),
      stroke: (paint: red, thickness: 1.5pt),
      mark: (end: ">", fill: red))
    content((9.0, 4.5), text(size: 7pt, fill: red)[Forward\ EX/MEM to ALU\ ForwardA = 10], anchor: "west")
  }),
  caption: [Pipeline timing: add result forwarded from EX/MEM to sub in EX],
) <fwd-scenario>

At CC4:
- `add` is in MEM, so its result sits in EX/MEM.ALUResult
- `sub` is in EX, so it needs register 1 as ALU input A
- EX/MEM.RegWrite = 1, EX/MEM.Rd = 1, ID/EX.Rs = 1
- Therefore X = 1, so ForwardA = 10

No stall is needed.

// ─────────────────────────────────────────────
// 4  HAZARD DETECTION UNIT
// ─────────────────────────────────────────────

= Hazard Detection Unit

== Purpose

The hazard detection unit detects *load-use* hazards — cases where a `lw` instruction is immediately followed by an instruction that uses the loaded register. Since the data emerges from memory one cycle too late for forwarding, the pipeline must stall for exactly one cycle.

== Block Diagram

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    rect((0, 0), (10, 5), name: "hdu")
    content((5, 2.5), text(weight: "bold", size: 10pt)[Hazard Detection Unit])

    let inputs = (
      ("ID/EX.MemRead", 4.2),
      ("ID/EX.RegisterRt", 3.4),
      ("IF/ID.RegisterRs", 1.6),
      ("IF/ID.RegisterRt", 0.8),
    )
    for (label, y) in inputs {
      line((-3.5, y), (0, y), mark: (end: ">", fill: black))
      content((-3.7, y), text(size: 8pt)[#label], anchor: "east")
    }

    let outputs = (
      ("PCWrite", 4.0),
      ("IF/ID Write", 2.5),
      ("ControlZero", 1.0),
    )
    for (label, y) in outputs {
      line((10, y), (13.0, y), mark: (end: ">", fill: black))
      content((13.2, y), text(size: 8pt)[#label], anchor: "west")
    }
  }),
  caption: [Hazard detection unit — external interface],
) <hdu-block>

== Inputs and Outputs

#table(
  columns: 3,
  [*Signal*], [*Direction*], [*Width*],
  [`ID/EX.MemRead`], [Input], [1 bit],
  [`ID/EX.RegisterRt`], [Input], [3 bits],
  [`IF/ID.RegisterRs`], [Input], [3 bits],
  [`IF/ID.RegisterRt`], [Input], [3 bits],
  [`PCWrite`], [Output], [1 bit],
  [`IF/ID Write`], [Output], [1 bit],
  [`ControlZero`], [Output], [1 bit],
)

Output meanings:
- PCWrite = 0: freeze the program counter
- IF/ID Write = 0: freeze the IF/ID pipeline register
- ControlZero = 1: zero out control signals entering ID/EX (insert NOP bubble)

== Hazard Condition

Define:

- *M* = ID/EX.MemRead
- *A* = (ID/EX.Rt = IF/ID.Rs)
- *B* = (ID/EX.Rt = IF/ID.Rt)

The load-use hazard exists when:

*Hazard = M AND (A OR B)*

== Truth Table

#figure(
  table(
    columns: 7,
    [*M*], [*A*], [*B*], [*Hazard*], [*PCWrite*], [*IF/ID Write*], [*CtrlZero*],
    [0], [0], [0], [0], [1], [1], [0],
    [0], [0], [1], [0], [1], [1], [0],
    [0], [1], [0], [0], [1], [1], [0],
    [0], [1], [1], [0], [1], [1], [0],
    [1], [0], [0], [0], [1], [1], [0],
    [1], [0], [1], [1], [0], [0], [1],
    [1], [1], [0], [1], [0], [0], [1],
    [1], [1], [1], [1], [0], [0], [1],
  ),
  caption: [Truth table for the hazard detection unit],
) <hdu-tt>

== Karnaugh Map for Hazard

#figure(
  stack(
    dir: ttb,
    spacing: 0.4em,
    text(weight: "bold", size: 9pt)[Hazard],
    table(
      columns: 5,
      [_M_ \\ _AB_], [*00*], [*01*], [*11*], [*10*],
      [*0*], [0], [0], [0], [0],
      [*1*], [0], [1], [1], [1],
    ),
  ),
  caption: [K-map for the Hazard signal],
) <hdu-kmap>

Groupings:

- Group 1 (cells M=1 AB=01 and M=1 AB=11): M AND B
- Group 2 (cells M=1 AB=10 and M=1 AB=11): M AND A

Result:

*Hazard = (M AND A) OR (M AND B) = M AND (A OR B)*

== Boolean Equations

- *Hazard* = ID/EX.MemRead AND ((ID/EX.Rt = IF/ID.Rs) OR (ID/EX.Rt = IF/ID.Rt))
- *PCWrite* = NOT(Hazard)
- *IF/ID Write* = NOT(Hazard)
- *ControlZero* = Hazard

== Internal Logic Diagram

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let comp(pos, label) = {
      rect(
        (pos.at(0) - 1.4, pos.at(1) - 0.5),
        (pos.at(0) + 1.4, pos.at(1) + 0.5),
      )
      content(pos, text(size: 7pt)[#label])
    }

    let gate(pos, label) = {
      rect(
        (pos.at(0) - 0.7, pos.at(1) - 0.4),
        (pos.at(0) + 0.7, pos.at(1) + 0.4),
      )
      content(pos, text(size: 7pt, weight: "bold")[#label])
    }

    content((-2.5, 6.0), text(size: 7pt)[ID/EX.Rt], anchor: "east")
    content((-2.5, 4.5), text(size: 7pt)[IF/ID.Rs], anchor: "east")
    content((-2.5, 2.5), text(size: 7pt)[IF/ID.Rt], anchor: "east")
    content((-2.5, 7.5), text(size: 7pt)[ID/EX.MemRead], anchor: "east")

    comp((2.0, 5.2), [EQ: A\ ID/EX.Rt = IF/ID.Rs])
    line((-2.3, 6.0), (0.6, 5.5), mark: (end: ">", fill: black))
    line((-2.3, 4.5), (0.6, 4.9), mark: (end: ">", fill: black))

    comp((2.0, 3.0), [EQ: B\ ID/EX.Rt = IF/ID.Rt])
    line((-0.5, 6.0), (0.6, 3.3))
    line((-2.3, 2.5), (0.6, 2.7), mark: (end: ">", fill: black))

    gate((5.5, 4.1), [OR])
    line((3.4, 5.2), (4.8, 4.3), mark: (end: ">", fill: black))
    line((3.4, 3.0), (4.8, 3.9), mark: (end: ">", fill: black))

    gate((8.5, 5.5), [AND])
    line((6.2, 4.1), (7.8, 5.2), mark: (end: ">", fill: black))
    line((-2.3, 7.5), (7.8, 5.8), mark: (end: ">", fill: black))

    line((9.2, 5.5), (11.0, 5.5), mark: (end: ">", fill: black))
    content((11.2, 5.5), text(size: 8pt, weight: "bold")[Hazard], anchor: "west")

    circle((11.8, 4.0), radius: 0.25)
    content((11.8, 4.0), text(size: 7pt)[N])
    line((10.5, 5.5), (11.55, 4.2))

    line((12.05, 4.0), (13.5, 4.0), mark: (end: ">", fill: black))
    content((13.7, 4.0), text(size: 7pt)[PCWrite = NOT Hazard], anchor: "west")

    line((12.05, 3.7), (13.5, 3.2), mark: (end: ">", fill: black))
    content((13.7, 3.2), text(size: 7pt)[IF/ID Write = NOT Hazard], anchor: "west")

    line((10.5, 5.3), (13.5, 2.3), mark: (end: ">", fill: black))
    content((13.7, 2.3), text(size: 7pt)[ControlZero = Hazard], anchor: "west")
  }),
  caption: [Internal logic of the hazard detection unit],
) <hdu-logic>

== Sample Scenario: Load-Use Hazard with Stall

Consider the instruction sequence:

```asm
lw  r1, 0(r2)
add r3, r1, r4
```

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let stages = ("IF", "ID", "EX", "MEM", "WB")

    for i in range(8) {
      content((2.2 + i * 2.0, 8.5), text(size: 8pt, weight: "bold")[CC#(i + 1)])
    }
    line((1.5, 8.1), (18.0, 8.1), mark: (end: ">", fill: black))
    content((18.2, 8.1), text(size: 7pt)[Time], anchor: "west")

    content((0.0, 6.5), text(size: 8pt)[lw r1, 0(r2)], anchor: "east")
    content((0.0, 4.5), text(size: 8pt)[add r3, r1, r4], anchor: "east")
    content((0.0, 2.5), text(size: 8pt)[add (retry)], anchor: "east")

    let boxw = 1.6
    let boxh = 1.0

    for (i, s) in stages.enumerate() {
      let x = 1.5 + i * 2.0
      let y = 6.5
      rect((x - boxw/2, y - boxh/2), (x + boxw/2, y + boxh/2),
        fill: if s == "EX" { rgb("#FFAAAA") } else { white })
      content((x, y), text(size: 8pt)[#s])
    }

    rect((3.5 - boxw/2, 4.5 - boxh/2), (3.5 + boxw/2, 4.5 + boxh/2))
    content((3.5, 4.5), text(size: 8pt)[IF])

    rect((5.5 - boxw/2, 4.5 - boxh/2), (5.5 + boxw/2, 4.5 + boxh/2),
      fill: rgb("#FFAAAA"))
    content((5.5, 4.5), text(size: 8pt)[ID])

    rect((7.5 - boxw/2, 4.5 - boxh/2), (7.5 + boxw/2, 4.5 + boxh/2),
      fill: rgb("#DDDDDD"))
    content((7.5, 4.5), text(size: 7pt)[STALL])

    let retry-stages = ("ID", "EX", "MEM", "WB")
    for (i, s) in retry-stages.enumerate() {
      let x = 7.5 + i * 2.0
      let y = 2.5
      rect((x - boxw/2, y - boxh/2), (x + boxw/2, y + boxh/2))
      content((x, y), text(size: 8pt)[#s])
    }

    line((5.5, 5.5), (5.5, 7.0),
      stroke: (paint: red, thickness: 1.2pt, dash: "dashed"))
    content((5.5, 7.3), text(size: 7pt, fill: red)[Hazard\ detected!], anchor: "south")

    line((9.5, 6.0), (9.5, 3.0),
      stroke: (paint: blue, thickness: 1.2pt),
      mark: (end: ">", fill: blue))
    content((10.8, 4.5), text(size: 7pt, fill: blue)[Forward\ MEM/WB to ALU], anchor: "west")
  }),
  caption: [Pipeline timing: load-use hazard — stall then forward],
) <hdu-scenario>

At CC3:
- `lw` is in EX, so ID/EX.MemRead = 1 and ID/EX.Rt = 1
- `add` is in ID, so IF/ID.Rs = 1

Therefore:

- A = 1, B = 0, M = 1
- Hazard = 1 AND (1 OR 0) = 1

Outputs:
- PCWrite = 0: PC frozen
- IF/ID Write = 0: IF/ID frozen
- ControlZero = 1: bubble (NOP) injected into ID/EX

After the one-cycle stall, at CC5:
- `lw` is in WB, so the loaded value sits in MEM/WB
- `add` is retried in EX
- The forwarding unit selects ForwardA = 01 (forward from MEM/WB)

The pipeline resumes correctly.

// ─────────────────────────────────────────────
// 5  MEM/WB FORWARDING SCENARIO
// ─────────────────────────────────────────────

= Additional Scenario: MEM/WB Forwarding

Consider:

```asm
add r1, r2, r3
nop
sub r4, r1, r5
```

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let stages = ("IF", "ID", "EX", "MEM", "WB")

    for i in range(8) {
      content((2.2 + i * 2.0, 9.0), text(size: 8pt, weight: "bold")[CC#(i + 1)])
    }
    line((1.5, 8.6), (18.0, 8.6), mark: (end: ">", fill: black))

    content((0.0, 7.0), text(size: 8pt)[add r1, r2, r3], anchor: "east")
    content((0.0, 5.0), text(size: 8pt)[nop], anchor: "east")
    content((0.0, 3.0), text(size: 8pt)[sub r4, r1, r5], anchor: "east")

    let boxw = 1.6
    let boxh = 1.0

    for (i, s) in stages.enumerate() {
      let x = 1.5 + i * 2.0
      rect((x - boxw/2, 7.0 - boxh/2), (x + boxw/2, 7.0 + boxh/2),
        fill: if s == "WB" { rgb("#B0FFB0") } else { white })
      content((x, 7.0), text(size: 8pt)[#s])
    }

    for (i, s) in stages.enumerate() {
      let x = 3.5 + i * 2.0
      rect((x - boxw/2, 5.0 - boxh/2), (x + boxw/2, 5.0 + boxh/2),
        fill: rgb("#EEEEEE"))
      content((x, 5.0), text(size: 8pt)[#s])
    }

    for (i, s) in stages.enumerate() {
      let x = 5.5 + i * 2.0
      rect((x - boxw/2, 3.0 - boxh/2), (x + boxw/2, 3.0 + boxh/2),
        fill: if s == "EX" { rgb("#B0FFB0") } else { white })
      content((x, 3.0), text(size: 8pt)[#s])
    }

    line((9.5, 6.5), (9.5, 3.5),
      stroke: (paint: rgb("#007700"), thickness: 1.5pt),
      mark: (end: ">", fill: rgb("#007700")))
    content((10.8, 5.0), text(size: 7pt, fill: rgb("#007700"))[Forward\ MEM/WB to ALU\ ForwardA = 01], anchor: "west")
  }),
  caption: [Pipeline timing: MEM/WB forwarding (two instructions apart)],
) <memwb-scenario>

At CC5:
- `add` is in WB, so MEM/WB.RegWrite = 1 and MEM/WB.Rd = 1
- `sub` is in EX, so ID/EX.Rs = 1
- EX/MEM does not match (the nop does not write any register)

Therefore:

- X = 0, Y = 1
- ForwardA = (NOT X) AND Y = 01

The ALU input A is forwarded from MEM/WB.

// ─────────────────────────────────────────────
// 6  LAB-SPECIFIC NOTES
// ─────────────────────────────────────────────

= Notes for This Laboratory

- The processor uses an *8-bit datapath* and *8 registers* (3-bit register addresses).
- The forwarding and hazard detection logic operates on *register identifiers*, not data width.
- Therefore, all equations and circuits derived above apply directly.
- Each comparator compares 3-bit register fields.
- The non-zero detector checks that the 3-bit destination is not 000.

= Summary of All Boolean Equations

=== Forwarding Unit

- X = EX/MEM.RegWrite AND (EX/MEM.Rd is not 0) AND (EX/MEM.Rd = ID/EX.Rs)
- Y = MEM/WB.RegWrite AND (MEM/WB.Rd is not 0) AND (MEM/WB.Rd = ID/EX.Rs)
- P = EX/MEM.RegWrite AND (EX/MEM.Rd is not 0) AND (EX/MEM.Rd = ID/EX.Rt)
- Q = MEM/WB.RegWrite AND (MEM/WB.Rd is not 0) AND (MEM/WB.Rd = ID/EX.Rt)

Outputs:

- ForwardA1 = X
- ForwardA0 = (NOT X) AND Y
- ForwardB1 = P
- ForwardB0 = (NOT P) AND Q

=== Hazard Detection Unit

- Hazard = ID/EX.MemRead AND ((ID/EX.Rt = IF/ID.Rs) OR (ID/EX.Rt = IF/ID.Rt))
- PCWrite = NOT(Hazard)
- IF/ID Write = NOT(Hazard)
- ControlZero = Hazard

= Conclusion

Two units have been designed for the pipelined processor:

The *forwarding unit* resolves most read-after-write data hazards by selecting operand values from the EX/MEM or MEM/WB pipeline registers instead of the register file. Priority is given to EX/MEM because it contains the most recent result.

The *hazard detection unit* detects load-use hazards that cannot be solved by forwarding alone. It stalls the pipeline for one cycle by disabling writes to the PC and IF/ID register while inserting a bubble into the ID/EX stage.

Together, these two units ensure correct execution of data-dependent instructions in the pipelined processor while minimizing unnecessary stalls.