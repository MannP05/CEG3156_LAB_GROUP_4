-- ============================================================
-- CEG 3156 Lab 2 - Program Counter Register
-- 8-bit register, updates every clock cycle (i_load tied high)
-- ============================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY pc_reg IS
    PORT(
        i_clock : IN  STD_LOGIC;
        i_reset : IN  STD_LOGIC;
        i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END pc_reg;

ARCHITECTURE structural OF pc_reg IS

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

    -- PC always loads on every rising edge: i_load tied to '1'
    U_REG : reg_8
        PORT MAP(
            i_d     => i_d,
            i_load  => '1',
            i_clock => i_clock,
            i_reset => i_reset,
            o_q     => o_q
        );

END structural;