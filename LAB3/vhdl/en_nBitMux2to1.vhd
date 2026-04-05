LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY en_nBitMux2to1 IS
    GENERIC(n : INTEGER := 4);
    PORT(
        i_en        : IN  STD_LOGIC;
        i_sel       : IN  STD_LOGIC;
        i_0, i_1  : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        output_mux         : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
    );
END en_nBitMux2to1;

ARCHITECTURE structural OF en_nBitMux2to1 IS
    COMPONENT oneBitMux2to1 IS
        PORT(
            s, x0, x1 : IN  STD_LOGIC;
            y         : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL int_mux_out : STD_LOGIC_VECTOR(n-1 DOWNTO 0);

BEGIN

    gen_mux: FOR i IN 0 TO n-1 GENERATE
        mux_i: oneBitMux2to1 PORT MAP(
            s  => i_sel,
            x0 => i_0(i),
            x1 => i_1(i),
            y  => int_mux_out(i)
        );
    END GENERATE;

    gen_en: FOR i IN 0 TO n-1 GENERATE
        output_mux(i) <= int_mux_out(i) AND i_en;
    END GENERATE;

END structural;