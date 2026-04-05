-- ============================================================
-- ID/EX Pipeline Register
-- Stores: all control signals, PC+4, read data 1 & 2,
--         sign-extended immediate, rs/rt/rd register numbers
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY IDEX_reg IS
    PORT(
        i_clock      : IN  STD_LOGIC;
        i_reset      : IN  STD_LOGIC;
        i_flush      : IN  STD_LOGIC;  -- flush on stall or branch
        -- Control signals in
        i_RegDst     : IN  STD_LOGIC;
        i_ALUSrc     : IN  STD_LOGIC;
        i_MemtoReg   : IN  STD_LOGIC;
        i_RegWrite   : IN  STD_LOGIC;
        i_MemRead    : IN  STD_LOGIC;
        i_MemWrite   : IN  STD_LOGIC;
        i_Branch     : IN  STD_LOGIC;
        i_Jump       : IN  STD_LOGIC;
        i_ALUOp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        -- Data in
        i_PC4        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_ReadData1  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_ReadData2  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_SignExt    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_rs         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        i_rt         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        i_rd         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        i_funct      : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
        -- Control signals out
        o_RegDst     : OUT STD_LOGIC;
        o_ALUSrc     : OUT STD_LOGIC;
        o_MemtoReg   : OUT STD_LOGIC;
        o_RegWrite   : OUT STD_LOGIC;
        o_MemRead    : OUT STD_LOGIC;
        o_MemWrite   : OUT STD_LOGIC;
        o_Branch     : OUT STD_LOGIC;
        o_Jump       : OUT STD_LOGIC;
        o_ALUOp      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        -- Data out
        o_PC4        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_ReadData1  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_ReadData2  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_SignExt    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_rs         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        o_rt         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        o_rd         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        o_funct      : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
    );
END IDEX_reg;

ARCHITECTURE structural OF IDEX_reg IS

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
    -- 3-bit register signals
    SIGNAL int_rs_q    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL int_rt_q    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL int_rd_q    : STD_LOGIC_VECTOR(2 DOWNTO 0);
    -- 6-bit funct signals
    SIGNAL int_funct_q : STD_LOGIC_VECTOR(5 DOWNTO 0);
    -- 2-bit ALUOp
    SIGNAL int_aluop_q : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

    int_reset <= i_reset OR i_flush;

    -- ---- 1-bit control FFs ----
    FF_RegDst   : dFF_reset PORT MAP(i_RegDst,   i_clock, int_reset, o_RegDst,   OPEN);
    FF_ALUSrc   : dFF_reset PORT MAP(i_ALUSrc,   i_clock, int_reset, o_ALUSrc,   OPEN);
    FF_MemtoReg : dFF_reset PORT MAP(i_MemtoReg, i_clock, int_reset, o_MemtoReg, OPEN);
    FF_RegWrite : dFF_reset PORT MAP(i_RegWrite, i_clock, int_reset, o_RegWrite, OPEN);
    FF_MemRead  : dFF_reset PORT MAP(i_MemRead,  i_clock, int_reset, o_MemRead,  OPEN);
    FF_MemWrite : dFF_reset PORT MAP(i_MemWrite, i_clock, int_reset, o_MemWrite, OPEN);
    FF_Branch   : dFF_reset PORT MAP(i_Branch,   i_clock, int_reset, o_Branch,   OPEN);
    FF_Jump     : dFF_reset PORT MAP(i_Jump,     i_clock, int_reset, o_Jump,     OPEN);

    -- ---- 2-bit ALUOp ----
    FF_ALUOp0 : dFF_reset PORT MAP(i_ALUOp(0), i_clock, int_reset, int_aluop_q(0), OPEN);
    FF_ALUOp1 : dFF_reset PORT MAP(i_ALUOp(1), i_clock, int_reset, int_aluop_q(1), OPEN);
    o_ALUOp <= int_aluop_q;

    -- ---- 8-bit data registers ----
    U_PC4 : reg_8 PORT MAP(i_PC4,       '1', i_clock, int_reset, o_PC4);
    U_RD1 : reg_8 PORT MAP(i_ReadData1, '1', i_clock, int_reset, o_ReadData1);
    U_RD2 : reg_8 PORT MAP(i_ReadData2, '1', i_clock, int_reset, o_ReadData2);
    U_SE  : reg_8 PORT MAP(i_SignExt,   '1', i_clock, int_reset, o_SignExt);

    -- ---- 3-bit register number FFs ----
    GEN_RS: FOR i IN 0 TO 2 GENERATE
        FF: dFF_reset PORT MAP(i_rs(i), i_clock, int_reset, int_rs_q(i), OPEN);
    END GENERATE;
    o_rs <= int_rs_q;

    GEN_RT: FOR i IN 0 TO 2 GENERATE
        FF: dFF_reset PORT MAP(i_rt(i), i_clock, int_reset, int_rt_q(i), OPEN);
    END GENERATE;
    o_rt <= int_rt_q;

    GEN_RD: FOR i IN 0 TO 2 GENERATE
        FF: dFF_reset PORT MAP(i_rd(i), i_clock, int_reset, int_rd_q(i), OPEN);
    END GENERATE;
    o_rd <= int_rd_q;

    -- ---- 6-bit funct ----
    GEN_FUNCT: FOR i IN 0 TO 5 GENERATE
        FF: dFF_reset PORT MAP(i_funct(i), i_clock, int_reset, int_funct_q(i), OPEN);
    END GENERATE;
    o_funct <= int_funct_q;

END structural;