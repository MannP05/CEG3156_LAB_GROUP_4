library ieee;
use ieee.std_logic_1164.all;
entity sign_extended_sim is
    port(
        input : in std_logic_vector(15 downto 0);
        output : out std_logic_vector(31 downto 0)
    );
end sign_extended_sim;
architecture Behavioral of sign_extended_sim is
    component sign_extended
        port(
            input : in std_logic_vector(15 downto 0);
            output : out std_logic_vector(31 downto 0)
        );
    end component;

    signal input_signal : std_logic_vector(15 downto 0);
    signal output_signal : std_logic_vector(31 downto 0);
begin
    test: sign_extended
        port map(
            input => input_signal,
            output => output_signal
        );
    process
    begin
        -- Test case 1: Positive number
        input_signal <= "0000000000001010"; -- 10 in decimal
        wait for 10 ns;

        -- Test case 2: Negative number
        input_signal <= "1111111111110110"; -- -10 in decimal
        wait for 10 ns;

        -- Test case 3: Zero
        input_signal <= "0000000000000000"; -- 0 in decimal
        wait for 10 ns;

        -- Test case 4: Maximum positive number
        input_signal <= "0111111111111111"; -- 32767 in decimal
        wait for 10 ns;

        -- Test case 5: Minimum negative number
        input_signal <= "1000000000000000"; -- -32768 in decimal
        wait for 10 ns;

        -- Test case 6: Random value
        input_signal <= "1010101010101010"; -- -21846 in decimal
        wait for 10 ns;

        wait;
    end process;
end Behavioral;

