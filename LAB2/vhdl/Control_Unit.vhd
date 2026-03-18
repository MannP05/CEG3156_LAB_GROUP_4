-- ============================================================
-- CEG 3156 Lab 2 - Main Control Unit
--
-- Supported opcodes:
--   R-format : 000000  -> RegDst=1, RegWrite=1, ALUOp=10
--   lw       : 100011  -> ALUSrc=1, MemtoReg=1, RegWrite=1, MemRead=1, ALUOp=00
--   sw       : 101011  -> ALUSrc=1, MemWrite=1, ALUOp=00
--   beq      : 000100  -> Branch=1, ALUOp=01
--   j        : 000010  -> Jump=1
-- ============================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Control_Unit IS
    PORT(
        opcode   : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);

        RegDst   : OUT STD_LOGIC;
        ALUSrc   : OUT STD_LOGIC;
        MemtoReg : OUT STD_LOGIC;
        RegWrite : OUT STD_LOGIC;
        MemRead  : OUT STD_LOGIC;
        MemWrite : OUT STD_LOGIC;
        Branch   : OUT STD_LOGIC;
        Jump     : OUT STD_LOGIC;
        ALUOp    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END Control_Unit;

ARCHITECTURE structural OF Control_Unit IS

    -- Inverted opcode bits (gates)
    SIGNAL nop5, nop4, nop3, nop2, nop1, nop0 : STD_LOGIC;

    -- One signal per recognised instruction
    SIGNAL R_format : STD_LOGIC;  -- opcode = 000000
    SIGNAL lw       : STD_LOGIC;  -- opcode = 100011
    SIGNAL sw       : STD_LOGIC;  -- opcode = 101011
    SIGNAL beq      : STD_LOGIC;  -- opcode = 000100
    SIGNAL jump_sig : STD_LOGIC;  -- opcode = 000010

BEGIN

    -- ----------------------------------------------------------
    -- Invert each opcode bit (NOT gates)
    -- ----------------------------------------------------------
    nop5 <= NOT opcode(5);
    nop4 <= NOT opcode(4);
    nop3 <= NOT opcode(3);
    nop2 <= NOT opcode(2);
    nop1 <= NOT opcode(1);
    nop0 <= NOT opcode(0);

    -- ----------------------------------------------------------
    -- Decode each instruction (AND gates on opcode bits)
    -- ----------------------------------------------------------

    -- R_format: opcode = 0 0 0 0 0 0
    R_format <= nop5 AND nop4 AND nop3 AND nop2 AND nop1 AND nop0;

    -- lw:  opcode = 1 0 0 0 1 1
    lw <= opcode(5) AND nop4 AND nop3 AND nop2 AND opcode(1) AND opcode(0);

    -- sw:  opcode = 1 0 1 0 1 1
    sw <= opcode(5) AND nop4 AND opcode(3) AND nop2 AND opcode(1) AND opcode(0);

    -- beq: opcode = 0 0 0 1 0 0
    beq <= nop5 AND nop4 AND nop3 AND opcode(2) AND nop1 AND nop0;

    -- j:   opcode = 0 0 0 0 1 0
    jump_sig <= nop5 AND nop4 AND nop3 AND nop2 AND opcode(1) AND nop0;

    -- ----------------------------------------------------------
    -- Drive output control signals (OR / wire assignments)
    -- ----------------------------------------------------------
    RegDst   <= R_format;
    ALUSrc   <= lw OR sw;
    MemtoReg <= lw;
    RegWrite <= R_format OR lw;
    MemRead  <= lw;
    MemWrite <= sw;
    Branch   <= beq;
    Jump     <= jump_sig;
    ALUOp(1) <= R_format;
    ALUOp(0) <= beq;

END structural;