library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

entity ripple_adder is
    generic ( 
                -- min 1
                BITS : integer := 4
            );

    port (
             A: in std_logic_vector(BITS - 1 downto 0); 
             B : in std_logic_vector(BITS - 1 downto 0); 
             Cin : in std_logic; 
             sum : out std_logic_vector(BITS - 1 downto 0);
             Cout : out std_logic;
             Zero : out std_logic;
             Overflow : out std_logic;
             add_sub : in std_logic -- flag for add or subtract (0 = add)
         );
end ripple_adder;

architecture rtl of ripple_adder is
    signal C_internal : std_logic_vector(BITS downto 0) := (others => '0'); 
    signal B_internal : std_logic_vector(BITS - 1 downto 0) := (others => '0');
    signal S_internal : std_logic_vector(BITS - 1 downto 0) := (others => '0');
    signal Z_internal : STD_LOGIC_VECTOr(BITS  downto 0) := (others => '0');

    component oneBitAdder -- 1-bit adder given by our prof
        port(
            i_Ai, i_Bi, i_CarryIn : in    std_logic;
            o_Sum, o_CarryOut  : out   std_logic
        );
    end component;

begin
    C_internal(0) <= Cin or add_sub;

    adders: for i in BITS - 1 downto 0 generate
        B_internal(i) <= B(i) xor add_sub;


        adder: oneBitAdder 
        port map(
                    i_Ai => A(i),
                    i_Bi => B_internal(i),
                    i_CarryIn => C_internal(i),
                    o_Sum => S_internal(i),
                    o_CarryOut => C_internal(i+1)
                );
    end generate;

    Cout <= C_internal(BITS) XOR add_sub; -- sub is inverse of Cout, so when add_sub is 1, it inverts C_internal, and when it's 0, it's the same
    Overflow <= C_internal(BITS) XOR C_internal(BITS-1);

    -- This genuinely breaks for n < 1 BIT adders, oh well
    zero_find : for i in BITS - 1 downto 0 generate
        Z_internal(i) <= S_internal(i) OR Z_internal(i + 1);
    end generate;
    Zero <= NOT Z_internal(0);

    sum <= S_internal;

end rtl;
