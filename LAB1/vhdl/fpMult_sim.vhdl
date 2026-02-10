LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fpMult_sim IS
END fpMult_sim;

ARCHITECTURE behavior OF fpMult_sim IS

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT fpMult
    PORT(
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
    END COMPONENT;

    -- Signal Declarations
    SIGNAL SignA       : STD_LOGIC := '0';
    SIGNAL MantissaA   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL ExponentA   : STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0');
    SIGNAL SignB       : STD_LOGIC := '0';
    SIGNAL MantissaB   : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
    SIGNAL ExponentB   : STD_LOGIC_VECTOR(6 DOWNTO 0) := (others => '0');
    SIGNAL GClock      : STD_LOGIC := '0';
    SIGNAL GReset      : STD_LOGIC := '0';

    -- Outputs
    SIGNAL SignOut     : STD_LOGIC;
    SIGNAL MantissaOut : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ExponentOut : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL Overflow    : STD_LOGIC;

    -- Clock period definition
    CONSTANT clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: fpMult PORT MAP (
        SignA => SignA,
        MantissaA => MantissaA,
        ExponentA => ExponentA,
        SignB => SignB,
        MantissaB => MantissaB,
        ExponentB => ExponentB,
        GClock => GClock,
        GReset => GReset,
        SignOut => SignOut,
        MantissaOut => MantissaOut,
        ExponentOut => ExponentOut,
        Overflow => Overflow
    );

    -- Clock Process
    clk_process :process
    BEGIN
        GClock <= '0';
        WAIT FOR clk_period/2;
        GClock <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;

    -- Stimulus Process
    stim_proc: process
    BEGIN
        -- 1. Hold Reset for 2 cycles
        GReset <= '1';
        WAIT FOR clk_period * 2;
        GReset <= '0';
        WAIT FOR clk_period;

        -- =========================================================
        -- TEST CASE 1: 2.5 * 12.0 = 30.0
        -- =========================================================
        -- Format: 1 Sign, 7 Exp (Bias 63), 8 Mantissa
        -- Value = (-1)^S * (1.Mantissa) * 2^(Exponent - 63)
        
        -- Input A: 2.5
        -- 2.5 = 1.25 * 2^1
        -- Sign: 0
        -- Exponent: 1 + 63 = 64 (1000000)
        -- Mantissa: 0.25 (binary .01000000) -> "01000000"
        SignA <= '0';
        ExponentA <= "1000000"; 
        MantissaA <= "01000000";

        -- Input B: 12.0
        -- 12.0 = 1.5 * 2^3
        -- Sign: 0
        -- Exponent: 3 + 63 = 66 (1000010)
        -- Mantissa: 0.5 (binary .10000000) -> "10000000"
        SignB <= '0';
        ExponentB <= "1000010"; 
        MantissaB <= "10000000";

        -- Pulse Reset to start the Multiplier state machine
        -- (Assuming design starts on Reset release or uses a start signal)
        -- Based on your code, it loads inputs when reset releases or control logic loops.
        -- Let's give it time to calculate (Shift-Add takes approx 9-10 cycles)
        WAIT FOR clk_period * 20;


        -- =========================================================
        -- TEST CASE 2: -3.0 * 1.5 = -4.5 (Normalization Check)
        -- =========================================================
        -- We need to assert reset briefly to restart the control unit for new inputs
        GReset <= '1';
        WAIT FOR clk_period;
        
        -- Input A: -3.0
        -- -3.0 = -1.5 * 2^1
        -- Sign: 1
        -- Exponent: 1 + 63 = 64 (1000000)
        -- Mantissa: 0.5 -> "10000000"
        SignA <= '1';
        ExponentA <= "1000000";
        MantissaA <= "10000000";

        -- Input B: 1.5
        -- 1.5 = 1.5 * 2^0
        -- Sign: 0
        -- Exponent: 0 + 63 = 63 (0111111)
        -- Mantissa: 0.5 -> "10000000"
        SignB <= '0';
        ExponentB <= "0111111";
        MantissaB <= "10000000";
        
        GReset <= '0'; -- Start calculation
        WAIT FOR clk_period * 20;

        -- End Simulation
        ASSERT FALSE REPORT "Simulation Finished" SEVERITY FAILURE;
    END PROCESS;

END behavior;