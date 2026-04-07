LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dFF_2 IS
    PORT(
        i_d      : IN  STD_LOGIC;
        i_clock  : IN  STD_LOGIC;
        o_q      : OUT STD_LOGIC;
        o_qBar   : OUT STD_LOGIC
    );
END dFF_2;

ARCHITECTURE rtl OF dFF_2 IS
    SIGNAL int_q : STD_LOGIC := '0';  
BEGIN

    oneBitRegister:
    PROCESS(i_clock)
    BEGIN
        IF (i_clock'EVENT and i_clock = '1') THEN
            int_q <= i_d;
        END IF;
    END PROCESS oneBitRegister;

    o_q    <= int_q;
    o_qBar <= not(int_q);

END rtl;