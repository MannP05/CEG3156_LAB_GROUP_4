-- ============================================================
-- IF/ID Pipeline Register
-- Stores: PC+4 and Instruction
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY IFID_reg IS
    PORT(
        i_clock       : IN  STD_LOGIC;
        i_reset       : IN  STD_LOGIC;
        i_flush       : IN  STD_LOGIC;   -- flush on branch taken
        i_stall       : IN  STD_LOGIC;   -- stall on load-use hazard
        -- Inputs
        i_PC4         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_instruction : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- Outputs
        o_PC4         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_instruction : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END IFID_reg;

ARCHITECTURE structural OF IFID_reg IS

    COMPONENT reg_8 IS
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    -- 32-bit register built from four 8-bit registers
    COMPONENT reg_32 IS
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL int_reset : STD_LOGIC;
    SIGNAL int_load  : STD_LOGIC;

BEGIN
    -- flush or reset clears the register (insert NOP)
    int_reset <= i_reset OR i_flush;
    -- stall holds the register (do not load new value)
    int_load  <= NOT i_stall;

    U_PC4 : reg_8
        PORT MAP(
            i_d     => i_PC4,
            i_load  => int_load,
            i_clock => i_clock,
            i_reset => int_reset,
            o_q     => o_PC4
        );

    U_INSTR : reg_32
        PORT MAP(
            i_d     => i_instruction,
            i_load  => int_load,
            i_clock => i_clock,
            i_reset => int_reset,
            o_q     => o_instruction
        );

END structural;