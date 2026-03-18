library ieee;
use ieee.std_logic_1164.all;

entity sign_extended is
    port(
        i  : in  std_logic_vector(15 downto 0);
        o : out std_logic_vector(7 downto 0)
    );
end sign_extended;

architecture structural of sign_extended is
begin
    -- Just pass through the lower 8 bits
    pass: for j in 0 to 7 generate
        o(j) <= i(j);  -- sign extend
    end generate;
end structural;