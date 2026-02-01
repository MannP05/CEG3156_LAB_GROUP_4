LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fpAdd IS
    PORT (
        SignA       : IN  STD_LOGIC;
        MantissaA   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        ExponentA   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        
        SignB       : IN  STD_LOGIC;
        MantissaB   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        ExponentB   : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        
        GClock      : IN  STD_LOGIC;
        GReset      : IN  STD_LOGIC;
        
        SignOut     : OUT STD_LOGIC;
        MantissaOut : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        ExponentOut : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        Overflow    : OUT STD_LOGIC
    );
END fpAdd;

ARCHITECTURE structural OF fpAdd IS

    SIGNAL s_MantA_16   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL s_MantB_16   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    
    SIGNAL s_Exp_Diff   : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL s_Swap_Flag  : STD_LOGIC;
    
    SIGNAL s_Mant_Small : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL s_Mant_Large : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL s_Exp_Large  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    
    SIGNAL s_Mant_Small_Shifted : STD_LOGIC_VECTOR(15 DOWNTO 0);
    
    SIGNAL s_Sum_Result : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL s_CarryOut   : STD_LOGIC;
    SIGNAL s_Zero       : STD_LOGIC;
    SIGNAL s_Ovf_ALU    : STD_LOGIC;
    
    SIGNAL s_shift_enable : STD_LOGIC;

    COMPONENT smallALU
        PORT(
            Exp_A          : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            Exp_B          : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            Exp_Difference : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            Swap_Flag      : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT bigALU 
        GENERIC ( BITS : integer := 16 );
        PORT (
            i_Mantissa_A : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            i_Mantissa_B : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            i_Op_Code    : IN STD_LOGIC;
            o_Result     : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
            o_CarryOut   : OUT STD_LOGIC;
            o_Overflow   : OUT STD_LOGIC;
            o_Zero       : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT mux_2x1_16bit
        PORT (
            in_0    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            in_1    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            in_sel  : IN STD_LOGIC;
            out_mux : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
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

    COMPONENT bidirectional_shifter
        PORT (
            i_val       : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            i_enable    : IN STD_LOGIC;
            i_direction : IN STD_LOGIC;
            o_val       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT ControlUnit
        PORT (
            clk          : IN STD_LOGIC;
            reset        : IN STD_LOGIC;
            exp_diff     : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            shift_enable : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    s_MantA_16 <= "0000000" & '1' & MantissaA;
    s_MantB_16 <= "0000000" & '1' & MantissaB;

    U_SMALL_ALU: smallALU
    PORT MAP (
        Exp_A          => ExponentA,
        Exp_B          => ExponentB,
        Exp_Difference => s_Exp_Diff,
        Swap_Flag      => s_Swap_Flag
    );

    U_MUX_SMALL: mux_2x1_16bit
    PORT MAP (
        in_0    => s_MantB_16,
        in_1    => s_MantA_16,
        in_sel  => s_Swap_Flag,
        out_mux => s_Mant_Small
    );

    U_MUX_LARGE: mux_2x1_16bit
    PORT MAP (
        in_0    => s_MantA_16,
        in_1    => s_MantB_16,
        in_sel  => s_Swap_Flag,
        out_mux => s_Mant_Large
    );

    U_MUX_EXP: mux_2x1
    GENERIC MAP ( BITS => 7 )
    PORT MAP (
        in_0    => ExponentA,
        in_1    => ExponentB,
        in_sel  => s_Swap_Flag,
        out_mux => s_Exp_Large
    );

    U_SHIFTER: bidirectional_shifter
    PORT MAP (
        i_val       => s_Mant_Small,
        i_direction => '0',
        i_enable    => s_shift_enable,
        o_val       => s_Mant_Small_Shifted
    );

    U_BIG_ALU: bigALU
    GENERIC MAP ( BITS => 16 )
    PORT MAP (
        i_Mantissa_A => s_Mant_Large,
        i_Mantissa_B => s_Mant_Small_Shifted,
        i_Op_Code    => '0',
        o_Result     => s_Sum_Result,
        o_CarryOut   => s_CarryOut,
        o_Overflow   => s_Ovf_ALU,
        o_Zero       => s_Zero
    );

    U_CONTROL: ControlUnit
    PORT MAP (
        clk          => GClock,
        reset        => GReset,
        exp_diff     => s_Exp_Diff,
        shift_enable => s_shift_enable
    );

    SignOut <= SignA AND SignB; 

    MantissaOut <= s_Sum_Result(7 DOWNTO 0); 
    
    ExponentOut <= s_Exp_Large;
    
    Overflow <= s_CarryOut OR s_Ovf_ALU;

END structural;