LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ControlUnit_Mult IS
    PORT (
        clk           : IN  STD_LOGIC;
        reset         : IN  STD_LOGIC;
        multiplier_bit: IN  STD_LOGIC;
        load_inputs   : OUT STD_LOGIC;
        shift_enable  : OUT STD_LOGIC;
        add_enable    : OUT STD_LOGIC;
        done_flag     : OUT STD_LOGIC
    );
END ControlUnit_Mult;

ARCHITECTURE structural OF ControlUnit_Mult IS

    SIGNAL s_count, s_next_count : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_plus_one            : STD_LOGIC_VECTOR(3 DOWNTO 0);
    
    SIGNAL s_is_zero, s_is_ten   : STD_LOGIC;
    SIGNAL s_not_done            : STD_LOGIC;
    SIGNAL s_enable_shift        : STD_LOGIC;
    SIGNAL n_reset               : STD_LOGIC;
    
    COMPONENT bigALU
        GENERIC (BITS : INTEGER);
        PORT (i_Mantissa_A, i_Mantissa_B : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
              i_Op_Code : IN STD_LOGIC; o_Result : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
              o_CarryOut, o_Overflow, o_Zero : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT nbit_register
        GENERIC (BITS : INTEGER);
        PORT (in_val : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
              in_load, in_resetBar, in_clock : IN STD_LOGIC;
              out_val : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0));
    END COMPONENT;

    COMPONENT mux_2x1
        GENERIC (BITS : INTEGER);
        PORT (in_0, in_1 : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
              in_sel : IN STD_LOGIC; out_mux : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0));
    END COMPONENT;
    
BEGIN

    U_ADDER : bigALU GENERIC MAP(4)
    PORT MAP(i_Mantissa_A => s_count, i_Mantissa_B => "0001", i_Op_Code => '0', 
             o_Result => s_plus_one, o_CarryOut => open, o_Overflow => open, o_Zero => open);

    s_is_ten <= s_count(3) AND (NOT s_count(2)) AND s_count(1) AND (NOT s_count(0));
    s_not_done <= NOT s_is_ten;

    U_MUX_CNT : mux_2x1 GENERIC MAP(4)
    PORT MAP(in_0 => s_count, in_1 => s_plus_one, in_sel => s_not_done, out_mux => s_next_count);

    n_reset <= NOT reset;
    U_COUNTER : nbit_register GENERIC MAP(4)
    PORT MAP(in_val => s_next_count, in_load => '1', in_resetBar => n_reset, in_clock => clk, out_val => s_count);

    s_is_zero <= NOT(s_count(3) OR s_count(2) OR s_count(1) OR s_count(0));
    load_inputs <= s_is_zero;

    s_enable_shift <= (NOT s_is_zero) AND s_not_done;
    shift_enable <= s_enable_shift;

    add_enable <= s_enable_shift AND multiplier_bit;
    
    done_flag <= s_is_ten;

END structural;