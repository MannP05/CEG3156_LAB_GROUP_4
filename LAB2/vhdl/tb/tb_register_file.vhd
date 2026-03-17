library ieee;
use ieee.std_logic_1164.all;

entity tb_register_file is
end tb_register_file;

architecture behavior of tb_register_file is

    component register_file
        port(
            clock      : in  std_logic;
            reset      : in  std_logic;
            RegWrite   : in  std_logic;
            read_reg1  : in  std_logic_vector(2 downto 0);
            read_reg2  : in  std_logic_vector(2 downto 0);
            write_reg  : in  std_logic_vector(2 downto 0);
            write_data : in  std_logic_vector(7 downto 0);
            read_data1 : out std_logic_vector(7 downto 0);
            read_data2 : out std_logic_vector(7 downto 0)
        );
    end component;

    signal tb_clock      : std_logic := '0';
    signal tb_reset      : std_logic := '0';
    signal tb_RegWrite   : std_logic := '0';
    signal tb_read_reg1  : std_logic_vector(2 downto 0) := (others => '0');
    signal tb_read_reg2  : std_logic_vector(2 downto 0) := (others => '0');
    signal tb_write_reg  : std_logic_vector(2 downto 0) := (others => '0');
    signal tb_write_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_read_data1 : std_logic_vector(7 downto 0);
    signal tb_read_data2 : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;

    signal sim_done : boolean := false;

begin

    reg_file: register_file port map (
        clock      => tb_clock,
        reset      => tb_reset,
        RegWrite   => tb_RegWrite,
        read_reg1  => tb_read_reg1,
        read_reg2  => tb_read_reg2,
        write_reg  => tb_write_reg,
        write_data => tb_write_data,
        read_data1 => tb_read_data1,
        read_data2 => tb_read_data2
    );

    clk_proc: process
    begin
        if sim_done then
            wait;
        end if;
        tb_clock <= '0';
        wait for clk_period / 2;
        tb_clock <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
    begin
        -- Reset
        tb_reset <= '1';
        wait for clk_period;
        tb_reset <= '0';
        wait for clk_period;

        -- Write 0xAB to $0 (should stay 0x00, hardwired)
        tb_write_reg  <= "000";
        tb_write_data <= x"AB";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "000";
        wait for clk_period;

        -- Write 0x55 to $1
        tb_write_reg  <= "001";
        tb_write_data <= x"55";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "001";
        wait for clk_period;

        -- Write 0xAA to $7
        tb_write_reg  <= "111";
        tb_write_data <= x"AA";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "111";
        wait for clk_period;

        -- Write 0x11 to $2, then 0x22 to $3, read both
        tb_write_reg  <= "010";
        tb_write_data <= x"11";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_write_reg  <= "011";
        tb_write_data <= x"22";
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "010";
        tb_read_reg2  <= "011";
        wait for clk_period;

        -- Write disabled: try writing 0xFF to $4
        tb_write_reg  <= "100";
        tb_write_data <= x"FF";
        tb_RegWrite   <= '0';
        wait for clk_period;
        tb_read_reg1  <= "100";
        wait for clk_period;

        -- Write 0xCC to $5, verify $1 unchanged
        tb_write_reg  <= "101";
        tb_write_data <= x"CC";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "101";
        tb_read_reg2  <= "001";
        wait for clk_period;

        -- Overwrite $1 with 0x77
        tb_write_reg  <= "001";
        tb_write_data <= x"77";
        tb_RegWrite   <= '1';
        wait for clk_period;
        tb_RegWrite   <= '0';
        tb_read_reg1  <= "001";
        wait for clk_period;

        -- Verify $0 still zero
        tb_read_reg1  <= "000";
        tb_read_reg2  <= "000";
        wait for clk_period;

        -- Reset and verify cleared
        tb_reset <= '1';
        wait for clk_period;
        tb_reset <= '0';
        tb_read_reg1  <= "001";
        tb_read_reg2  <= "111";
        wait for clk_period;

        sim_done <= true;
        wait;
    end process;

end behavior;