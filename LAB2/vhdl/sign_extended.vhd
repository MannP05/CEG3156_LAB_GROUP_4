library ieee;
use ieee.std_logic_1164.all;

entity sign_extended is
    port(
        input : in std_logic_vector(15 downto 0);
        output : out std_logic_vector(31 downto 0)
    );
end sign_extended;

architecture structural of sign_extended is
begin
    -- original 16 bits: passvthrough the bits from input
    original: for i in 0 to 15 generate
        output(i) <= input(i);
    end generate;

    -- Upper 16 bits: repeat the sign bit 
    upper: for i in 16 to 31 generate
        output(i) <= input(15);
    end generate;
end structural;