LIBRARY ieee;
use ieee.std_logic_1164.ALL;

-- STOLEN FROM SLIDES

ENTITY latch IS PORT(
    i_set, i_reset : IN STD_LOGIC;
    i_enable : IN STD_LOGIC;
    o_q, o_qPrime : OUT STD_LOGIC
);

END latch;

ARCHITECTURE rtl OF latch IS
    SIGNAL int_q, int_qPrime : STD_LOGIC;
    SIGNAL int_sSignal, int_rSignal: STD_LOGIC;
BEGIN
    -- Trigger signals
    int_sSignal <= i_set nand i_enable;
    int_rSignal <= i_enable nand i_reset;
    int_q       <= int_sSignal nand int_qPrime;
    int_qPrime  <= int_q nand int_rSignal;

    -- Output
    o_q         <= int_q;
    o_qPrime    <= int_qPrime;
END rtl;
