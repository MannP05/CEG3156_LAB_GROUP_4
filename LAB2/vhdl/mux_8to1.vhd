LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.mux_package.ALL;

ENTITY mux_8to1_8bit IS
    PORT(
        i_inputs : IN  bus_array_8;
        i_sel    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        o_y      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END mux_8to1_8bit;

ARCHITECTURE structural OF mux_8to1_8bit IS

    COMPONENT mux_2to1
        PORT(
            i_a   : IN  STD_LOGIC;  -- selected when sel='0'
            i_b   : IN  STD_LOGIC;  -- selected when sel='1'
            i_sel : IN  STD_LOGIC;
            o_y   : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Layer 1 intermediate signals (4 groups)
    SIGNAL int_layer1_0 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(input0, input1)
    SIGNAL int_layer1_1 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(input2, input3)
    SIGNAL int_layer1_2 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(input4, input5)
    SIGNAL int_layer1_3 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(input6, input7)

    -- Layer 2 intermediate signals (2 groups)
    SIGNAL int_layer2_0 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(L1_0, L1_1)
    SIGNAL int_layer2_1 : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- mux(L1_2, L1_3)

BEGIN

    -- Generate the mux tree for each bit position
    gen_bits: FOR b IN 0 TO 7 GENERATE

        -----------------------------------------------
        -- LAYER 1: 4 muxes selecting pairs with sel(0)
        -----------------------------------------------
        l1_m0: mux_2to1 PORT MAP(
            i_a   => i_inputs(0)(b),
            i_b   => i_inputs(1)(b),
            i_sel => i_sel(0),
            o_y   => int_layer1_0(b)
        );

        l1_m1: mux_2to1 PORT MAP(
            i_a   => i_inputs(2)(b),
            i_b   => i_inputs(3)(b),
            i_sel => i_sel(0),
            o_y   => int_layer1_1(b)
        );

        l1_m2: mux_2to1 PORT MAP(
            i_a   => i_inputs(4)(b),
            i_b   => i_inputs(5)(b),
            i_sel => i_sel(0),
            o_y   => int_layer1_2(b)
        );

        l1_m3: mux_2to1 PORT MAP(
            i_a   => i_inputs(6)(b),
            i_b   => i_inputs(7)(b),
            i_sel => i_sel(0),
            o_y   => int_layer1_3(b)
        );

        -----------------------------------------------
        -- LAYER 2: 2 muxes selecting pairs with sel(1)
        -----------------------------------------------
        l2_m0: mux_2to1 PORT MAP(
            i_a   => int_layer1_0(b),
            i_b   => int_layer1_1(b),
            i_sel => i_sel(1),
            o_y   => int_layer2_0(b)
        );

        l2_m1: mux_2to1 PORT MAP(
            i_a   => int_layer1_2(b),
            i_b   => int_layer1_3(b),
            i_sel => i_sel(1),
            o_y   => int_layer2_1(b)
        );

        -----------------------------------------------
        -- LAYER 3: 1 final mux selecting with sel(2)
        -----------------------------------------------
        l3_m0: mux_2to1 PORT MAP(
            i_a   => int_layer2_0(b),
            i_b   => int_layer2_1(b),
            i_sel => i_sel(2),
            o_y   => o_y(b)
        );

    END GENERATE;

END structural;