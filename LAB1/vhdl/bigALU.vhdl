--------------------------------------------------------------------------------
-- Title         : Big ALU (Mantissa Adder)
-- Description   : the Ripple Adder to act as the "Big ALU" 
--              
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bigALU IS
    GENERIC ( 
        BITS : integer := 16
    );
    PORT (
        i_Mantissa_A : IN  STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0); 
        i_Mantissa_B : IN  STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0); 
        
   
        i_Op_Code    : IN  STD_LOGIC; 
        
        -- Outputs
        o_Result     : OUT STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
        o_CarryOut   : OUT STD_LOGIC; 
        o_Overflow   : OUT STD_LOGIC;
        o_Zero       : OUT STD_LOGIC
    );
END bigALU;

ARCHITECTURE structural OF bigALU IS

    COMPONENT ripple_adder
        GENERIC ( 
            BITS : integer 
        );
        PORT (
             A        : in std_logic_vector(BITS - 1 downto 0); 
             B        : in std_logic_vector(BITS - 1 downto 0); 
             Cin      : in std_logic; 
             sum      : out std_logic_vector(BITS - 1 downto 0);
             Cout     : out std_logic;
             Zero     : out std_logic;
             Overflow : out std_logic;
             add_sub  : in std_logic
         );
    END COMPONENT;

BEGIN
    U_ADDER: ripple_adder
    GENERIC MAP ( 
        BITS => BITS 
    )
    PORT MAP (
        A        => i_Mantissa_A,
        B        => i_Mantissa_B,

        Cin      => '0', 
        
        sum      => o_Result,
        Cout     => o_CarryOut,
        Zero     => o_Zero,
        Overflow => o_Overflow,
        add_sub  => i_Op_Code
    );

END structural;