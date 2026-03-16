LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_8 IS
    PORT(
        i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_load  : IN  STD_LOGIC;
        i_clock : IN  STD_LOGIC;
        i_reset : IN  STD_LOGIC;
        o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END reg_8;

ARCHITECTURE structural OF reg_8 IS

    SIGNAL int_mux : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL int_q   : STD_LOGIC_VECTOR(7 DOWNTO 0);

    COMPONENT mux_2to1
        PORT(
            i_a   : IN  STD_LOGIC;
            i_b   : IN  STD_LOGIC;
            i_sel : IN  STD_LOGIC;
            o_y   : OUT STD_LOGIC
        );
    END COMPONENT;

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

    -- Structural mux: hold (int_q) when load='0', load (i_d) when load='1'
    gen_mux: FOR i IN 0 TO 7 GENERATE
        mux_i: mux_2to1 PORT MAP(
            i_a   => int_q(i),   -- hold current
            i_b   => i_d(i),     -- load new
            i_sel => i_load,
            o_y   => int_mux(i)
        );
    END GENERATE;

    -- 8 D flip-flops with reset
    gen_ff: FOR i IN 0 TO 7 GENERATE
        ff_i: dFF_reset PORT MAP(
            i_d     => int_mux(i),
            i_clock => i_clock,
            i_reset => i_reset,
            o_q     => int_q(i),
            o_qBar  => OPEN
        );
    END GENERATE;

    o_q <= int_q;

END structural;