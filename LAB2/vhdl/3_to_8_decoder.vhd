LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY decoder_3to8 IS
    PORT(
        i_addr   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        i_enable : IN  STD_LOGIC;
        o_y      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END decoder_3to8;

ARCHITECTURE structural OF decoder_3to8 IS
    SIGNAL int_not_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
    int_not_addr <= NOT i_addr;

    o_y(0) <= i_enable AND int_not_addr(2) AND int_not_addr(1) AND int_not_addr(0);
    o_y(1) <= i_enable AND int_not_addr(2) AND int_not_addr(1) AND i_addr(0);
    o_y(2) <= i_enable AND int_not_addr(2) AND i_addr(1)       AND int_not_addr(0);
    o_y(3) <= i_enable AND int_not_addr(2) AND i_addr(1)       AND i_addr(0);
    o_y(4) <= i_enable AND i_addr(2)       AND int_not_addr(1) AND int_not_addr(0);
    o_y(5) <= i_enable AND i_addr(2)       AND int_not_addr(1) AND i_addr(0);
    o_y(6) <= i_enable AND i_addr(2)       AND i_addr(1)       AND int_not_addr(0);
    o_y(7) <= i_enable AND i_addr(2)       AND i_addr(1)       AND i_addr(0);
END structural;