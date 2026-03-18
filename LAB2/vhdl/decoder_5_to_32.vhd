--------------------------------------------------------------------------------
-- Title         : 5-to-32 Decoder
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : decoder_5to32.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A structural 5-to-32 line decoder with an active-high enable. 
--               It takes a 5-bit address input and asserts exactly one of the 
--               32 output lines corresponding to the address value, provided 
--               the enable signal is high.
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY decoder_5to32 IS
    PORT(
        i_addr   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        i_enable : IN  STD_LOGIC;
        o_y      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END decoder_5to32;

ARCHITECTURE structural OF decoder_5to32 IS
    SIGNAL n : STD_LOGIC_VECTOR(4 DOWNTO 0);
BEGIN
    n(0) <= NOT i_addr(0);
    n(1) <= NOT i_addr(1);
    n(2) <= NOT i_addr(2);
    n(3) <= NOT i_addr(3);
    n(4) <= NOT i_addr(4);

    o_y(0)  <= i_enable AND n(4) AND n(3) AND n(2) AND n(1) AND n(0);
    o_y(1)  <= i_enable AND n(4) AND n(3) AND n(2) AND n(1) AND i_addr(0);
    o_y(2)  <= i_enable AND n(4) AND n(3) AND n(2) AND i_addr(1) AND n(0);
    o_y(3)  <= i_enable AND n(4) AND n(3) AND n(2) AND i_addr(1) AND i_addr(0);
    o_y(4)  <= i_enable AND n(4) AND n(3) AND i_addr(2) AND n(1) AND n(0);
    o_y(5)  <= i_enable AND n(4) AND n(3) AND i_addr(2) AND n(1) AND i_addr(0);
    o_y(6)  <= i_enable AND n(4) AND n(3) AND i_addr(2) AND i_addr(1) AND n(0);
    o_y(7)  <= i_enable AND n(4) AND n(3) AND i_addr(2) AND i_addr(1) AND i_addr(0);
    o_y(8)  <= i_enable AND n(4) AND i_addr(3) AND n(2) AND n(1) AND n(0);
    o_y(9)  <= i_enable AND n(4) AND i_addr(3) AND n(2) AND n(1) AND i_addr(0);
    o_y(10) <= i_enable AND n(4) AND i_addr(3) AND n(2) AND i_addr(1) AND n(0);
    o_y(11) <= i_enable AND n(4) AND i_addr(3) AND n(2) AND i_addr(1) AND i_addr(0);
    o_y(12) <= i_enable AND n(4) AND i_addr(3) AND i_addr(2) AND n(1) AND n(0);
    o_y(13) <= i_enable AND n(4) AND i_addr(3) AND i_addr(2) AND n(1) AND i_addr(0);
    o_y(14) <= i_enable AND n(4) AND i_addr(3) AND i_addr(2) AND i_addr(1) AND n(0);
    o_y(15) <= i_enable AND n(4) AND i_addr(3) AND i_addr(2) AND i_addr(1) AND i_addr(0);
    o_y(16) <= i_enable AND i_addr(4) AND n(3) AND n(2) AND n(1) AND n(0);
    o_y(17) <= i_enable AND i_addr(4) AND n(3) AND n(2) AND n(1) AND i_addr(0);
    o_y(18) <= i_enable AND i_addr(4) AND n(3) AND n(2) AND i_addr(1) AND n(0);
    o_y(19) <= i_enable AND i_addr(4) AND n(3) AND n(2) AND i_addr(1) AND i_addr(0);
    o_y(20) <= i_enable AND i_addr(4) AND n(3) AND i_addr(2) AND n(1) AND n(0);
    o_y(21) <= i_enable AND i_addr(4) AND n(3) AND i_addr(2) AND n(1) AND i_addr(0);
    o_y(22) <= i_enable AND i_addr(4) AND n(3) AND i_addr(2) AND i_addr(1) AND n(0);
    o_y(23) <= i_enable AND i_addr(4) AND n(3) AND i_addr(2) AND i_addr(1) AND i_addr(0);
    o_y(24) <= i_enable AND i_addr(4) AND i_addr(3) AND n(2) AND n(1) AND n(0);
    o_y(25) <= i_enable AND i_addr(4) AND i_addr(3) AND n(2) AND n(1) AND i_addr(0);
    o_y(26) <= i_enable AND i_addr(4) AND i_addr(3) AND n(2) AND i_addr(1) AND n(0);
    o_y(27) <= i_enable AND i_addr(4) AND i_addr(3) AND n(2) AND i_addr(1) AND i_addr(0);
    o_y(28) <= i_enable AND i_addr(4) AND i_addr(3) AND i_addr(2) AND n(1) AND n(0);
    o_y(29) <= i_enable AND i_addr(4) AND i_addr(3) AND i_addr(2) AND n(1) AND i_addr(0);
    o_y(30) <= i_enable AND i_addr(4) AND i_addr(3) AND i_addr(2) AND i_addr(1) AND n(0);
    o_y(31) <= i_enable AND i_addr(4) AND i_addr(3) AND i_addr(2) AND i_addr(1) AND i_addr(0);
END structural;