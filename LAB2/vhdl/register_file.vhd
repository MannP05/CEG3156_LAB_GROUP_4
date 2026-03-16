LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.mux_package.ALL;

ENTITY register_file IS
    PORT(
        i_clock      : IN  STD_LOGIC;
        i_RegWrite   : IN  STD_LOGIC;
        i_read_reg1  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        i_read_reg2  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        i_write_reg  : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
        i_write_data : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        o_read_data1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        o_read_data2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END register_file;

ARCHITECTURE structural OF register_file IS

    COMPONENT decoder_5to32
        PORT(
            i_addr   : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
            i_enable : IN  STD_LOGIC;
            o_y      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT reg_32
        PORT(
            i_d     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            i_load  : IN  STD_LOGIC;
            i_clock : IN  STD_LOGIC;
            o_q     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mux_32_to_1
        PORT(
            i_inputs : IN  bus_array_32;
            i_sel    : IN  STD_LOGIC_VECTOR(4 DOWNTO 0);
            o_y      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL int_write_en : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL int_reg_out  : bus_array_32;

BEGIN

    -- WRITE DECODER
    write_dec: decoder_5to32 PORT MAP(
        i_addr   => i_write_reg,
        i_enable => i_RegWrite,
        o_y      => int_write_en
    );

    -- REGISTER 0: hardwired to zero
    int_reg_out(0) <= (OTHERS => '0');

    -- REGISTERS 1-31
    gen_regs: FOR i IN 1 TO 31 GENERATE
        reg_i: reg_32 PORT MAP(
            i_d     => i_write_data,
            i_load  => int_write_en(i),
            i_clock => i_clock,
            o_q     => int_reg_out(i)
        );
    END GENERATE;

    -- READ MUX 1
    read_mux1: mux_32_to_1 PORT MAP(
        i_inputs => int_reg_out,
        i_sel    => i_read_reg1,
        o_y      => o_read_data1
    );

    -- READ MUX 2
    read_mux2: mux_32_to_1 PORT MAP(
        i_inputs => int_reg_out,
        i_sel    => i_read_reg2,
        o_y      => o_read_data2
    );

END structural;