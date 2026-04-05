LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.mux_package.ALL;

ENTITY register_file IS
    PORT(
        clock      : IN  STD_LOGIC;
        reset      : IN  STD_LOGIC;                     -- ADDED
        RegWrite   : IN  STD_LOGIC;
        read_reg1  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- 3-bit
        read_reg2  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- 3-bit
        write_reg  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);  -- 3-bit
        write_data : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- 8-bit
        read_data1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- 8-bit
        read_data2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)   -- 8-bit
    );
END register_file;

ARCHITECTURE structural OF register_file IS

    COMPONENT decoder_3to8
        PORT(
            i_addr   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            i_enable : IN  STD_LOGIC;
            o_y      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT reg_8
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mux_8to1_8bit
        PORT(
            i_inputs : IN  bus_array_8;
            i_sel    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_y      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL int_write_en : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL int_reg_out  : bus_array_8;

BEGIN

    -- WRITE DECODER
    write_dec: decoder_3to8 PORT MAP(
        i_addr   => write_reg,
        i_enable => RegWrite,
        o_y      => int_write_en
    );

    -- REGISTER 0: hardwired to zero
    int_reg_out(0) <= (OTHERS => '0');

    -- REGISTERS 1 through 7
    gen_regs: FOR i IN 1 TO 7 GENERATE
        reg_i: reg_8 PORT MAP(
            i_d     => write_data,
            i_load  => int_write_en(i),
            i_clock => clock,
            i_reset => reset,
            o_q     => int_reg_out(i)
        );
    END GENERATE;

    -- READ MUX 1
    read_mux1: mux_8to1_8bit PORT MAP(
        i_inputs => int_reg_out,
        i_sel    => read_reg1,
        o_y      => read_data1
    );

    -- READ MUX 2
    read_mux2: mux_8to1_8bit PORT MAP(
        i_inputs => int_reg_out,
        i_sel    => read_reg2,
        o_y      => read_data2
    );

END structural;