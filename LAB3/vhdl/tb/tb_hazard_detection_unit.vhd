-- ============================================================
-- Testbench: tb_hazard_detection_unit
-- Tests the load-use hazard detection:
--   - No hazard:  PCWrite=1, IFID_Write=1, ctrl_flush=0
--   - Hazard:     PCWrite=0, IFID_Write=0, ctrl_flush=1
--
-- Hazard condition:
--   IDEX_MemRead='1' AND
--   (IDEX_rt = IFID_rs OR IDEX_rt = IFID_rt)
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_hazard_detection_unit is
end tb_hazard_detection_unit;

architecture behavior of tb_hazard_detection_unit is

    component hazard_detection_unit
        port(
            IDEX_MemRead  : in  std_logic;
            IDEX_rt       : in  std_logic_vector(2 downto 0);
            IFID_rs       : in  std_logic_vector(2 downto 0);
            IFID_rt       : in  std_logic_vector(2 downto 0);
            PCWrite       : out std_logic;
            IFID_Write    : out std_logic;
            ctrl_flush    : out std_logic
        );
    end component;

    signal tb_IDEX_MemRead : std_logic := '0';
    signal tb_IDEX_rt      : std_logic_vector(2 downto 0) := "000";
    signal tb_IFID_rs      : std_logic_vector(2 downto 0) := "000";
    signal tb_IFID_rt      : std_logic_vector(2 downto 0) := "000";

    signal tb_PCWrite      : std_logic;
    signal tb_IFID_Write   : std_logic;
    signal tb_ctrl_flush   : std_logic;

begin

    UUT : hazard_detection_unit
        port map(
            IDEX_MemRead => tb_IDEX_MemRead,
            IDEX_rt      => tb_IDEX_rt,
            IFID_rs      => tb_IFID_rs,
            IFID_rt      => tb_IFID_rt,
            PCWrite      => tb_PCWrite,
            IFID_Write   => tb_IFID_Write,
            ctrl_flush   => tb_ctrl_flush
        );

    stim_proc : process
    begin
        -- -----------------------------------------------
        -- Test 1: No hazard - MemRead=0 (not a load)
        -- lw not in ID/EX, no stall needed
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '0';
        tb_IDEX_rt      <= "010";   -- $2
        tb_IFID_rs      <= "010";   -- same as rt, but MemRead=0
        tb_IFID_rt      <= "011";
        wait for 10 ns;
        assert (tb_PCWrite    = '1')
            report "TC1 FAIL: No hazard, PCWrite should be 1" severity error;
        assert (tb_IFID_Write = '1')
            report "TC1 FAIL: No hazard, IFID_Write should be 1" severity error;
        assert (tb_ctrl_flush = '0')
            report "TC1 FAIL: No hazard, ctrl_flush should be 0" severity error;

        -- -----------------------------------------------
        -- Test 2: Hazard - IDEX_rt matches IFID_rs
        -- lw $2, 0($0)   <- in ID/EX (MemRead=1, rt=$2)
        -- add $1, $2, $3 <- in IF/ID (rs=$2)
        -- -> Stall required
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '1';
        tb_IDEX_rt      <= "010";   -- $2 (lw destination)
        tb_IFID_rs      <= "010";   -- $2 (add source 1)
        tb_IFID_rt      <= "011";   -- $3
        wait for 10 ns;
        assert (tb_PCWrite    = '0')
            report "TC2 FAIL: Load-use hazard (rs match), PCWrite should be 0" severity error;
        assert (tb_IFID_Write = '0')
            report "TC2 FAIL: Load-use hazard (rs match), IFID_Write should be 0" severity error;
        assert (tb_ctrl_flush = '1')
            report "TC2 FAIL: Load-use hazard (rs match), ctrl_flush should be 1" severity error;

        -- -----------------------------------------------
        -- Test 3: Hazard - IDEX_rt matches IFID_rt
        -- lw $3, 1($0)   <- in ID/EX (MemRead=1, rt=$3)
        -- add $1, $2, $3 <- in IF/ID (rt=$3)
        -- -> Stall required
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '1';
        tb_IDEX_rt      <= "011";   -- $3
        tb_IFID_rs      <= "010";   -- $2 (no match)
        tb_IFID_rt      <= "011";   -- $3 (match)
        wait for 10 ns;
        assert (tb_PCWrite    = '0')
            report "TC3 FAIL: Load-use hazard (rt match), PCWrite should be 0" severity error;
        assert (tb_IFID_Write = '0')
            report "TC3 FAIL: Load-use hazard (rt match), IFID_Write should be 0" severity error;
        assert (tb_ctrl_flush = '1')
            report "TC3 FAIL: Load-use hazard (rt match), ctrl_flush should be 1" severity error;

        -- -----------------------------------------------
        -- Test 4: No hazard - IDEX_rt does not match
        -- lw $5, 0($0)   <- in ID/EX (rt=$5)
        -- add $1, $2, $3 <- in IF/ID (rs=$2, rt=$3)
        -- Different registers -> no stall
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '1';
        tb_IDEX_rt      <= "101";   -- $5 (lw destination)
        tb_IFID_rs      <= "010";   -- $2
        tb_IFID_rt      <= "011";   -- $3
        wait for 10 ns;
        assert (tb_PCWrite    = '1')
            report "TC4 FAIL: No match, PCWrite should be 1" severity error;
        assert (tb_IFID_Write = '1')
            report "TC4 FAIL: No match, IFID_Write should be 1" severity error;
        assert (tb_ctrl_flush = '0')
            report "TC4 FAIL: No match, ctrl_flush should be 0" severity error;

        -- -----------------------------------------------
        -- Test 5: No hazard - lw $0 (register 0 edge case)
        -- lw into $0 should still work logically
        -- (register 0 is hardwired to 0, but hazard unit
        --  is purely structural - it still detects the match)
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '1';
        tb_IDEX_rt      <= "000";   -- $0
        tb_IFID_rs      <= "000";   -- $0
        tb_IFID_rt      <= "001";
        wait for 10 ns;
        -- $0 match: hazard detected (structural unit does not
        -- know $0 is always 0; forwarding unit handles that)
        assert (tb_ctrl_flush = '1')
            report "TC5 NOTE: $0 match detected as hazard (expected structural behaviour)" severity note;

        -- -----------------------------------------------
        -- Test 6: Both rs and rt match (double match)
        -- lw $2, 0($0)   <- rt=$2
        -- beq $2, $2, X  <- rs=$2, rt=$2
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '1';
        tb_IDEX_rt      <= "010";
        tb_IFID_rs      <= "010";
        tb_IFID_rt      <= "010";
        wait for 10 ns;
        assert (tb_PCWrite    = '0')
            report "TC6 FAIL: Double match hazard, PCWrite should be 0" severity error;
        assert (tb_ctrl_flush = '1')
            report "TC6 FAIL: Double match hazard, ctrl_flush should be 1" severity error;

        -- -----------------------------------------------
        -- Test 7: MemRead=0, rt matches - still no hazard
        -- (sw does not create a load-use hazard)
        -- -----------------------------------------------
        tb_IDEX_MemRead <= '0';
        tb_IDEX_rt      <= "001";
        tb_IFID_rs      <= "001";
        tb_IFID_rt      <= "001";
        wait for 10 ns;
        assert (tb_PCWrite    = '1')
            report "TC7 FAIL: MemRead=0, no hazard regardless of register match" severity error;
        assert (tb_ctrl_flush = '0')
            report "TC7 FAIL: MemRead=0, ctrl_flush should be 0" severity error;

        report "tb_hazard_detection_unit: All test cases completed!" severity note;
        wait;
    end process;

end behavior;