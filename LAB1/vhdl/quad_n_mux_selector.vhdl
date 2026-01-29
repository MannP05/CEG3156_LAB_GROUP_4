LIBRARY ieee;
use ieee.std_logic_1164.ALL;

ENTITY quad_n_mux_selector IS 
    generic ( 
                BITS : integer := 4
            );
    PORT (
    in_tt, in_tf, in_ft, in_ff : IN STD_LOGIC_vector(BITS - 1 DOWNTO 0);
    in_sel_tt : IN STD_LOGIC;
    in_sel_tf : IN STD_LOGIC;
    in_sel_ft : IN STD_LOGIC;
    in_sel_ff : IN STD_LOGIC;
    out_mux : OUT STD_LOGIC_vector(BITS - 1 DOWNTO 0)
                        );
END quad_n_mux_selector;

ARCHITECTURE rtl of quad_n_mux_selector IS
    SIGNAL int_tt, int_tf, int_ft, int_ff : STD_LOGIC_vector(BITS - 1 DOWNTO 0);
BEGIN
    o : for i in BITS -1 downto 0 generate
    int_tt(i) <=  in_sel_tt AND in_tt(i);
    int_tf(i) <=  in_sel_tf AND in_tf(i);
    int_ft(i) <=  in_sel_ft AND in_ft(i);
    int_ff(i) <=  in_sel_ff AND in_ff(i);

    -- output
    out_mux(i) <=   int_tt(i) 
                OR  int_tf(i) 
                OR  int_ft(i) 
                OR  int_ff(i);
end generate;
END rtl;
