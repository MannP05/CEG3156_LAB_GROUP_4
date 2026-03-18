--------------------------------------------------------------------------------
-- Title         : D Flip-Flop with Reset
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : dFF_reset.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A structural positive-edge triggered D flip-flop with a 
--               synchronous active-high reset. It utilizes a basic D flip-flop 
--               component and combinational logic to clear the stored value 
--               (force to '0') when the reset signal is asserted.
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dFF_reset IS
    PORT(
        i_d     : IN  STD_LOGIC;
        i_clock : IN  STD_LOGIC;
        i_reset : IN  STD_LOGIC;
        o_q     : OUT STD_LOGIC;
        o_qBar  : OUT STD_LOGIC
    );
END dFF_reset;

ARCHITECTURE structural OF dFF_reset IS

    SIGNAL int_d : STD_LOGIC;

    COMPONENT dFF_2
        PORT(
            i_d     : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC;
            o_qBar  : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    int_d <= i_d AND (NOT i_reset);

    ff: dFF_2 PORT MAP(
        i_d     => int_d,
        i_clock => i_clock,
        o_q     => o_q,
        o_qBar  => o_qBar
    );

END structural;