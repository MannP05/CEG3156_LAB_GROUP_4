--------------------------------------------------------------------------------
-- Title         : Right Shift Byte
-- Project       : Lab1
-------------------------------------------------------------------------------
-- File          : rshift_byte.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A right shift byte that shifts the bits of an 8-bit input
--               vector to the right when the in_rshift signal is asserted.
-------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.ALL;

-- shifts the output when in_rshift is set
ENTITY rshift_byte IS PORT (
    in_val : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    in_rshift : IN STD_LOGIC;
    out_val : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END rshift_byte;

architecture rtl of rshift_byte is
    SIGNAL int_val : STD_LOGIC_VECTOR(7 downto 0);
begin

    -- special case for first one
    int_val(7) <= (in_rshift AND in_val(0)) -- case to rshift
                  OR (NOT in_rshift AND in_val(7)); -- no shift, leave as is
    shifts: for i in 6 downto 0 generate
        int_val(i) <= (in_rshift AND in_val(i+1)) -- case to rshift
                      OR (NOT in_rshift AND in_val(i)); -- no shift, leave as is
    end generate shifts;

    out_val <= int_val;

end architecture rtl;
