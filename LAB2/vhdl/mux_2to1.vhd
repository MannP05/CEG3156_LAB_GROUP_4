LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux_2to1 IS
    PORT(
        i_a   : IN  STD_LOGIC;  -- selected when sel='0'
        i_b   : IN  STD_LOGIC;  -- selected when sel='1'
        i_sel : IN  STD_LOGIC;
        o_y   : OUT STD_LOGIC
    );
END mux_2to1;

ARCHITECTURE structural OF mux_2to1 IS
    SIGNAL int_not_sel : STD_LOGIC;
    SIGNAL int_and0    : STD_LOGIC;
    SIGNAL int_and1    : STD_LOGIC;
BEGIN
    int_not_sel <= NOT i_sel;
    int_and0    <= i_a AND int_not_sel;
    int_and1    <= i_b AND i_sel;
    o_y         <= int_and0 OR int_and1;
END structural;