-- ============================================================
-- MEM/WB Pipeline Register
-- Stores: WB control signals, memory read data, ALU result,
--         destination register
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY MEMWB_reg IS
    PORT(
        i_clock       : IN  STD_LOGIC;
        i_reset       : IN  STD_LOGIC;
        -- Control in
        i_MemtoReg    : IN  STD_LOGIC;
        i_RegWrite    : IN  STD_LOGIC;
        -- Data in
        i_MemReadData : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_ALUResult   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_WriteReg    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        -- Control out
        o_MemtoReg    : OUT STD_LOGIC;
        o_RegWrite    : OUT STD_LOGIC;
        -- Data out
        o_MemReadData : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_ALUResult   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_WriteReg    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END MEMWB_reg;

ARCHITECTURE structural OF MEMWB_reg IS

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

    SIGNAL int_wreg_q : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    -- 1-bit control FFs
    FF_MemtoReg : dFF_reset PORT MAP(i_MemtoReg, i_clock, i_reset, o_MemtoReg, OPEN);
    FF_RegWrite : dFF_reset PORT MAP(i_RegWrite, i_clock, i_reset, o_RegWrite, OPEN);

    -- 8-bit data
    U_MRD : reg_8 PORT MAP(i_MemReadData, '1', i_clock, i_reset, o_MemReadData);
    U_ALU : reg_8 PORT MAP(i_ALUResult,   '1', i_clock, i_reset, o_ALUResult);

    -- 3-bit write register
    GEN_WR: FOR i IN 0 TO 2 GENERATE
        FF: dFF_reset PORT MAP(i_WriteReg(i), i_clock, i_reset, int_wreg_q(i), OPEN);
    END GENERATE;
    o_WriteReg <= int_wreg_q;

END structural;