--------------------------------------------------------------------------------
-- Title         : D Flip-Flop
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : dFF_2.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A positive-edge triggered D flip-flop. It takes a single 
--               data input and a clock signal, and provides both the true 
--               output (o_q) and the complemented output (o_qBar).
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dFF_2 IS
    PORT(
        i_d      : IN  STD_LOGIC;
        i_clock  : IN  STD_LOGIC;
        o_q      : OUT STD_LOGIC;
        o_qBar   : OUT STD_LOGIC
    );
END dFF_2;

ARCHITECTURE rtl OF dFF_2 IS
    SIGNAL int_q : STD_LOGIC;
BEGIN

    oneBitRegister:
    PROCESS(i_clock)
    BEGIN
        IF (i_clock'EVENT and i_clock = '1') THEN
            int_q <= i_d;
        END IF;
    END PROCESS oneBitRegister;

    o_q    <= int_q;
    o_qBar <= not(int_q);

END rtl;