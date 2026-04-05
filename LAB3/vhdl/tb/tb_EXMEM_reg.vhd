-- ============================================================
-- Testbench: tb_EXMEM_reg
-- Tests the EX/MEM pipeline register:
--   - Normal propagation of all fields
--   - Reset zeros everything
--   - Flush zeros control signals
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_EXMEM_reg is
end tb_EXMEM_reg;

architecture behavior of tb_EXMEM_reg is

    component EXMEM_reg
        port(
            i_clock        : in  std_logic;
            i_reset        : in  std_logic;
            i_flush        : in  std_logic;
            i_MemtoReg     : in  std_logic;
            i_RegWrite     : in  std_logic;
            i_MemRead      : in  std_logic;
            i_MemWrite     : in  std_logic;
            i_Branch       : in  std_logic;
            i_Jump         : in  std_logic;
            i_BranchTarget : in  std_logic_vector(7 downto 0);
            i_JumpAddr     : in  std_logic_vector(7 downto 0);
            i_Zero         : in  std_logic;
            i_ALUResult    : in  std_logic_vector(7 downto 0);
            i_ReadData2    : in  std_logic_vector(7 downto 0);
            i_WriteReg     : in  std_logic_vector(2 downto 0);
            o_MemtoReg     : out std_logic;
            o_RegWrite     : out std_logic;
            o_MemRead      : out std_logic;
            o_MemWrite     : out std_logic;
            o_Branch       : out std_logic;
            o_Jump         : out std_logic;
            o_BranchTarget : out std_logic_vector(7 downto 0);
            o_JumpAddr     : out std_logic_vector(7 downto 0);
            o_Zero         : out std_logic;
            o_ALUResult    : out std_logic_vector(7 downto 0);
            o_ReadData2    : out std_logic_vector(7 downto 0);
            o_WriteReg     : out std_logic_vector(2 downto 0)
        );
    end component;

    signal tb_clock        : std_logic := '0';
    signal tb_reset        : std_logic := '0';
    signal tb_flush        : std_logic := '0';

    signal tb_MemtoReg     : std_logic := '0';
    signal tb_RegWrite     : std_logic := '0';
    signal tb_MemRead      : std_logic := '0';
    signal tb_MemWrite     : std_logic := '0';
    signal tb_Branch       : std_logic := '0';
    signal tb_Jump         : std_logic := '0';
    signal tb_BranchTarget : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_JumpAddr     : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_Zero         : std_logic := '0';
    signal tb_ALUResult    : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_ReadData2    : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_WriteReg     : std_logic_vector(2 downto 0) := "000";

    signal tb_o_MemtoReg   : std_logic;
    signal tb_o_RegWrite   : std_logic;
    signal tb_o_MemRead    : std_logic;
    signal tb_o_MemWrite   : std_logic;
    signal tb_o_Branch     : std_logic;
    signal tb_o_Jump       : std_logic;
    signal tb_o_BranchTarget : std_logic_vector(7 downto 0);
    signal tb_o_JumpAddr   : std_logic_vector(7 downto 0);
    signal tb_o_Zero       : std_logic;
    signal tb_o_ALUResult  : std_logic_vector(7 downto 0);
    signal tb_o_ReadData2  : std_logic_vector(7 downto 0);
    signal tb_o_WriteReg   : std_logic_vector(2 downto 0);

    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

begin

    UUT : EXMEM_reg
        port map(
            i_clock => tb_clock, i_reset => tb_reset, i_flush => tb_flush,
            i_MemtoReg => tb_MemtoReg, i_RegWrite => tb_RegWrite,
            i_MemRead  => tb_MemRead,  i_MemWrite => tb_MemWrite,
            i_Branch   => tb_Branch,   i_Jump     => tb_Jump,
            i_BranchTarget => tb_BranchTarget, i_JumpAddr => tb_JumpAddr,
            i_Zero      => tb_Zero,    i_ALUResult => tb_ALUResult,
            i_ReadData2 => tb_ReadData2, i_WriteReg => tb_WriteReg,
            o_MemtoReg => tb_o_MemtoReg, o_RegWrite => tb_o_RegWrite,
            o_MemRead  => tb_o_MemRead,  o_MemWrite => tb_o_MemWrite,
            o_Branch   => tb_o_Branch,   o_Jump     => tb_o_Jump,
            o_BranchTarget => tb_o_BranchTarget, o_JumpAddr => tb_o_JumpAddr,
            o_Zero      => tb_o_Zero,    o_ALUResult => tb_o_ALUResult,
            o_ReadData2 => tb_o_ReadData2, o_WriteReg => tb_o_WriteReg
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
        -- Test 1: Reset
        -- -----------------------------------------------
        tb_reset        <= '1';
        tb_MemtoReg     <= '1'; tb_RegWrite  <= '1';
        tb_MemRead      <= '1'; tb_MemWrite  <= '1';
        tb_Branch       <= '1'; tb_Jump      <= '1';
        tb_BranchTarget <= x"40"; tb_JumpAddr <= x"2C";
        tb_Zero         <= '1'; tb_ALUResult <= x"FF";
        tb_ReadData2    <= x"AA"; tb_WriteReg <= "011";
        wait for clk_period;
        tb_reset <= '0';
        wait for 1 ns;
        assert (tb_o_RegWrite  = '0')
            report "TC1 FAIL: Reset should clear RegWrite" severity error;
        assert (tb_o_ALUResult = x"00")
            report "TC1 FAIL: Reset should clear ALUResult" severity error;
        assert (tb_o_WriteReg  = "000")
            report "TC1 FAIL: Reset should clear WriteReg" severity error;
        assert (tb_o_Zero      = '0')
            report "TC1 FAIL: Reset should clear Zero flag" severity error;
        wait for clk_period / 2;

        -- -----------------------------------------------
        -- Test 2: R-type add result
        -- ALU result = 0xFF, Zero='0', WriteReg=$1
        -- Controls: RegWrite=1, MemtoReg=0
        -- -----------------------------------------------
        tb_MemtoReg  <= '0'; tb_RegWrite  <= '1';
        tb_MemRead   <= '0'; tb_MemWrite  <= '0';
        tb_Branch    <= '0'; tb_Jump      <= '0';
        tb_Zero      <= '0'; tb_ALUResult <= x"FF";
        tb_ReadData2 <= x"AA"; tb_WriteReg <= "001";
        tb_BranchTarget <= x"00"; tb_JumpAddr <= x"00";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_RegWrite  = '1')
            report "TC2 FAIL: R-type RegWrite should propagate as 1" severity error;
        assert (tb_o_MemtoReg  = '0')
            report "TC2 FAIL: R-type MemtoReg should propagate as 0" severity error;
        assert (tb_o_ALUResult = x"FF")
            report "TC2 FAIL: ALUResult 0xFF not propagated" severity error;
        assert (tb_o_WriteReg  = "001")
            report "TC2 FAIL: WriteReg $1 not propagated" severity error;
        assert (tb_o_Zero      = '0')
            report "TC2 FAIL: Zero should be 0" severity error;

        -- -----------------------------------------------
        -- Test 3: Branch taken scenario
        -- beq: Branch=1, Zero=1, BranchTarget=0x10
        -- -----------------------------------------------
        tb_MemtoReg  <= '0'; tb_RegWrite  <= '0';
        tb_MemRead   <= '0'; tb_MemWrite  <= '0';
        tb_Branch    <= '1'; tb_Jump      <= '0';
        tb_Zero      <= '1'; tb_ALUResult <= x"00";
        tb_ReadData2 <= x"00"; tb_WriteReg <= "000";
        tb_BranchTarget <= x"10"; tb_JumpAddr <= x"00";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_Branch       = '1')
            report "TC3 FAIL: Branch should propagate as 1" severity error;
        assert (tb_o_Zero         = '1')
            report "TC3 FAIL: Zero should propagate as 1 for beq" severity error;
        assert (tb_o_BranchTarget = x"10")
            report "TC3 FAIL: BranchTarget 0x10 not propagated" severity error;

        -- -----------------------------------------------
        -- Test 4: lw - memory read
        -- Controls: MemRead=1, MemtoReg=1, RegWrite=1
        -- -----------------------------------------------
        tb_MemtoReg  <= '1'; tb_RegWrite  <= '1';
        tb_MemRead   <= '1'; tb_MemWrite  <= '0';
        tb_Branch    <= '0'; tb_Jump      <= '0';
        tb_Zero      <= '0'; tb_ALUResult <= x"00";  -- address
        tb_ReadData2 <= x"00"; tb_WriteReg <= "010";
        tb_BranchTarget <= x"00"; tb_JumpAddr <= x"00";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemRead  = '1')
            report "TC4 FAIL: lw MemRead should be 1" severity error;
        assert (tb_o_MemtoReg = '1')
            report "TC4 FAIL: lw MemtoReg should be 1" severity error;
        assert (tb_o_WriteReg = "010")
            report "TC4 FAIL: lw destination register not propagated" severity error;

        -- -----------------------------------------------
        -- Test 5: sw - memory write with store data
        -- -----------------------------------------------
        tb_MemtoReg  <= '0'; tb_RegWrite  <= '0';
        tb_MemRead   <= '0'; tb_MemWrite  <= '1';
        tb_Branch    <= '0'; tb_Jump      <= '0';
        tb_Zero      <= '0'; tb_ALUResult <= x"03";  -- address
        tb_ReadData2 <= x"FF";                         -- store data
        tb_WriteReg <= "000";
        tb_BranchTarget <= x"00"; tb_JumpAddr <= x"00";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemWrite  = '1')
            report "TC5 FAIL: sw MemWrite should be 1" severity error;
        assert (tb_o_ReadData2 = x"FF")
            report "TC5 FAIL: sw store data not propagated" severity error;
        assert (tb_o_ALUResult = x"03")
            report "TC5 FAIL: sw address not propagated" severity error;

        -- -----------------------------------------------
        -- Test 6: Jump instruction
        -- -----------------------------------------------
        tb_MemtoReg  <= '0'; tb_RegWrite  <= '0';
        tb_MemRead   <= '0'; tb_MemWrite  <= '0';
        tb_Branch    <= '0'; tb_Jump      <= '1';
        tb_Zero      <= '0'; tb_ALUResult <= x"00";
        tb_ReadData2 <= x"00"; tb_WriteReg <= "000";
        tb_BranchTarget <= x"00"; tb_JumpAddr <= x"2C";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_Jump    = '1')
            report "TC6 FAIL: Jump should propagate as 1" severity error;
        assert (tb_o_JumpAddr = x"2C")
            report "TC6 FAIL: JumpAddr not propagated" severity error;

        -- -----------------------------------------------
        -- Test 7: Flush zeros all control signals
        -- -----------------------------------------------
        tb_MemtoReg  <= '1'; tb_RegWrite  <= '1';
        tb_MemRead   <= '1'; tb_MemWrite  <= '1';
        tb_Branch    <= '1'; tb_Jump      <= '1';
        tb_flush     <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_RegWrite = '0')
            report "TC7 FAIL: Flush should clear RegWrite" severity error;
        assert (tb_o_MemWrite = '0')
            report "TC7 FAIL: Flush should clear MemWrite" severity error;
        assert (tb_o_Branch   = '0')
            report "TC7 FAIL: Flush should clear Branch" severity error;
        assert (tb_o_Jump     = '0')
            report "TC7 FAIL: Flush should clear Jump" severity error;
        tb_flush <= '0';

        report "tb_EXMEM_reg: All test cases completed!" severity note;
        sim_done <= true;
        wait;
    end process;

end behavior;