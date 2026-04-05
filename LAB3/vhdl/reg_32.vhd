-- ============================================================
-- 32-bit Register (structural, built from four reg_8)
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_32 IS
    PORT(
        i_d     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        i_load  : IN  STD_LOGIC;
        i_clock : IN  STD_LOGIC;
        i_reset : IN  STD_LOGIC;
        o_q     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END reg_32;

ARCHITECTURE structural OF reg_32 IS

    COMPONENT reg_8 IS
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    U_BYTE0 : reg_8
        PORT MAP(i_d => i_d(7 DOWNTO 0),   i_load => i_load,
                 i_clock => i_clock, i_reset => i_reset,
                 o_q => o_q(7 DOWNTO 0));

    U_BYTE1 : reg_8
        PORT MAP(i_d => i_d(15 DOWNTO 8),  i_load => i_load,
                 i_clock => i_clock, i_reset => i_reset,
                 o_q => o_q(15 DOWNTO 8));

    U_BYTE2 : reg_8
        PORT MAP(i_d => i_d(23 DOWNTO 16), i_load => i_load,
                 i_clock => i_clock, i_reset => i_reset,
                 o_q => o_q(23 DOWNTO 16));

    U_BYTE3 : reg_8
        PORT MAP(i_d => i_d(31 DOWNTO 24), i_load => i_load,
                 i_clock => i_clock, i_reset => i_reset,
                 o_q => o_q(31 DOWNTO 24));

END structural;