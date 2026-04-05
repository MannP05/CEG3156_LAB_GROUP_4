-- ============================================================
-- EX/MEM Pipeline Register
-- Stores: MEM/WB control signals, branch target, zero flag,
--         ALU result, read data 2, destination register
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY EXMEM_reg IS
    PORT(
        i_clock        : IN  STD_LOGIC;
        i_reset        : IN  STD_LOGIC;
        i_flush        : IN  STD_LOGIC;
        -- Control in
        i_MemtoReg     : IN  STD_LOGIC;
        i_RegWrite     : IN  STD_LOGIC;
        i_MemRead      : IN  STD_LOGIC;
        i_MemWrite     : IN  STD_LOGIC;
        i_Branch       : IN  STD_LOGIC;
        i_Jump         : IN  STD_LOGIC;
        -- Data in
        i_BranchTarget : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_JumpAddr     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_Zero         : IN  STD_LOGIC;
        i_ALUResult    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_ReadData2    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_WriteReg     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        -- Control out
        o_MemtoReg     : OUT STD_LOGIC;
        o_RegWrite     : OUT STD_LOGIC;
        o_MemRead      : OUT STD_LOGIC;
        o_MemWrite     : OUT STD_LOGIC;
        o_Branch       : OUT STD_LOGIC;
        o_Jump         : OUT STD_LOGIC;
        -- Data out
        o_BranchTarget : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_JumpAddr     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_Zero         : OUT STD_LOGIC;
        o_ALUResult    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_ReadData2    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_WriteReg     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END EXMEM_reg;

ARCHITECTURE structural OF EXMEM_reg IS

    COMPONENT dFF_reset IS
        PORT(
            i_d     : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC;
            o_qBar  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT reg_8 IS
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL int_reset   : STD_LOGIC;
    SIGNAL int_wreg_q  : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    int_reset <= i_reset OR i_flush;

    -- 1-bit control FFs
    FF_MemtoReg : dFF_reset PORT MAP(i_MemtoReg, i_clock, int_reset, o_MemtoReg, OPEN);
    FF_RegWrite : dFF_reset PORT MAP(i_RegWrite, i_clock, int_reset, o_RegWrite, OPEN);
    FF_MemRead  : dFF_reset PORT MAP(i_MemRead,  i_clock, int_reset, o_MemRead,  OPEN);
    FF_MemWrite : dFF_reset PORT MAP(i_MemWrite, i_clock, int_reset, o_MemWrite, OPEN);
    FF_Branch   : dFF_reset PORT MAP(i_Branch,   i_clock, int_reset, o_Branch,   OPEN);
    FF_Jump     : dFF_reset PORT MAP(i_Jump,     i_clock, int_reset, o_Jump,     OPEN);
    FF_Zero     : dFF_reset PORT MAP(i_Zero,     i_clock, int_reset, o_Zero,     OPEN);

    -- 8-bit data registers
    U_BT  : reg_8 PORT MAP(i_BranchTarget, '1', i_clock, int_reset, o_BranchTarget);
    U_JA  : reg_8 PORT MAP(i_JumpAddr,     '1', i_clock, int_reset, o_JumpAddr);
    U_ALU : reg_8 PORT MAP(i_ALUResult,    '1', i_clock, int_reset, o_ALUResult);
    U_RD2 : reg_8 PORT MAP(i_ReadData2,    '1', i_clock, int_reset, o_ReadData2);

    -- 3-bit write register
    GEN_WR: FOR i IN 0 TO 2 GENERATE
        FF: dFF_reset PORT MAP(i_WriteReg(i), i_clock, int_reset, int_wreg_q(i), OPEN);
    END GENERATE;
    o_WriteReg <= int_wreg_q;

END structural;