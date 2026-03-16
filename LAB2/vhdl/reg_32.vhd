    LIBRARY ieee;
    USE ieee.std_logic_1164.ALL;

    ENTITY reg_32 IS
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END reg_32;

    ARCHITECTURE structural OF reg_32 IS

        SIGNAL int_mux : STD_LOGIC_VECTOR(31 DOWNTO 0);
        SIGNAL int_q   : STD_LOGIC_VECTOR(31 DOWNTO 0);

        COMPONENT dFF_2
            PORT(
                i_d     : IN  STD_LOGIC;
                i_clock : IN  STD_LOGIC;
                o_q     : OUT STD_LOGIC;
                o_qBar  : OUT STD_LOGIC
            );
        END COMPONENT;

    BEGIN

        -- Mux: load new value or hold current value
        int_mux <= i_d WHEN i_load = '1' ELSE int_q;

        -- 32 D flip-flop instantiations
        ff0:  dFF_2 PORT MAP(i_d => int_mux(0),  i_clock => i_clock, o_q => int_q(0),  o_qBar => OPEN);
        ff1:  dFF_2 PORT MAP(i_d => int_mux(1),  i_clock => i_clock, o_q => int_q(1),  o_qBar => OPEN);
        ff2:  dFF_2 PORT MAP(i_d => int_mux(2),  i_clock => i_clock, o_q => int_q(2),  o_qBar => OPEN);
        ff3:  dFF_2 PORT MAP(i_d => int_mux(3),  i_clock => i_clock, o_q => int_q(3),  o_qBar => OPEN);
        ff4:  dFF_2 PORT MAP(i_d => int_mux(4),  i_clock => i_clock, o_q => int_q(4),  o_qBar => OPEN);
        ff5:  dFF_2 PORT MAP(i_d => int_mux(5),  i_clock => i_clock, o_q => int_q(5),  o_qBar => OPEN);
        ff6:  dFF_2 PORT MAP(i_d => int_mux(6),  i_clock => i_clock, o_q => int_q(6),  o_qBar => OPEN);
        ff7:  dFF_2 PORT MAP(i_d => int_mux(7),  i_clock => i_clock, o_q => int_q(7),  o_qBar => OPEN);
        ff8:  dFF_2 PORT MAP(i_d => int_mux(8),  i_clock => i_clock, o_q => int_q(8),  o_qBar => OPEN);
        ff9:  dFF_2 PORT MAP(i_d => int_mux(9),  i_clock => i_clock, o_q => int_q(9),  o_qBar => OPEN);
        ff10: dFF_2 PORT MAP(i_d => int_mux(10), i_clock => i_clock, o_q => int_q(10), o_qBar => OPEN);
        ff11: dFF_2 PORT MAP(i_d => int_mux(11), i_clock => i_clock, o_q => int_q(11), o_qBar => OPEN);
        ff12: dFF_2 PORT MAP(i_d => int_mux(12), i_clock => i_clock, o_q => int_q(12), o_qBar => OPEN);
        ff13: dFF_2 PORT MAP(i_d => int_mux(13), i_clock => i_clock, o_q => int_q(13), o_qBar => OPEN);
        ff14: dFF_2 PORT MAP(i_d => int_mux(14), i_clock => i_clock, o_q => int_q(14), o_qBar => OPEN);
        ff15: dFF_2 PORT MAP(i_d => int_mux(15), i_clock => i_clock, o_q => int_q(15), o_qBar => OPEN);
        ff16: dFF_2 PORT MAP(i_d => int_mux(16), i_clock => i_clock, o_q => int_q(16), o_qBar => OPEN);
        ff17: dFF_2 PORT MAP(i_d => int_mux(17), i_clock => i_clock, o_q => int_q(17), o_qBar => OPEN);
        ff18: dFF_2 PORT MAP(i_d => int_mux(18), i_clock => i_clock, o_q => int_q(18), o_qBar => OPEN);
        ff19: dFF_2 PORT MAP(i_d => int_mux(19), i_clock => i_clock, o_q => int_q(19), o_qBar => OPEN);
        ff20: dFF_2 PORT MAP(i_d => int_mux(20), i_clock => i_clock, o_q => int_q(20), o_qBar => OPEN);
        ff21: dFF_2 PORT MAP(i_d => int_mux(21), i_clock => i_clock, o_q => int_q(21), o_qBar => OPEN);
        ff22: dFF_2 PORT MAP(i_d => int_mux(22), i_clock => i_clock, o_q => int_q(22), o_qBar => OPEN);
        ff23: dFF_2 PORT MAP(i_d => int_mux(23), i_clock => i_clock, o_q => int_q(23), o_qBar => OPEN);
        ff24: dFF_2 PORT MAP(i_d => int_mux(24), i_clock => i_clock, o_q => int_q(24), o_qBar => OPEN);
        ff25: dFF_2 PORT MAP(i_d => int_mux(25), i_clock => i_clock, o_q => int_q(25), o_qBar => OPEN);
        ff26: dFF_2 PORT MAP(i_d => int_mux(26), i_clock => i_clock, o_q => int_q(26), o_qBar => OPEN);
        ff27: dFF_2 PORT MAP(i_d => int_mux(27), i_clock => i_clock, o_q => int_q(27), o_qBar => OPEN);
        ff28: dFF_2 PORT MAP(i_d => int_mux(28), i_clock => i_clock, o_q => int_q(28), o_qBar => OPEN);
        ff29: dFF_2 PORT MAP(i_d => int_mux(29), i_clock => i_clock, o_q => int_q(29), o_qBar => OPEN);
        ff30: dFF_2 PORT MAP(i_d => int_mux(30), i_clock => i_clock, o_q => int_q(30), o_qBar => OPEN);
        ff31: dFF_2 PORT MAP(i_d => int_mux(31), i_clock => i_clock, o_q => int_q(31), o_qBar => OPEN);

        -- Output driver
        o_q <= int_q;

    END structural;