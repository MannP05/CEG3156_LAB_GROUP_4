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

    -- AND gate: forces '0' into FF when reset is active
    int_d <= i_d AND (NOT i_reset);

    -- Base flip-flop (no process here, purely structural instantiation)
    ff: dFF_2 PORT MAP(
        i_d     => int_d,
        i_clock => i_clock,
        o_q     => o_q,
        o_qBar  => o_qBar
    );

END structural;