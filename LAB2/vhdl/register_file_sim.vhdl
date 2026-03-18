library ieee;
use ieee.std_logic_1164.all;

entity register_file_sim is
end register_file_sim;

architecture behavior of register_file_sim is

    component register_file
        port(
            i_clock      : in  std_logic;
            i_RegWrite   : in  std_logic;
            i_read_reg1  : in  std_logic_vector(4 downto 0);
            i_read_reg2  : in  std_logic_vector(4 downto 0);
            i_write_reg  : in  std_logic_vector(4 downto 0);
            i_write_data : in  std_logic_vector(31 downto 0);
            o_read_data1 : out std_logic_vector(31 downto 0);
            o_read_data2 : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Testbench signals
    signal tb_clock      : std_logic := '0';
    signal tb_RegWrite   : std_logic := '0';
    signal tb_read_reg1  : std_logic_vector(4 downto 0) := (others => '0');
    signal tb_read_reg2  : std_logic_vector(4 downto 0) := (others => '0');
    signal tb_write_reg  : std_logic_vector(4 downto 0) := (others => '0');
    signal tb_write_data : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_read_data1 : std_logic_vector(31 downto 0);
    signal tb_read_data2 : std_logic_vector(31 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

begin

    reg_file: register_file port map (
        i_clock      => tb_clock,
        i_RegWrite   => tb_RegWrite,
        i_read_reg1  => tb_read_reg1,
        i_read_reg2  => tb_read_reg2,
        i_write_reg  => tb_write_reg,
        i_write_data => tb_write_data,
        o_read_data1 => tb_read_data1,
        o_read_data2 => tb_read_data2
    );

    -- Clock generation process
    clk_proc: process
    begin
        tb_clock <= '0';
        wait for clk_period / 2;
        tb_clock <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Initialize
        wait for clk_period;

        -- Test 1: Write to register $0 (should remain zero - hardwired)
        tb_write_reg  <= "00000";  -- $0
        tb_write_data <= x"DEADBEEF";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "00000";  -- Read $0
        wait for clk_period;
        -- Expected: o_read_data1 = 0x00000000

        -- Test 2: Write to register $1
        tb_write_reg  <= "00001";  -- $1
        tb_write_data <= x"12345678";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "00001";  -- Read $1
        wait for clk_period;
        -- Expected: o_read_data1 = 0x12345678

        -- Test 3: Write to register $31
        tb_write_reg  <= "11111";  -- $31
        tb_write_data <= x"ABCDEF01";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "11111";  -- Read $31
        wait for clk_period;
        -- Expected: o_read_data1 = 0xABCDEF01

        -- Test 4: Read two registers simultaneously
        tb_write_reg  <= "00010";  -- $2
        tb_write_data <= x"11111111";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_write_reg  <= "00011";  -- $3
        tb_write_data <= x"22222222";
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "00010";  -- Read $2
        tb_read_reg2  <= "00011";  -- Read $3
        wait for clk_period;
        -- Expected: o_read_data1 = 0x11111111, o_read_data2 = 0x22222222

        -- Test 5: Write disabled (RegWrite = 0)
        tb_write_reg  <= "00100";  -- $4
        tb_write_data <= x"FFFFFFFF";
        tb_RegWrite   <= '0';  -- Write disabled
        wait for clk_period;
        tb_read_reg1  <= "00100";  -- Read $4
        wait for clk_period;
        -- Expected: o_read_data1 should NOT be 0xFFFFFFFF

        -- Test 6: Write to register $15 (middle register)
        tb_write_reg  <= "01111";  -- $15
        tb_write_data <= x"55555555";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "01111";  -- Read $15
        tb_read_reg2  <= "00001";  -- Read $1 (should still be 0x12345678)
        wait for clk_period;
        -- Expected: o_read_data1 = 0x55555555, o_read_data2 = 0x12345678

        -- Test 7: Verify $0 is still zero
        tb_read_reg1  <= "00000";
        tb_read_reg2  <= "00000";
        wait for clk_period;
        -- Expected: both outputs = 0x00000000

        wait;
    end process;

end behavior;