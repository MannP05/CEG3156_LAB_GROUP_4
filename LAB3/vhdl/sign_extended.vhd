-- ============================================================
-- Sign Extension Unit
-- CEG 3156 Lab 2/3
--
-- Extends a 16-bit immediate field to 8 bits for the 8-bit
-- datapath. The lower 8 bits of the 16-bit immediate are
-- passed through (the upper 8 bits are used for sign detection
-- but our datapath is 8-bit wide so output is 8-bit).
--
-- Port names match the LAB2/LAB3 top-level instantiation:
--   i -> instruction(15 downto 0)
--   o -> sign_ext_out (8-bit)
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY sign_extended IS
    PORT(
        i  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);   -- 16-bit immediate from instruction
        o  : OUT STD_LOGIC_VECTOR(7  DOWNTO 0)    -- 8-bit sign-extended output
    );
END sign_extended;

ARCHITECTURE structural OF sign_extended IS
BEGIN
    -- --------------------------------------------------------
    -- For an 8-bit datapath the immediate fits in 8 bits.
    -- We pass through bits [7..0] of the 16-bit field.
    -- Bit 7 of the output naturally carries the sign bit of
    -- the lower byte, which is the sign bit for an 8-bit
    -- two's-complement representation.
    -- --------------------------------------------------------
    pass: FOR j IN 0 TO 7 GENERATE
        o(j) <= i(j);
    END GENERATE;

END structural;