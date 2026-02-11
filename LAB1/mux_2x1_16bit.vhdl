LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux_2x1_16bit IS
    PORT (
        in_0, in_1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        in_sel     : IN STD_LOGIC;
        out_mux    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END mux_2x1_16bit;

ARCHITECTURE structural OF mux_2x1_16bit IS
    COMPONENT quad_n_mux_selector
        GENERIC ( BITS : integer );
        PORT (
            in_tt, in_tf, in_ft, in_ff : IN STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
            in_sel_tt, in_sel_tf, in_sel_ft, in_sel_ff : IN STD_LOGIC;
            out_mux : OUT STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL s_not_sel : STD_LOGIC;
    SIGNAL s_zeros   : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
BEGIN
    s_not_sel <= NOT in_sel;

    U_MUX: quad_n_mux_selector
    GENERIC MAP ( BITS => 16 )
    PORT MAP (
        in_tt => in_1, in_tf => in_0,
        in_ft => s_zeros, in_ff => s_zeros,
        in_sel_tt => in_sel, in_sel_tf => s_not_sel,
        in_sel_ft => '0', in_sel_ff => '0',
        out_mux => out_mux
    );
END structural;