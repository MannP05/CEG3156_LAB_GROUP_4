-- ============================================================
-- Testbench: tb_forwarding_unit
-- Tests EX/MEM and MEM/WB forwarding logic
--
-- ForwardA / ForwardB:
--   "00" -> no forwarding (use register file)
--   "01" -> forward from MEM/WB
--   "10" -> forward from EX/MEM
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_forwarding_unit is
end tb_forwarding_unit;

architecture behavior of tb_forwarding_unit is

    component forwarding_unit
        port(
            IDEX_rs        : in  std_logic_vector(2 downto 0);
            IDEX_rt        : in  std_logic_vector(2 downto 0);
            EXMEM_RegWrite : in  std_logic;
            EXMEM_rd       : in  std_logic_vector(2 downto 0);
            MEMWB_RegWrite : in  std_logic;
            MEMWB_rd       : in  std_logic_vector(2 downto 0);
            ForwardA       : out std_logic_vector(1 downto 0);
            ForwardB       : out std_logic_vector(1 downto 0)
        );
    end component;

    signal tb_IDEX_rs        : std_logic_vector(2 downto 0) := "000";
    signal tb_IDEX_rt        : std_logic_vector(2 downto 0) := "000";
    signal tb_EXMEM_RegWrite : std_logic := '0';
    signal tb_EXMEM_rd       : std_logic_vector(2 downto 0) := "000";
    signal tb_MEMWB_RegWrite : std_logic := '0';
    signal tb_MEMWB_rd       : std_logic_vector(2 downto 0) := "000";
    signal tb_ForwardA       : std_logic_vector(1 downto 0);
    signal tb_ForwardB       : std_logic_vector(1 downto 0);

begin

    UUT : forwarding_unit
        port map(
            IDEX_rs        => tb_IDEX_rs,
            IDEX_rt        => tb_IDEX_rt,
            EXMEM_RegWrite => tb_EXMEM_RegWrite,
            EXMEM_rd       => tb_EXMEM_rd,
            MEMWB_RegWrite => tb_MEMWB_RegWrite,
            MEMWB_rd       => tb_MEMWB_rd,
            ForwardA       => tb_ForwardA,
            ForwardB       => tb_ForwardB
        );

    stim_proc : process
    begin
        -- -----------------------------------------------
        -- Test 1: No forwarding needed
        -- No register write in EX/MEM or MEM/WB
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";  -- $1
        tb_IDEX_rt        <= "010";  -- $2
        tb_EXMEM_RegWrite <= '0';
        tb_EXMEM_rd       <= "001";
        tb_MEMWB_RegWrite <= '0';
        tb_MEMWB_rd       <= "001";
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC1 FAIL: No write, ForwardA should be 00" severity error;
        assert (tb_ForwardB = "00")
            report "TC1 FAIL: No write, ForwardB should be 00" severity error;

        -- -----------------------------------------------
        -- Test 2: EX/MEM forward to A (rs match)
        -- add $3, $1, $2  <- EX stage (IDEX_rs=$1)
        -- add $4, $3, $5  <- was just here, rd=$3 in EX/MEM
        -- -> ForwardA = "10"
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";  -- $1 (current EX stage rs)
        tb_IDEX_rt        <= "010";  -- $2
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "001";  -- $1 (EX/MEM writing $1)
        tb_MEMWB_RegWrite <= '0';
        tb_MEMWB_rd       <= "000";
        wait for 10 ns;
        assert (tb_ForwardA = "10")
            report "TC2 FAIL: EX/MEM forward to A, ForwardA should be 10" severity error;
        assert (tb_ForwardB = "00")
            report "TC2 FAIL: No B hazard, ForwardB should be 00" severity error;

        -- -----------------------------------------------
        -- Test 3: EX/MEM forward to B (rt match)
        -- sub $1, $2, $3  <- EX stage (IDEX_rt=$3)
        -- add $3, $4, $5  <- was EX/MEM, rd=$3
        -- -> ForwardB = "10"
        -- -----------------------------------------------
        tb_IDEX_rs        <= "010";  -- $2
        tb_IDEX_rt        <= "011";  -- $3
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "011";  -- $3
        tb_MEMWB_RegWrite <= '0';
        tb_MEMWB_rd       <= "000";
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC3 FAIL: No A hazard, ForwardA should be 00" severity error;
        assert (tb_ForwardB = "10")
            report "TC3 FAIL: EX/MEM forward to B, ForwardB should be 10" severity error;

        -- -----------------------------------------------
        -- Test 4: MEM/WB forward to A (rs match, no EX/MEM hazard)
        -- add $5, $1, $2  <- EX stage (rs=$1)
        -- add $1, $3, $4  <- MEM/WB, rd=$1
        -- No instruction in EX/MEM writing $1
        -- -> ForwardA = "01"
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";  -- $1
        tb_IDEX_rt        <= "010";  -- $2
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "100";  -- $4 (different register)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "001";  -- $1
        wait for 10 ns;
        assert (tb_ForwardA = "01")
            report "TC4 FAIL: MEM/WB forward to A, ForwardA should be 01" severity error;
        assert (tb_ForwardB = "00")
            report "TC4 FAIL: No B hazard, ForwardB should be 00" severity error;

        -- -----------------------------------------------
        -- Test 5: MEM/WB forward to B (rt match, no EX/MEM hazard)
        -- -----------------------------------------------
        tb_IDEX_rs        <= "010";  -- $2
        tb_IDEX_rt        <= "001";  -- $1
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "100";  -- $4 (no match)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "001";  -- $1
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC5 FAIL: No A hazard, ForwardA should be 00" severity error;
        assert (tb_ForwardB = "01")
            report "TC5 FAIL: MEM/WB forward to B, ForwardB should be 01" severity error;

        -- -----------------------------------------------
        -- Test 6: EX/MEM takes priority over MEM/WB
        -- Both stages writing same register ($1)
        -- EX/MEM result is more recent -> ForwardA="10"
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";  -- $1
        tb_IDEX_rt        <= "010";  -- $2
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "001";  -- $1 (EX/MEM writing)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "001";  -- $1 (MEM/WB also writing)
        wait for 10 ns;
        assert (tb_ForwardA = "10")
            report "TC6 FAIL: EX/MEM must take priority, ForwardA should be 10" severity error;

        -- -----------------------------------------------
        -- Test 7: No forwarding to $0 (always-zero register)
        -- Writing to $0 should NOT trigger forwarding
        -- -----------------------------------------------
        tb_IDEX_rs        <= "000";  -- $0
        tb_IDEX_rt        <= "000";  -- $0
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "000";  -- writing to $0 (invalid)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "000";  -- writing to $0 (invalid)
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC7 FAIL: No forward to $0, ForwardA should be 00" severity error;
        assert (tb_ForwardB = "00")
            report "TC7 FAIL: No forward to $0, ForwardB should be 00" severity error;

        -- -----------------------------------------------
        -- Test 8: Forward both A and B simultaneously (different sources)
        -- add $1, $2, $3
        -- EX/MEM writing $2, MEM/WB writing $3
        -- -> ForwardA="10" (EX/MEM), ForwardB="01" (MEM/WB)
        -- -----------------------------------------------
        tb_IDEX_rs        <= "010";  -- $2
        tb_IDEX_rt        <= "011";  -- $3
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "010";  -- $2 (matches rs)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "011";  -- $3 (matches rt)
        wait for 10 ns;
        assert (tb_ForwardA = "10")
            report "TC8 FAIL: ForwardA should be 10 (EX/MEM->rs)" severity error;
        assert (tb_ForwardB = "01")
            report "TC8 FAIL: ForwardB should be 01 (MEM/WB->rt)" severity error;

        -- -----------------------------------------------
        -- Test 9: RegWrite=0 in EX/MEM, match exists
        -- -> Should NOT forward (disabled write)
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";
        tb_IDEX_rt        <= "010";
        tb_EXMEM_RegWrite <= '0';    -- write disabled
        tb_EXMEM_rd       <= "001";  -- same register but write=0
        tb_MEMWB_RegWrite <= '0';
        tb_MEMWB_rd       <= "001";
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC9 FAIL: RegWrite=0, should not forward, ForwardA should be 00" severity error;

        -- -----------------------------------------------
        -- Test 10: All registers different - no forwarding
        -- -----------------------------------------------
        tb_IDEX_rs        <= "001";  -- $1
        tb_IDEX_rt        <= "010";  -- $2
        tb_EXMEM_RegWrite <= '1';
        tb_EXMEM_rd       <= "011";  -- $3 (no match)
        tb_MEMWB_RegWrite <= '1';
        tb_MEMWB_rd       <= "100";  -- $4 (no match)
        wait for 10 ns;
        assert (tb_ForwardA = "00")
            report "TC10 FAIL: All different, ForwardA should be 00" severity error;
        assert (tb_ForwardB = "00")
            report "TC10 FAIL: All different, ForwardB should be 00" severity error;

        report "tb_forwarding_unit: All test cases completed!" severity note;
        wait;
    end process;

end behavior;