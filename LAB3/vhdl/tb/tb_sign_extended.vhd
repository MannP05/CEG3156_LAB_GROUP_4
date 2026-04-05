-- ============================================================
-- Testbench: tb_sign_extended
-- CEG 3156 Lab 2/3
--
-- Tests the sign_extended unit with correct port names (i, o)
-- and correct bit widths (16-bit in, 8-bit out).
--
-- For an 8-bit datapath the sign-extended output is the lower
-- 8 bits of the 16-bit immediate field. Bit 7 of the output
-- is the sign bit.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_sign_extended is
end tb_sign_extended;

architecture behavior of tb_sign_extended is

    -- --------------------------------------------------------
    -- Component declaration matches the fixed sign_extended
    -- --------------------------------------------------------
    component sign_extended
        port(
            i  : in  std_logic_vector(15 downto 0);
            o  : out std_logic_vector(7  downto 0)
        );
    end component;

    -- Testbench signals
    signal tb_i : std_logic_vector(15 downto 0) := (others => '0');
    signal tb_o : std_logic_vector(7  downto 0);

begin

    -- --------------------------------------------------------
    -- Unit Under Test
    -- --------------------------------------------------------
    UUT : sign_extended
        port map(
            i => tb_i,
            o => tb_o
        );

    -- --------------------------------------------------------
    -- Stimulus process
    -- --------------------------------------------------------
    stim_proc : process
    begin

        -- ----------------------------------------------------
        -- Test Case 1: Small positive immediate (+10)
        -- i = 0x000A -> lower 8 bits = 0x0A = 00001010
        -- Expected o = 0x0A (positive, bit 7 = 0)
        -- ----------------------------------------------------
        tb_i <= "0000000000001010";   -- +10
        wait for 10 ns;
        assert (tb_o = "00001010")
            report "TC1 FAIL: +10 -> expected 0x0A (00001010)" severity error;

        -- ----------------------------------------------------
        -- Test Case 2: Negative immediate (-10 in lower byte)
        -- i = 0x00F6 -> lower 8 bits = 0xF6 = 11110110
        -- Expected o = 0xF6 (negative in 8-bit two's complement)
        -- ----------------------------------------------------
        tb_i <= "0000000011110110";   -- lower 8 bits = 0xF6 = -10
        wait for 10 ns;
        assert (tb_o = "11110110")
            report "TC2 FAIL: -10 (8-bit) -> expected 0xF6 (11110110)" severity error;

        -- ----------------------------------------------------
        -- Test Case 3: Zero immediate
        -- i = 0x0000 -> o = 0x00
        -- ----------------------------------------------------
        tb_i <= "0000000000000000";   -- 0
        wait for 10 ns;
        assert (tb_o = "00000000")
            report "TC3 FAIL: 0 -> expected 0x00 (00000000)" severity error;

        -- ----------------------------------------------------
        -- Test Case 4: Maximum positive 8-bit value (+127)
        -- Lower 8 bits = 0x7F = 01111111
        -- Expected o = 0x7F
        -- ----------------------------------------------------
        tb_i <= "0000000001111111";   -- lower 8 bits = +127
        wait for 10 ns;
        assert (tb_o = "01111111")
            report "TC4 FAIL: +127 -> expected 0x7F (01111111)" severity error;

        -- ----------------------------------------------------
        -- Test Case 5: Minimum negative 8-bit value (-128)
        -- Lower 8 bits = 0x80 = 10000000
        -- Expected o = 0x80 (most negative 8-bit value)
        -- ----------------------------------------------------
        tb_i <= "0000000010000000";   -- lower 8 bits = -128
        wait for 10 ns;
        assert (tb_o = "10000000")
            report "TC5 FAIL: -128 -> expected 0x80 (10000000)" severity error;

        -- ----------------------------------------------------
        -- Test Case 6: Alternating lower bits (0x55 = 01010101)
        -- Upper bits of i are non-zero but should be ignored
        -- Expected o = 0x55
        -- ----------------------------------------------------
        tb_i <= "1111111101010101";   -- upper bits 1, lower = 0x55
        wait for 10 ns;
        assert (tb_o = "01010101")
            report "TC6 FAIL: 0x55 lower byte -> expected 01010101" severity error;

        -- ----------------------------------------------------
        -- Test Case 7: Alternating lower bits (0xAA = 10101010)
        -- Expected o = 0xAA (negative in 8-bit two's complement)
        -- ----------------------------------------------------
        tb_i <= "0000000010101010";   -- lower 8 bits = 0xAA
        wait for 10 ns;
        assert (tb_o = "10101010")
            report "TC7 FAIL: 0xAA lower byte -> expected 10101010" severity error;

        -- ----------------------------------------------------
        -- Test Case 8: LW offset +1 (common in benchmark)
        -- i = 0x0001 -> o = 0x01
        -- Used in: lw $3, 1($0)
        -- ----------------------------------------------------
        tb_i <= "0000000000000001";   -- offset = +1
        wait for 10 ns;
        assert (tb_o = "00000001")
            report "TC8 FAIL: offset +1 -> expected 0x01 (00000001)" severity error;

        -- ----------------------------------------------------
        -- Test Case 9: SW offset +3 (common in benchmark)
        -- i = 0x0003 -> o = 0x03
        -- Used in: sw $1, 3($0)
        -- ----------------------------------------------------
        tb_i <= "0000000000000011";   -- offset = +3
        wait for 10 ns;
        assert (tb_o = "00000011")
            report "TC9 FAIL: offset +3 -> expected 0x03 (00000011)" severity error;

        -- ----------------------------------------------------
        -- Test Case 10: Branch offset -1 (0xFFFF -> lower = 0xFF)
        -- Used to verify negative branch offsets pass correctly
        -- Expected o = 0xFF = -1 in 8-bit two's complement
        -- ----------------------------------------------------
        tb_i <= "1111111111111111";   -- all ones
        wait for 10 ns;
        assert (tb_o = "11111111")
            report "TC10 FAIL: 0xFFFF lower byte -> expected 0xFF (11111111)" severity error;

        -- ----------------------------------------------------
        -- Test Case 11: Only upper byte set, lower byte zero
        -- Upper byte of i is ignored (only lower 8 bits passed)
        -- Expected o = 0x00
        -- ----------------------------------------------------
        tb_i <= "1111111100000000";   -- upper = 0xFF, lower = 0x00
        wait for 10 ns;
        assert (tb_o = "00000000")
            report "TC11 FAIL: Upper byte set, lower zero -> expected 0x00" severity error;

        -- ----------------------------------------------------
        -- Test Case 12: Branch offset +4 (jump forward 1 word)
        -- i = 0x0004 -> o = 0x04
        -- ----------------------------------------------------
        tb_i <= "0000000000000100";   -- offset = +4
        wait for 10 ns;
        assert (tb_o = "00000100")
            report "TC12 FAIL: offset +4 -> expected 0x04 (00000100)" severity error;

        -- All tests completed
        report "tb_sign_extended: All test cases completed!" severity note;

        wait;
    end process;

end behavior;