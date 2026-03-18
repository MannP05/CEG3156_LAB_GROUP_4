--------------------------------------------------------------------------------
-- Title         : N-bit Mux2to1
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : nBitMux2to1.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A parameterized structural n-bit 2-to-1 multiplexer. It uses an 
-- array of one-bit 2-to-1 multiplexers to select between two n-bit input vectors 
-- (i_d0 and i_d1) based on the select signal (i_sel) and outputs the selected n-bit 
--vector (o_q).
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nBitMux2to1 IS
    GENERIC(n : INTEGER := 4);
    PORT(
        i_sel       : IN  STD_LOGIC;
        i_d0, i_d1  : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        o_q         : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
    );
END nBitMux2to1;

ARCHITECTURE structural OF nBitMux2to1 IS
    COMPONENT oneBitMux2to1 IS
        PORT(
            s, x0, x1 : IN  STD_LOGIC;
            y         : OUT STD_LOGIC
        );
    END COMPONENT;
BEGIN
    gen_mux: FOR i IN 0 TO n-1 GENERATE
        mux_i: oneBitMux2to1 PORT MAP(
            s  => i_sel,
            x0 => i_d0(i),
            x1 => i_d1(i),
            y  => o_q(i)
        );
    END GENERATE;
END structural;