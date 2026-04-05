-- ============================================================
-- Testbench: tb_reg_32
-- Tests the 32-bit pipeline data register
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_reg_32 is
end tb_reg_32;

architecture behavior of tb_reg_32 is

    component reg_32
        port(
            i_d     : in  std_logic_vector(31 downto 0);
            i_load  : in  std_logic;
            i_clock : in  std_logic;
            i_reset : in  std_logic;
            o_q     : out std_logic_vector(31 downto 0)
        );
    end component;

    signal tb_d     : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_load  : std_logic := '0';
    signal tb_clock : std_logic := '0';
    signal tb_reset : std_logic := '0';
    signal tb_q     : std_logic_vector(31 downto 0);

    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

begin

    UUT : reg_32
        port map(
            i_d     => tb_d,
            i_load  => tb_load,
            i_clock => tb_clock,
            i_reset => tb_reset,
            o_q     => tb_q
        );

    clk_proc : process
    begin
        if sim_done then wait; end if;
        tb_clock <= '0'; wait for clk_period / 2;
        tb_clock <= '1'; wait for clk_period / 2;
    end process;

    stim_proc : process
    begin
        -- -----------------------------------------------
        -- Test 1: Reset clears to zero
        -- -----------------------------------------------
        tb_reset <= '1';
        tb_d     <= x"DEADBEEF";
        tb_load  <= '1';
        wait for clk_period;
        tb_reset <= '0';
        wait for 1 ns;
        assert (tb_q = x"00000000")
            report "TC1 FAIL: Reset should clear register to 0x00000000" severity error;
        wait for clk_period / 2;

        -- -----------------------------------------------
        -- Test 2: Load a 32-bit instruction word
        -- -----------------------------------------------
        tb_d    <= x"8C020000";   -- lw $2, 0($0)
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"8C020000")
            report "TC2 FAIL: Load lw instruction incorrect" severity error;

        -- -----------------------------------------------
        -- Test 3: Hold (load=0) keeps previous value
        -- -----------------------------------------------
        tb_d    <= x"00430820";   -- add $1,$2,$3 (different)
        tb_load <= '0';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"8C020000")
            report "TC3 FAIL: Hold should keep 0x8C020000" severity error;

        -- -----------------------------------------------
        -- Test 4: Load new value after hold
        -- -----------------------------------------------
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"00430820")
            report "TC4 FAIL: Load after hold incorrect" severity error;

        -- -----------------------------------------------
        -- Test 5: All ones
        -- -----------------------------------------------
        tb_d    <= x"FFFFFFFF";
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"FFFFFFFF")
            report "TC5 FAIL: All-ones load incorrect" severity error;

        -- -----------------------------------------------
        -- Test 6: All zeros explicit load
        -- -----------------------------------------------
        tb_d    <= x"00000000";
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"00000000")
            report "TC6 FAIL: All-zeros load incorrect" severity error;

        -- -----------------------------------------------
        -- Test 7: Alternating bit pattern
        -- -----------------------------------------------
        tb_d    <= x"AAAA5555";
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"AAAA5555")
            report "TC7 FAIL: Alternating pattern 0xAAAA5555 incorrect" severity error;

        -- -----------------------------------------------
        -- Test 8: Reverse alternating
        -- -----------------------------------------------
        tb_d    <= x"5555AAAA";
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"5555AAAA")
            report "TC8 FAIL: Reverse alternating 0x5555AAAA incorrect" severity error;

        -- -----------------------------------------------
        -- Test 9: Typical sw instruction word
        -- -----------------------------------------------
        tb_d    <= x"AC010003";
        tb_load <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"AC010003")
            report "TC9 FAIL: sw instruction 0xAC010003 incorrect" severity error;

        -- -----------------------------------------------
        -- Test 10: Reset mid-operation
        -- -----------------------------------------------
        tb_d     <= x"12345678";
        tb_load  <= '1';
        tb_reset <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_q = x"00000000")
            report "TC10 FAIL: Reset mid-operation should clear to zero" severity error;
        tb_reset <= '0';

        report "tb_reg_32: All test cases completed!" severity note;
        sim_done <= true;
        wait;
    end process;

end behavior;