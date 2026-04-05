-- ============================================================
-- Testbench: tb_IDEX_reg
-- Tests the ID/EX pipeline register:
--   - Normal operation (all fields propagate)
--   - Flush zeros all control signals (NOP bubble)
--   - Reset zeros everything
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;

entity tb_IDEX_reg is
end tb_IDEX_reg;

architecture behavior of tb_IDEX_reg is

    component IDEX_reg
        port(
            i_clock      : in  std_logic;
            i_reset      : in  std_logic;
            i_flush      : in  std_logic;
            i_RegDst     : in  std_logic;
            i_ALUSrc     : in  std_logic;
            i_MemtoReg   : in  std_logic;
            i_RegWrite   : in  std_logic;
            i_MemRead    : in  std_logic;
            i_MemWrite   : in  std_logic;
            i_Branch     : in  std_logic;
            i_Jump       : in  std_logic;
            i_ALUOp      : in  std_logic_vector(1 downto 0);
            i_PC4        : in  std_logic_vector(7 downto 0);
            i_ReadData1  : in  std_logic_vector(7 downto 0);
            i_ReadData2  : in  std_logic_vector(7 downto 0);
            i_SignExt    : in  std_logic_vector(7 downto 0);
            i_rs         : in  std_logic_vector(2 downto 0);
            i_rt         : in  std_logic_vector(2 downto 0);
            i_rd         : in  std_logic_vector(2 downto 0);
            i_funct      : in  std_logic_vector(5 downto 0);
            o_RegDst     : out std_logic;
            o_ALUSrc     : out std_logic;
            o_MemtoReg   : out std_logic;
            o_RegWrite   : out std_logic;
            o_MemRead    : out std_logic;
            o_MemWrite   : out std_logic;
            o_Branch     : out std_logic;
            o_Jump       : out std_logic;
            o_ALUOp      : out std_logic_vector(1 downto 0);
            o_PC4        : out std_logic_vector(7 downto 0);
            o_ReadData1  : out std_logic_vector(7 downto 0);
            o_ReadData2  : out std_logic_vector(7 downto 0);
            o_SignExt    : out std_logic_vector(7 downto 0);
            o_rs         : out std_logic_vector(2 downto 0);
            o_rt         : out std_logic_vector(2 downto 0);
            o_rd         : out std_logic_vector(2 downto 0);
            o_funct      : out std_logic_vector(5 downto 0)
        );
    end component;

    -- Clock / reset / flush
    signal tb_clock    : std_logic := '0';
    signal tb_reset    : std_logic := '0';
    signal tb_flush    : std_logic := '0';

    -- Control inputs
    signal tb_RegDst   : std_logic := '0';
    signal tb_ALUSrc   : std_logic := '0';
    signal tb_MemtoReg : std_logic := '0';
    signal tb_RegWrite : std_logic := '0';
    signal tb_MemRead  : std_logic := '0';
    signal tb_MemWrite : std_logic := '0';
    signal tb_Branch   : std_logic := '0';
    signal tb_Jump     : std_logic := '0';
    signal tb_ALUOp    : std_logic_vector(1 downto 0) := "00";

    -- Data inputs
    signal tb_PC4      : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_RD1      : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_RD2      : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_SE       : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_rs       : std_logic_vector(2 downto 0) := "000";
    signal tb_rt       : std_logic_vector(2 downto 0) := "000";
    signal tb_rd       : std_logic_vector(2 downto 0) := "000";
    signal tb_funct    : std_logic_vector(5 downto 0) := "000000";

    -- Control outputs
    signal tb_o_RegDst   : std_logic;
    signal tb_o_ALUSrc   : std_logic;
    signal tb_o_MemtoReg : std_logic;
    signal tb_o_RegWrite : std_logic;
    signal tb_o_MemRead  : std_logic;
    signal tb_o_MemWrite : std_logic;
    signal tb_o_Branch   : std_logic;
    signal tb_o_Jump     : std_logic;
    signal tb_o_ALUOp    : std_logic_vector(1 downto 0);

    -- Data outputs
    signal tb_o_PC4    : std_logic_vector(7 downto 0);
    signal tb_o_RD1    : std_logic_vector(7 downto 0);
    signal tb_o_RD2    : std_logic_vector(7 downto 0);
    signal tb_o_SE     : std_logic_vector(7 downto 0);
    signal tb_o_rs     : std_logic_vector(2 downto 0);
    signal tb_o_rt     : std_logic_vector(2 downto 0);
    signal tb_o_rd     : std_logic_vector(2 downto 0);
    signal tb_o_funct  : std_logic_vector(5 downto 0);

    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

begin

    UUT : IDEX_reg
        port map(
            i_clock => tb_clock, i_reset => tb_reset, i_flush => tb_flush,
            i_RegDst => tb_RegDst, i_ALUSrc => tb_ALUSrc,
            i_MemtoReg => tb_MemtoReg, i_RegWrite => tb_RegWrite,
            i_MemRead => tb_MemRead, i_MemWrite => tb_MemWrite,
            i_Branch => tb_Branch, i_Jump => tb_Jump,
            i_ALUOp => tb_ALUOp,
            i_PC4 => tb_PC4, i_ReadData1 => tb_RD1,
            i_ReadData2 => tb_RD2, i_SignExt => tb_SE,
            i_rs => tb_rs, i_rt => tb_rt,
            i_rd => tb_rd, i_funct => tb_funct,
            o_RegDst => tb_o_RegDst, o_ALUSrc => tb_o_ALUSrc,
            o_MemtoReg => tb_o_MemtoReg, o_RegWrite => tb_o_RegWrite,
            o_MemRead => tb_o_MemRead, o_MemWrite => tb_o_MemWrite,
            o_Branch => tb_o_Branch, o_Jump => tb_o_Jump,
            o_ALUOp => tb_o_ALUOp,
            o_PC4 => tb_o_PC4, o_ReadData1 => tb_o_RD1,
            o_ReadData2 => tb_o_RD2, o_SignExt => tb_o_SE,
            o_rs => tb_o_rs, o_rt => tb_o_rt,
            o_rd => tb_o_rd, o_funct => tb_o_funct
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
        -- Test 1: Reset zeros all outputs
        -- -----------------------------------------------
        tb_reset   <= '1';
        tb_RegDst  <= '1'; tb_ALUSrc  <= '1'; tb_MemtoReg <= '1';
        tb_RegWrite <= '1'; tb_MemRead <= '1'; tb_MemWrite <= '1';
        tb_Branch  <= '1'; tb_Jump    <= '1'; tb_ALUOp   <= "11";
        tb_PC4     <= x"FF"; tb_RD1 <= x"AA"; tb_RD2 <= x"BB";
        tb_SE      <= x"CC"; tb_rs  <= "111"; tb_rt  <= "110";
        tb_rd      <= "101"; tb_funct <= "111111";
        wait for clk_period;
        tb_reset <= '0';
        wait for 1 ns;
        assert (tb_o_RegWrite = '0')
            report "TC1 FAIL: Reset should clear RegWrite" severity error;
        assert (tb_o_MemRead = '0')
            report "TC1 FAIL: Reset should clear MemRead" severity error;
        assert (tb_o_PC4 = x"00")
            report "TC1 FAIL: Reset should clear PC4" severity error;
        assert (tb_o_funct = "000000")
            report "TC1 FAIL: Reset should clear funct" severity error;
        wait for clk_period / 2;

        -- -----------------------------------------------
        -- Test 2: R-type instruction (add $1,$2,$3)
        -- Controls: RegDst=1, RegWrite=1, ALUOp="10"
        -- -----------------------------------------------
        tb_RegDst   <= '1'; tb_ALUSrc   <= '0';
        tb_MemtoReg <= '0'; tb_RegWrite <= '1';
        tb_MemRead  <= '0'; tb_MemWrite <= '0';
        tb_Branch   <= '0'; tb_Jump     <= '0';
        tb_ALUOp    <= "10";
        tb_PC4      <= x"0C";
        tb_RD1      <= x"55"; tb_RD2  <= x"AA";
        tb_SE       <= x"00";
        tb_rs       <= "010"; tb_rt   <= "011";
        tb_rd       <= "001"; tb_funct <= "100000";  -- ADD funct
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_RegDst   = '1')
            report "TC2 FAIL: R-type RegDst should be 1" severity error;
        assert (tb_o_RegWrite = '1')
            report "TC2 FAIL: R-type RegWrite should be 1" severity error;
        assert (tb_o_ALUOp    = "10")
            report "TC2 FAIL: R-type ALUOp should be 10" severity error;
        assert (tb_o_RD1      = x"55")
            report "TC2 FAIL: ReadData1 not propagated" severity error;
        assert (tb_o_RD2      = x"AA")
            report "TC2 FAIL: ReadData2 not propagated" severity error;
        assert (tb_o_rs       = "010")
            report "TC2 FAIL: rs not propagated" severity error;
        assert (tb_o_rd       = "001")
            report "TC2 FAIL: rd not propagated" severity error;
        assert (tb_o_funct    = "100000")
            report "TC2 FAIL: funct not propagated" severity error;

        -- -----------------------------------------------
        -- Test 3: lw instruction
        -- Controls: ALUSrc=1, MemtoReg=1, RegWrite=1, MemRead=1, ALUOp="00"
        -- -----------------------------------------------
        tb_RegDst   <= '0'; tb_ALUSrc   <= '1';
        tb_MemtoReg <= '1'; tb_RegWrite <= '1';
        tb_MemRead  <= '1'; tb_MemWrite <= '0';
        tb_Branch   <= '0'; tb_Jump     <= '0';
        tb_ALUOp    <= "00";
        tb_PC4      <= x"08";
        tb_RD1      <= x"00"; tb_RD2  <= x"00";
        tb_SE       <= x"01";   -- immediate = 1
        tb_rs       <= "000"; tb_rt   <= "010";
        tb_rd       <= "000"; tb_funct <= "000000";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_ALUSrc   = '1')
            report "TC3 FAIL: lw ALUSrc should be 1" severity error;
        assert (tb_o_MemtoReg = '1')
            report "TC3 FAIL: lw MemtoReg should be 1" severity error;
        assert (tb_o_MemRead  = '1')
            report "TC3 FAIL: lw MemRead should be 1" severity error;
        assert (tb_o_ALUOp    = "00")
            report "TC3 FAIL: lw ALUOp should be 00" severity error;
        assert (tb_o_SE       = x"01")
            report "TC3 FAIL: sign-extended immediate not propagated" severity error;

        -- -----------------------------------------------
        -- Test 4: Flush inserts NOP bubble
        -- -----------------------------------------------
        tb_RegDst   <= '1'; tb_ALUSrc   <= '1';
        tb_MemtoReg <= '1'; tb_RegWrite <= '1';
        tb_MemRead  <= '1'; tb_MemWrite <= '1';
        tb_Branch   <= '1'; tb_Jump     <= '1';
        tb_ALUOp    <= "11";
        tb_flush    <= '1';
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_RegWrite = '0')
            report "TC4 FAIL: Flush should clear RegWrite" severity error;
        assert (tb_o_MemRead  = '0')
            report "TC4 FAIL: Flush should clear MemRead" severity error;
        assert (tb_o_MemWrite = '0')
            report "TC4 FAIL: Flush should clear MemWrite" severity error;
        assert (tb_o_Branch   = '0')
            report "TC4 FAIL: Flush should clear Branch" severity error;
        tb_flush <= '0';

        -- -----------------------------------------------
        -- Test 5: sw instruction
        -- Controls: ALUSrc=1, MemWrite=1, ALUOp="00"
        -- -----------------------------------------------
        tb_RegDst   <= '0'; tb_ALUSrc   <= '1';
        tb_MemtoReg <= '0'; tb_RegWrite <= '0';
        tb_MemRead  <= '0'; tb_MemWrite <= '1';
        tb_Branch   <= '0'; tb_Jump     <= '0';
        tb_ALUOp    <= "00";
        tb_PC4      <= x"14";
        tb_RD1      <= x"00"; tb_RD2  <= x"FF";
        tb_SE       <= x"03";
        tb_rs       <= "000"; tb_rt   <= "001";
        tb_rd       <= "000"; tb_funct <= "000000";
        wait for clk_period;
        wait for 1 ns;
        assert (tb_o_MemWrite = '1')
            report "TC5 FAIL: sw MemWrite should be 1" severity error;
        assert (tb_o_RegWrite = '0')
            report "TC5 FAIL: sw RegWrite should be 0" severity error;
        assert (tb_o_RD2      = x"FF")
            report "TC5 FAIL: sw ReadData2 (store value) not propagated" severity error;

        report "tb_IDEX_reg: All test cases completed!" severity note;
        sim_done <= true;
        wait;
    end process;

end behavior;