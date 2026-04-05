-- ============================================================
-- Testbench: tb_IFID_reg
-- Tests the IF/ID pipeline register with flush and stall
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_IFID_reg is
end tb_IFID_reg;

architecture behavior of tb_IFID_reg is

    component IFID_reg
        port(
            i_clock       : in  std_logic;
            i_reset       : in  std_logic;
            i_flush       : in  std_logic;
            i_stall       : in  std_logic;
            i_PC4         : in  std_logic_vector(7 downto 0);
            i_instruction : in  std_logic_vector(31 downto 0);
            o_PC4         : out std_logic_vector(7 downto 0);
            o_instruction : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Clock and control signals
    signal tb_clock       : std_logic := '0';
    signal tb_reset       : std_logic := '0';
    signal tb_flush       : std_logic := '0';
    signal tb_stall       : std_logic := '0';

    -- Data signals
    signal tb_PC4         : std_logic_vector(7 downto 0)  := (others => '0');
    signal tb_instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_o_PC4       : std_logic_vector(7 downto 0);
    signal tb_o_instr     : std_logic_vector(31 downto 0);

    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

begin

    UUT : IFID_reg
        port map(
            i_clock       => tb_clock,
            i_reset       => tb_reset,
            i_flush       => tb_flush,
            i_stall       => tb_stall,
            i_PC4         => tb_PC4,
            i_instruction => tb_instruction,
            o_PC4         => tb_o_PC4,
            o_instruction => tb_o_instr
        );

    -- Clock generation
    clk_proc : process
    begin
        if sim_done then
            wait;
        end if;
        tb_clock <= '0';
        wait for clk_period / 2;
        tb_clock <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc : process
    begin
        -- ------------------------------------------------
        -- Test 1: Reset clears both fields
        -- ------------------------------------------------
        tb_reset      <= '1';
        tb_PC4        <= x"08";
        tb_instruction <= x"DEADBEEF";
        wait for clk_period;
        tb_reset <= '0';
        wait for clk_period / 2;  -- sample after clock edge settles
        assert (tb_o_PC4   = x"00")
            report "TC1 FAIL: Reset should clear PC4 to 0x00" severity error;
        assert (tb_o_instr = x"00000000")
            report "TC1 FAIL: Reset should clear instruction to 0x00000000" severity error;
        wait for clk_period / 2;

        -- ------------------------------------------------
        -- Test 2: Normal load (no flush, no stall)
        -- ------------------------------------------------
        tb_PC4        <= x"04";
        tb_instruction <= x"8C020000";   -- lw $2, 0
        tb_flush      <= '0';
        tb_stall      <= '0';
        wait for clk_period;
        wait for 1 ns;  -- small delta after edge
        assert (tb_o_PC4   = x"04")
            report "TC2 FAIL: Normal load of PC4 incorrect" severity error;
        assert (tb_o_instr = x"8C020000")
            report "TC2 FAIL: Normal load of instruction incorrect" severity error;

        -- ------------------------------------------------
        -- Test 3: Stall holds previous values
        -- ------------------------------------------------
        tb_PC4        <= x"08";          -- new value
        tb_instruction <= x"8C030001";   -- lw $3, 1 (new instruction)
        tb_stall      <= '1';            -- stall = hold
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_PC4   = x"04")
            report "TC3 FAIL: Stall should hold PC4 at 0x04" severity error;
        assert (tb_o_instr = x"8C020000")
            report "TC3 FAIL: Stall should hold instruction at lw $2,0" severity error;
        tb_stall <= '0';

        -- ------------------------------------------------
        -- Test 4: Flush inserts NOP (zeros)
        -- ------------------------------------------------
        tb_PC4        <= x"0C";
        tb_instruction <= x"00430820";   -- add $1,$2,$3
        tb_flush      <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_PC4   = x"00")
            report "TC4 FAIL: Flush should zero PC4" severity error;
        assert (tb_o_instr = x"00000000")
            report "TC4 FAIL: Flush should zero instruction (NOP)" severity error;
        tb_flush <= '0';

        -- ------------------------------------------------
        -- Test 5: After flush, normal load resumes
        -- ------------------------------------------------
        tb_PC4        <= x"10";
        tb_instruction <= x"AC010003";   -- sw $1, 3
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_PC4   = x"10")
            report "TC5 FAIL: After flush, normal load of PC4 incorrect" severity error;
        assert (tb_o_instr = x"AC010003")
            report "TC5 FAIL: After flush, normal load of instruction incorrect" severity error;

        -- ------------------------------------------------
        -- Test 6: Stall then flush priority (flush wins)
        -- ------------------------------------------------
        tb_PC4        <= x"14";
        tb_instruction <= x"10220000";   -- beq
        tb_stall      <= '1';
        tb_flush      <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_instr = x"00000000")
            report "TC6 FAIL: Flush must take priority over stall" severity error;
        tb_stall <= '0';
        tb_flush <= '0';

        report "tb_IFID_reg: All test cases completed!" severity note;
        sim_done <= true;
        wait;
    end process;

end behavior;