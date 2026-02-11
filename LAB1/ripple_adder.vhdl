library ieee;
use ieee.std_logic_1164.all;

entity ripple_adder is
    generic ( 
        BITS : integer := 4
    );
    port (
        A        : in std_logic_vector(BITS - 1 downto 0); 
        B        : in std_logic_vector(BITS - 1 downto 0); 
        Cin      : in std_logic; 
        sum      : out std_logic_vector(BITS - 1 downto 0);
        Cout     : out std_logic;
        Zero     : out std_logic;
        Overflow : out std_logic;
        add_sub  : in std_logic
    );
end ripple_adder;

architecture rtl of ripple_adder is
    signal C_internal : std_logic_vector(BITS downto 0) := (others => '0'); 
    signal B_internal : std_logic_vector(BITS - 1 downto 0) := (others => '0');
    signal S_internal : std_logic_vector(BITS - 1 downto 0) := (others => '0');
    signal Z_internal : std_logic_vector(BITS downto 0) := (others => '0');

    COMPONENT oneBitAdder
    PORT(
        i_CarryIn       : IN    STD_LOGIC;
        i_Ai, i_Bi      : IN    STD_LOGIC;
        o_Sum, o_CarryOut : OUT   STD_LOGIC
    );
    END COMPONENT;

begin
    C_internal(0) <= Cin or add_sub;

    adders: for i in BITS - 1 downto 0 generate
        B_internal(i) <= B(i) xor add_sub;

        adder: oneBitAdder 
        PORT MAP(
            i_CarryIn  => C_internal(i),
            i_Ai       => A(i),
            i_Bi       => B_internal(i),
            o_Sum      => S_internal(i),
            o_CarryOut => C_internal(i+1)
        );
    end generate;

    sum <= S_internal;

    Cout <= C_internal(BITS) XOR add_sub; 
    
    Overflow <= C_internal(BITS) XOR C_internal(BITS-1);

    zero_find : for i in BITS - 1 downto 0 generate
        Z_internal(i) <= S_internal(i) OR Z_internal(i + 1);
    end generate;
    Zero <= NOT Z_internal(0);

end rtl;