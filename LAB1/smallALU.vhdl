library IEEE;
use IEEE.std_logic_1164.all;

-- used for 7-bit exponent subtraction and comparison to find exponent difference and swap flag

entity smallALU is 
    port(
        Exp_A : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        Exp_B : IN STD_LOGIC_VECTOR(6 DOWNTO 0);

        Exp_Difference : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        Swap_Flag : OUT STD_LOGIC
    );
end smallALU;

architecture structural of smallALU is
    
    component ripple_adder
        generic ( BITS : integer := 4 );
        port (
             A, B     : in std_logic_vector(BITS - 1 downto 0); 
             Cin      : in std_logic; 
             sum      : out std_logic_vector(BITS - 1 downto 0);
             Cout     : out std_logic;
             Zero     : out std_logic;
             Overflow : out std_logic;
             add_sub  : in std_logic 
         );
    end component;

    component quad_n_mux_selector 
        generic ( BITS : integer := 4 );
        PORT (
            in_tt, in_tf, in_ft, in_ff : IN STD_LOGIC_vector(BITS - 1 DOWNTO 0);
            in_sel_tt, in_sel_tf, in_sel_ft, in_sel_ff : IN STD_LOGIC;
            out_mux : OUT STD_LOGIC_vector(BITS - 1 DOWNTO 0)
        );
    end component;

    signal s_diff_AB : std_logic_vector(6 downto 0); -- ( A - B)
    signal s_diff_BA : std_logic_vector(6 downto 0); -- ( B - A)     
    signal s_swap    : std_logic; 
    signal not_swap  : std_logic;

    -- Unused signals to satify vhdl not using random stuff idk it just works
    signal open_c, open_o1, open_o2, open_z1, open_z2 : std_logic;
    signal ground_vec : std_logic_vector(6 downto 0) := (others => '0');

begin

    -- Calculate A - B
    SUB_AB: ripple_adder
    generic map ( BITS => 7 )
    port map(
        A        => Exp_A,
        B        => Exp_B,
        Cin      => '0',
        add_sub  => '1',      
        sum      => s_diff_AB,
        Cout     => s_swap,  
        Zero     => open_z1,
        Overflow => open_o1
    );

    -- Calculate B - A
    SUB_BA: ripple_adder
    generic map ( BITS => 7 )
    port map(
        A        => Exp_B,
        B        => Exp_A,
        Cin      => '0',
        add_sub  => '1',
        sum      => s_diff_BA,
        Cout     => open_c,
        Zero     => open_z2,
        Overflow => open_o2
    );
    
    Swap_Flag <= s_swap;
    not_swap  <= NOT s_swap;

    MUX_DIFF: quad_n_mux_selector
    generic map ( BITS => 7 )
    port map (
        in_tt     => s_diff_AB, 
        in_tf     => s_diff_BA,  
        in_ft     => ground_vec, 
        in_ff     => ground_vec,
        
        in_sel_tt => not_swap, 
        in_sel_tf => s_swap, 
        in_sel_ft => '0',
        in_sel_ff => '0',
        
        out_mux   => Exp_Difference
    );

end structural;