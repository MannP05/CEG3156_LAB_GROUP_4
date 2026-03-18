LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nbit_ALU IS
    GENERIC (n : INTEGER := 8);
    PORT(
        i_A          : IN  STD_LOGIC_VECTOR(n-1 downto 0);
        i_B          : IN  STD_LOGIC_VECTOR(n-1 downto 0);
        i_ALUControl : IN  STD_LOGIC_VECTOR(2 downto 0);
        o_ALUResult  : OUT STD_LOGIC_VECTOR(n-1 downto 0);
        o_Zero       : OUT STD_LOGIC);
END nbit_ALU;

ARCHITECTURE rtl OF nbit_ALU IS

    SIGNAL and_result    : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL or_result     : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL addsub_result : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL slt_result    : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL alu_out       : STD_LOGIC_VECTOR(n-1 downto 0);
    SIGNAL carry_out     : STD_LOGIC;
    SIGNAL sub_flag      : STD_LOGIC;
    SIGNAL overflow      : STD_LOGIC;
    SIGNAL or_chain      : STD_LOGIC_VECTOR(n-1 downto 0);

    COMPONENT nBitAddSubUnit IS
        GENERIC (n : INTEGER := 8);
        PORT(
            i_A, i_Bi  : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            i_OpFlag   : IN  STD_LOGIC;
            o_CarryOut : OUT STD_LOGIC;
            o_Sum      : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

    COMPONENT nBitMux4to1 IS
        GENERIC (n : INTEGER := 4);
        PORT(
            s0, s1          : IN  STD_LOGIC;
            x0, x1, x2, x3 : IN  STD_LOGIC_VECTOR(n-1 downto 0);
            y               : OUT STD_LOGIC_VECTOR(n-1 downto 0));
    END COMPONENT;

BEGIN

    sub_flag <= i_ALUControl(2);

    gen_and: FOR i IN 0 TO n-1 GENERATE
        and_result(i) <= i_A(i) AND i_B(i);
    END GENERATE;

    gen_or: FOR i IN 0 TO n-1 GENERATE
        or_result(i) <= i_A(i) OR i_B(i);
    END GENERATE;

    AddSub_inst: nBitAddSubUnit
        GENERIC MAP(n => n)
        PORT MAP(
            i_A        => i_A,
            i_Bi       => i_B,
            i_OpFlag   => sub_flag,
            o_CarryOut => carry_out,
            o_Sum      => addsub_result);

    overflow <= (i_A(n-1) XOR i_B(n-1))
                AND (addsub_result(n-1) XOR i_A(n-1));

    slt_result(0) <= addsub_result(n-1) XOR overflow;

    gen_slt_zeros: FOR i IN 1 TO n-1 GENERATE
        slt_result(i) <= '0';
    END GENERATE;

    result_mux: nBitMux4to1
        GENERIC MAP(n => n)
        PORT MAP(
            s0 => i_ALUControl(0),
            s1 => i_ALUControl(1),
            x0 => and_result,
            x1 => or_result,
            x2 => addsub_result,
            x3 => slt_result,
            y  => alu_out);

    or_chain(0) <= alu_out(0);

    gen_zero: FOR i IN 1 TO n-1 GENERATE
        or_chain(i) <= or_chain(i-1) OR alu_out(i);
    END GENERATE;

    o_Zero <= NOT or_chain(n-1);

    o_ALUResult <= alu_out;

END rtl;