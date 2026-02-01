--------------------------------------------------------------------------------
-- Title         : 16-bit Bidirectional Shifter
-- Description   : Performs Logical Shift Right (for Alignment) 
--                 and Logical Shift Left (for Normalization).
--                 Strictly structural implementation using AND/OR/NOT gates.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY bidirectional_shifter IS
    PORT (
        i_val      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        i_enable   : IN  STD_LOGIC;
        i_direction: IN  STD_LOGIC; -- 0 = Shift Right, 1 = Shift Left
        o_val      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END bidirectional_shifter;

ARCHITECTURE structural OF bidirectional_shifter IS
    
    SIGNAL s_not_enable    : STD_LOGIC;
    SIGNAL s_not_direction : STD_LOGIC;
    
    SIGNAL s_do_right : STD_LOGIC;
    SIGNAL s_do_left  : STD_LOGIC;
    SIGNAL s_hold     : STD_LOGIC;

BEGIN

    s_not_enable    <= NOT i_enable;
    s_not_direction <= NOT i_direction;

    s_do_right <= i_enable AND s_not_direction;

    s_do_left  <= i_enable AND i_direction;

    s_hold     <= s_not_enable;

    o_val(0) <= (i_val(1) AND s_do_right) OR ('0' AND s_do_left) OR (i_val(0) AND s_hold);

    gen_mid_bits: FOR i IN 1 TO 14 GENERATE
        o_val(i) <= (i_val(i+1) AND s_do_right) OR 
                    (i_val(i-1) AND s_do_left)  OR 
                    (i_val(i)   AND s_hold);
    END GENERATE gen_mid_bits;

    o_val(15) <= ('0' AND s_do_right) OR (i_val(14) AND s_do_left) OR (i_val(15) AND s_hold);

END structural;