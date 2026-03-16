LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.mux_package.ALL;

ENTITY mux_32_to_1 IS
    PORT(
        i_inputs : IN  bus_array_32;
        i_sel    : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        o_y      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END mux_32_to_1;

ARCHITECTURE structural OF mux_32_to_1 IS

    COMPONENT mux_2x1
        GENERIC ( BITS : INTEGER := 8 );
        PORT(
            in_0    : IN  STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            in_1    : IN  STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            in_sel  : IN  STD_LOGIC;
            out_mux : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL s0_0,  s0_1,  s0_2,  s0_3  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s0_4,  s0_5,  s0_6,  s0_7  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s0_8,  s0_9,  s0_10, s0_11 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s0_12, s0_13, s0_14, s0_15 : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL s1_0, s1_1, s1_2, s1_3 : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL s1_4, s1_5, s1_6, s1_7 : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL s2_0, s2_1, s2_2, s2_3 : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL s3_0, s3_1 : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
    -- mux tree

    -- 16 muxes
    s0_m0:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(0),  in_1=>i_inputs(1),  in_sel=>i_sel(0), out_mux=>s0_0);
    s0_m1:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(2),  in_1=>i_inputs(3),  in_sel=>i_sel(0), out_mux=>s0_1);
    s0_m2:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(4),  in_1=>i_inputs(5),  in_sel=>i_sel(0), out_mux=>s0_2);
    s0_m3:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(6),  in_1=>i_inputs(7),  in_sel=>i_sel(0), out_mux=>s0_3);
    s0_m4:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(8),  in_1=>i_inputs(9),  in_sel=>i_sel(0), out_mux=>s0_4);
    s0_m5:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(10), in_1=>i_inputs(11), in_sel=>i_sel(0), out_mux=>s0_5);
    s0_m6:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(12), in_1=>i_inputs(13), in_sel=>i_sel(0), out_mux=>s0_6);
    s0_m7:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(14), in_1=>i_inputs(15), in_sel=>i_sel(0), out_mux=>s0_7);
    s0_m8:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(16), in_1=>i_inputs(17), in_sel=>i_sel(0), out_mux=>s0_8);
    s0_m9:  mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(18), in_1=>i_inputs(19), in_sel=>i_sel(0), out_mux=>s0_9);
    s0_m10: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(20), in_1=>i_inputs(21), in_sel=>i_sel(0), out_mux=>s0_10);
    s0_m11: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(22), in_1=>i_inputs(23), in_sel=>i_sel(0), out_mux=>s0_11);
    s0_m12: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(24), in_1=>i_inputs(25), in_sel=>i_sel(0), out_mux=>s0_12);
    s0_m13: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(26), in_1=>i_inputs(27), in_sel=>i_sel(0), out_mux=>s0_13);
    s0_m14: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(28), in_1=>i_inputs(29), in_sel=>i_sel(0), out_mux=>s0_14);
    s0_m15: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>i_inputs(30), in_1=>i_inputs(31), in_sel=>i_sel(0), out_mux=>s0_15);

    -- 8 muxes
    s1_m0: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_0,  in_1=>s0_1,  in_sel=>i_sel(1), out_mux=>s1_0);
    s1_m1: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_2,  in_1=>s0_3,  in_sel=>i_sel(1), out_mux=>s1_1);
    s1_m2: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_4,  in_1=>s0_5,  in_sel=>i_sel(1), out_mux=>s1_2);
    s1_m3: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_6,  in_1=>s0_7,  in_sel=>i_sel(1), out_mux=>s1_3);
    s1_m4: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_8,  in_1=>s0_9,  in_sel=>i_sel(1), out_mux=>s1_4);
    s1_m5: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_10, in_1=>s0_11, in_sel=>i_sel(1), out_mux=>s1_5);
    s1_m6: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_12, in_1=>s0_13, in_sel=>i_sel(1), out_mux=>s1_6);
    s1_m7: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s0_14, in_1=>s0_15, in_sel=>i_sel(1), out_mux=>s1_7);

    -- 4 muxes
    s2_m0: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s1_0, in_1=>s1_1, in_sel=>i_sel(2), out_mux=>s2_0);
    s2_m1: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s1_2, in_1=>s1_3, in_sel=>i_sel(2), out_mux=>s2_1);
    s2_m2: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s1_4, in_1=>s1_5, in_sel=>i_sel(2), out_mux=>s2_2);
    s2_m3: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s1_6, in_1=>s1_7, in_sel=>i_sel(2), out_mux=>s2_3);

    -- 2 muxes
    s3_m0: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s2_0, in_1=>s2_1, in_sel=>i_sel(3), out_mux=>s3_0);
    s3_m1: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s2_2, in_1=>s2_3, in_sel=>i_sel(3), out_mux=>s3_1);


    s4_m0: mux_2x1 GENERIC MAP(BITS=>32) PORT MAP(in_0=>s3_0, in_1=>s3_1, in_sel=>i_sel(4), out_mux=>o_y);

END structural;