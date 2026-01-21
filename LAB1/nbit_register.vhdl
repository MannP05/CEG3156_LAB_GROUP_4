--------------------------------------------------------------------------------
-- Title         : Byte Register
-- Project       : Lab1
-------------------------------------------------------------------------------
-- File          : byte_register.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A byte register that uses 8 enabled D flip-flops. The register
--               has an active low reset, a load signal, a clock, an 8-bit input,
--               and an 8-bit output.
-------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

ENTITY nbit_register IS 
    generic ( 
                BITS : integer := 4
            );
    PORT (
             in_val : IN STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
             in_load : IN STD_LOGIC;
             in_resetBar : IN STD_LOGIC;
             in_clock : IN STD_LOGIC;
             out_val : OUT STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)
         );
END nbit_register;

ARCHITECTURE rtl OF nbit_register IS
    SIGNAL int_val: STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0) := (others => '0');
    SIGNAL int_valPrime : STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0) := (others => '1');

	COMPONENT enARdFF_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;
BEGIN

    regs: for i in BITS - 1 downto 0 generate
        r: enARdFF_2 PORT MAP (i_resetBar => in_resetBar,
                               i_d => in_val(i), 
                               i_enable => in_load,
                               i_clock => in_clock,
                               o_q => int_val(i),
                               o_qBar => int_valPrime(i));

    end generate regs;

    out_val <= int_val;

END ARCHITECTURE rtl;


