LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY ControlUnit IS
    PORT (
        clk          : IN  STD_LOGIC;
        reset        : IN  STD_LOGIC;
        exp_diff     : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        shift_enable : OUT STD_LOGIC
    );
END ControlUnit;

ARCHITECTURE structural OF ControlUnit IS

    SIGNAL s_current_count  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_next_val       : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_decremented    : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_mux_load_out   : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_mux_stop_out   : STD_LOGIC_VECTOR(6 DOWNTO 0);
    
    SIGNAL s_is_not_zero    : STD_LOGIC;
    
    SIGNAL s_or_lvl1_a, s_or_lvl1_b, s_or_lvl1_c : STD_LOGIC;
    SIGNAL s_or_lvl2_a, s_or_lvl2_b : STD_LOGIC;
    
    SIGNAL s_one_vec        : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_zero_vec       : STD_LOGIC_VECTOR(6 DOWNTO 0);

    COMPONENT nbit_register
        GENERIC ( BITS : integer );
        PORT (
            in_val      : IN STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
            in_load     : IN STD_LOGIC;
            in_resetBar : IN STD_LOGIC;
            in_clock    : IN STD_LOGIC;
            out_val     : OUT STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT ripple_adder
        GENERIC ( BITS : integer );
        PORT (
             A, B     : in std_logic_vector(BITS - 1 downto 0); 
             Cin      : in std_logic; 
             sum      : out std_logic_vector(BITS - 1 downto 0);
             Cout, Zero, Overflow : out std_logic;
             add_sub  : in std_logic
         );
    END COMPONENT;

    COMPONENT mux_2x1
        GENERIC ( BITS : integer );
        PORT (
            in_0    : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            in_1    : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            in_sel  : IN STD_LOGIC;
            out_mux : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    s_one_vec  <= "0000001";
    s_zero_vec <= "0000000";

    U_REG: nbit_register
    GENERIC MAP ( BITS => 7 )
    PORT MAP (
        in_val      => s_mux_load_out,
        in_load     => '1',
        in_resetBar => '1',
        in_clock    => clk,
        out_val     => s_current_count
    );

    s_or_lvl1_a <= s_current_count(0) OR s_current_count(1);
    s_or_lvl1_b <= s_current_count(2) OR s_current_count(3);
    s_or_lvl1_c <= s_current_count(4) OR s_current_count(5);
    
    s_or_lvl2_a <= s_or_lvl1_a OR s_or_lvl1_b;
    s_or_lvl2_b <= s_or_lvl1_c OR s_current_count(6);
    
    s_is_not_zero <= s_or_lvl2_a OR s_or_lvl2_b;

    shift_enable <= s_is_not_zero;

    U_DEC: ripple_adder
    GENERIC MAP ( BITS => 7 )
    PORT MAP (
        A        => s_current_count,
        B        => s_one_vec,
        Cin      => '0',
        add_sub  => '1',
        sum      => s_decremented,
        Cout     => open, Zero => open, Overflow => open
    );

    U_MUX_STOP: mux_2x1
    GENERIC MAP ( BITS => 7 )
    PORT MAP (
        in_0    => s_zero_vec,
        in_1    => s_decremented,
        in_sel  => s_is_not_zero,
        out_mux => s_mux_stop_out
    );

    U_MUX_LOAD: mux_2x1
    GENERIC MAP ( BITS => 7 )
    PORT MAP (
        in_0    => exp_diff,
        in_1    => s_mux_stop_out,
        in_sel  => reset,
        out_mux => s_mux_load_out
    );

END structural;