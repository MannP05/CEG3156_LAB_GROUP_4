-- ============================================================
-- Testbench: tb_MEMWB_reg
-- Tests the MEM/WB pipeline register:
--   - Normal propagation (WB control signals + data)
--   - Reset clears all fields
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_MEMWB_reg is
end tb_MEMWB_reg;

architecture behavior of tb_MEMWB_reg is

    component MEMWB_reg
        port(
            i_clock       : in  std_logic;
            i_reset       : in  std_logic;
            i_MemtoReg    : in  std_logic;
            i_RegWrite    : in  std_logic;
            i_MemReadData : in  std_logic_vector(7 downto 0);
            i_ALUResult   : in  std_logic_vector(7 downto 0);
            i_WriteReg    : in  std_logic_vector(2 downto 0);
            o_MemtoReg    : out std_logic;
            o_RegWrite    : out std_logic;
            o_MemReadData : out std_logic_vector(7 downto 0);
            o_ALUResult   : out std_logic_vector(7 downto 0);
            o_WriteReg    : out std_logic_vector(2 downto 0)
        );
    end component;

    signal tb_clock       : std_logic := '0';
    signal tb_reset       : std_logic := '0';
    signal tb_MemtoReg    : std_logic := '0';
    signal tb_RegWrite    : std_logic := '0';
    signal tb_MemReadData : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_ALUResult   : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_WriteReg    : std_logic_vector(2 downto 0) := "000";

    signal tb_o_MemtoReg    : std_logic;
    signal tb_o_RegWrite    : std_logic;
    signal tb_o_MemReadData : std_logic_vector(7 downto 0);
    signal tb_o_ALUResult   : std_logic_vector(7 downto 0);
    signal tb_o_WriteReg    : std_logic_vector(2 downto 0);

    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

begin

    UUT : MEMWB_reg
        port map(
            i_clock       => tb_clock,
            i_reset       => tb_reset,
            i_MemtoReg    => tb_MemtoReg,
            i_RegWrite    => tb_RegWrite,
            i_MemReadData => tb_MemReadData,
            i_ALUResult   => tb_ALUResult,
            i_WriteReg    => tb_WriteReg,
            o_MemtoReg    => tb_o_MemtoReg,
            o_RegWrite    => tb_o_RegWrite,
            o_MemReadData => tb_o_MemReadData,
            o_ALUResult   => tb_o_ALUResult,
            o_WriteReg    => tb_o_WriteReg
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
        -- Test 1: Reset clears everything
        -- -----------------------------------------------
        tb_reset       <= '1';
        tb_MemtoReg    <= '1';
        tb_RegWrite    <= '1';
        tb_MemReadData <= x"55";
        tb_ALUResult   <= x"FF";
        tb_WriteReg    <= "111";
        wait for clk_period;
        tb_reset <= '0';
        wait for 1 ns;
        assert (tb_o_RegWrite    = '0')
            report "TC1 FAIL: Reset should clear RegWrite" severity error;
        assert (tb_o_MemtoReg    = '0')
            report "TC1 FAIL: Reset should clear MemtoReg" severity error;
        assert (tb_o_MemReadData = x"00")
            report "TC1 FAIL: Reset should clear MemReadData" severity error;
        assert (tb_o_ALUResult   = x"00")
            report "TC1 FAIL: Reset should clear ALUResult" severity error;
        assert (tb_o_WriteReg    = "000")
            report "TC1 FAIL: Reset should clear WriteReg" severity error;
        wait for clk_period / 2;

        -- -----------------------------------------------
        -- Test 2: lw write back
        -- MemtoReg=1 selects memory data, RegWrite=1
        -- -----------------------------------------------
        tb_MemtoReg    <= '1';
        tb_RegWrite    <= '1';
        tb_MemReadData <= x"55";   -- data from memory
        tb_ALUResult   <= x"00";   -- address (not selected)
        tb_WriteReg    <= "010";   -- $2
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemtoReg    = '1')
            report "TC2 FAIL: lw MemtoReg should be 1" severity error;
        assert (tb_o_RegWrite    = '1')
            report "TC2 FAIL: lw RegWrite should be 1" severity error;
        assert (tb_o_MemReadData = x"55")
            report "TC2 FAIL: Memory read data 0x55 not propagated" severity error;
        assert (tb_o_WriteReg    = "010")
            report "TC2 FAIL: lw destination $2 not propagated" severity error;

        -- -----------------------------------------------
        -- Test 3: R-type write back
        -- MemtoReg=0 selects ALU result, RegWrite=1
        -- -----------------------------------------------
        tb_MemtoReg    <= '0';
        tb_RegWrite    <= '1';
        tb_MemReadData <= x"00";
        tb_ALUResult   <= x"FF";   -- add $2,$3 result
        tb_WriteReg    <= "001";   -- $1
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemtoReg  = '0')
            report "TC3 FAIL: R-type MemtoReg should be 0" severity error;
        assert (tb_o_ALUResult = x"FF")
            report "TC3 FAIL: R-type ALU result 0xFF not propagated" severity error;
        assert (tb_o_WriteReg  = "001")
            report "TC3 FAIL: R-type destination $1 not propagated" severity error;

        -- -----------------------------------------------
        -- Test 4: sw / no write back (RegWrite=0)
        -- -----------------------------------------------
        tb_MemtoReg    <= '0';
        tb_RegWrite    <= '0';
        tb_MemReadData <= x"AA";
        tb_ALUResult   <= x"03";
        tb_WriteReg    <= "000";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_RegWrite = '0')
            report "TC4 FAIL: sw RegWrite should be 0 (no write)" severity error;

        -- -----------------------------------------------
        -- Test 5: Back-to-back lw results
        -- Verify no mixing between consecutive instructions
        -- -----------------------------------------------
        -- Cycle 1: lw $2, data=0xAA
        tb_MemtoReg    <= '1'; tb_RegWrite    <= '1';
        tb_MemReadData <= x"AA"; tb_ALUResult <= x"01";
        tb_WriteReg    <= "010";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemReadData = x"AA" and tb_o_WriteReg = "010")
            report "TC5a FAIL: First lw result incorrect" severity error;

        -- Cycle 2: lw $3, data=0xBB
        tb_MemReadData <= x"BB"; tb_ALUResult <= x"02";
        tb_WriteReg    <= "011";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemReadData = x"BB" and tb_o_WriteReg = "011")
            report "TC5b FAIL: Second lw result incorrect (pipeline mixing)" severity error;

        -- -----------------------------------------------
        -- Test 6: WriteReg all values
        -- -----------------------------------------------
        tb_MemtoReg <= '0'; tb_RegWrite <= '1';
        tb_ALUResult <= x"01"; tb_MemReadData <= x"00";
        tb_WriteReg  <= "101";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_WriteReg = "101")
            report "TC6 FAIL: WriteReg $5 not propagated" severity error;

        tb_WriteReg  <= "111";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_WriteReg = "111")
            report "TC6 FAIL: WriteReg $7 not propagated" severity error;

        report "tb_MEMWB_reg: All test cases completed!" severity note;
        sim_done <= true;
        wait;
    end process;

end behavior;