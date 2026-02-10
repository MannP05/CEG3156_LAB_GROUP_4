LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fpMult IS
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
END fpMult;

ARCHITECTURE structural OF fpMult IS

    SIGNAL ExpA_8, ExpB_8   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ExpSum, ExpBiased: STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ExpNorm            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL Norm_Bit           : STD_LOGIC;
    SIGNAL Norm_Bit_Vec       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    SIGNAL MantA_Ext          : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL MantB_Ext          : STD_LOGIC_VECTOR(8 DOWNTO 0);
    
    SIGNAL Reg_A_In, Reg_A_Out : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL Reg_B_In, Reg_B_Out : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL Prod_In, Prod_Out   : STD_LOGIC_VECTOR(17 DOWNTO 0);
    
    SIGNAL ALU_Add_Out        : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL Shifter_A_Out      : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL Shifter_B_Out      : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL Mux_Prod_Calc      : STD_LOGIC_VECTOR(17 DOWNTO 0);
    SIGNAL Zero_Vec_18        : STD_LOGIC_VECTOR(17 DOWNTO 0);
    
    SIGNAL ctrl_load, ctrl_add, ctrl_shift, ctrl_done : STD_LOGIC;

    COMPONENT controlUnit_Mult
        PORT (clk, reset, multiplier_bit : IN STD_LOGIC;
              load_inputs, shift_enable, add_enable, done_flag : OUT STD_LOGIC);
    END COMPONENT;

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

    COMPONENT bidirectional_shifter
        GENERIC (BITS : INTEGER);
        PORT (i_val : IN STD_LOGIC_VECTOR(BITS-1 DOWNTO 0);
              i_enable, i_direction : IN STD_LOGIC; o_val : OUT STD_LOGIC_VECTOR(BITS-1 DOWNTO 0));
    END COMPONENT;

BEGIN

    SignOut <= SignA XOR SignB;

    MantA_Ext <= "000000000" & '1' & MantissaA;
    MantB_Ext <= '1' & MantissaB;
    Zero_Vec_18 <= (OTHERS => '0');

    U_CTRL : controlUnit_Mult
    PORT MAP (
        clk => GClock, reset => GReset, multiplier_bit => Reg_B_Out(0),
        load_inputs => ctrl_load, shift_enable => ctrl_shift, 
        add_enable => ctrl_add, done_flag => ctrl_done
    );

    U_MUX_A : mux_2x1 GENERIC MAP (18)
    PORT MAP (in_0 => Shifter_A_Out, in_1 => MantA_Ext, in_sel => ctrl_load, out_mux => Reg_A_In);

    U_REG_A : nbit_register GENERIC MAP (18)
    PORT MAP (in_val => Reg_A_In, in_load => '1', in_resetBar => NOT GReset, in_clock => GClock, out_val => Reg_A_Out);

    U_SHIFT_A : bidirectional_shifter GENERIC MAP (18)
    PORT MAP (i_val => Reg_A_Out, i_enable => ctrl_shift, i_direction => '1', o_val => Shifter_A_Out);

    U_MUX_B : mux_2x1 GENERIC MAP (9)
    PORT MAP (in_0 => Shifter_B_Out, in_1 => MantB_Ext, in_sel => ctrl_load, out_mux => Reg_B_In);

    U_REG_B : nbit_register GENERIC MAP (9)
    PORT MAP (in_val => Reg_B_In, in_load => '1', in_resetBar => NOT GReset, in_clock => GClock, out_val => Reg_B_Out);

    U_SHIFT_B : bidirectional_shifter GENERIC MAP (9)
    PORT MAP (i_val => Reg_B_Out, i_enable => ctrl_shift, i_direction => '0', o_val => Shifter_B_Out);

    U_ALU_PROD : bigALU GENERIC MAP (18)
    PORT MAP (i_Mantissa_A => Prod_Out, i_Mantissa_B => Reg_A_Out, i_Op_Code => '0', 
              o_Result => ALU_Add_Out, o_CarryOut => open, o_Overflow => open, o_Zero => open);

    U_MUX_ADD : mux_2x1 GENERIC MAP (18)
    PORT MAP (in_0 => Prod_Out, in_1 => ALU_Add_Out, in_sel => ctrl_add, out_mux => Mux_Prod_Calc);

    U_MUX_LOAD_PROD : mux_2x1 GENERIC MAP (18)
    PORT MAP (in_0 => Mux_Prod_Calc, in_1 => Zero_Vec_18, in_sel => ctrl_load, out_mux => Prod_In);

    U_REG_PROD : nbit_register GENERIC MAP (18)
    PORT MAP (in_val => Prod_In, in_load => '1', in_resetBar => NOT GReset, in_clock => GClock, out_val => Prod_Out);

    ExpA_8 <= '0' & ExponentA;
    ExpB_8 <= '0' & ExponentB;

    U_EXP_ADD1 : bigALU GENERIC MAP (8)
    PORT MAP (i_Mantissa_A => ExpA_8, i_Mantissa_B => ExpB_8, i_Op_Code => '0', o_Result => ExpSum, 
              o_CarryOut => open, o_Overflow => open, o_Zero => open);
              
    U_EXP_SUB : bigALU GENERIC MAP (8)
    PORT MAP (i_Mantissa_A => ExpSum, i_Mantissa_B => "11000001", i_Op_Code => '0', o_Result => ExpBiased, 
              o_CarryOut => open, o_Overflow => open, o_Zero => open);

    Norm_Bit <= Prod_Out(17);
    Norm_Bit_Vec <= "0000000" & Norm_Bit;

    U_EXP_NORM : bigALU GENERIC MAP (8)
    PORT MAP (i_Mantissa_A => ExpBiased, i_Mantissa_B => Norm_Bit_Vec, i_Op_Code => '0', o_Result => ExpNorm,
              o_CarryOut => open, o_Overflow => open, o_Zero => open);

    ExponentOut <= ExpNorm(6 DOWNTO 0);

    U_MUX_MANT_OUT : mux_2x1 GENERIC MAP (8)
    PORT MAP (
        in_0 => Prod_Out(15 DOWNTO 8),
        in_1 => Prod_Out(16 DOWNTO 9),
        in_sel => Norm_Bit,
        out_mux => MantissaOut
    );

    Overflow <= '0';

END structural;