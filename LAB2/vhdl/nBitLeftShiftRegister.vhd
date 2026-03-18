LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitLeftShiftRegister IS
    GENERIC(n : INTEGER := 8);
    PORT(
        i_resetBar : IN  STD_LOGIC;
        i_clock    : IN  STD_LOGIC;
        i_Value    : IN  STD_LOGIC;
        o_Value    : OUT STD_LOGIC_VECTOR(n-1 downto 0)
    );
END nBitLeftShiftRegister;

ARCHITECTURE structural OF nBitLeftShiftRegister IS

    SIGNAL int_q, int_qBar : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL int_reset       : STD_LOGIC;

    COMPONENT dFF_reset
        PORT(
            i_d     : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC;
            o_qBar  : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN


    int_reset <= NOT i_resetBar;


    LSB_FF: dFF_reset
        PORT MAP (
            i_d     => i_Value,
            i_clock => i_clock,
            i_reset => int_reset,
            o_q     => int_q(0),
            o_qBar  => int_qBar(0)
        );

    
    GEN_SHIFT: FOR i IN 1 TO n-1 GENERATE
        SHIFT_FF: dFF_reset
            PORT MAP (
                i_d     => int_q(i-1),
                i_clock => i_clock,
                i_reset => int_reset,
                o_q     => int_q(i),
                o_qBar  => int_qBar(i)
            );
    END GENERATE GEN_SHIFT;

    o_Value <= int_q;

END structural;