LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fpAdd_sim IS
END fpAdd_sim;

ARCHITECTURE behavior OF fpAdd_sim IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT fpAdd
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

    -- Inputs
    signal SignA     : std_logic := '0';
    signal MantissaA : std_logic_vector(7 downto 0) := (others => '0');
    signal ExponentA : std_logic_vector(6 downto 0) := (others => '0');
    signal SignB     : std_logic := '0';
    signal MantissaB : std_logic_vector(7 downto 0) := (others => '0');
    signal ExponentB : std_logic_vector(6 downto 0) := (others => '0');
    
    -- Clock and Reset
    signal GClock    : std_logic := '0';
    signal GReset    : std_logic := '0'; -- Active Low logic implies 0 is reset

    -- Outputs
    signal SignOut     : std_logic;
    signal MantissaOut : std_logic_vector(7 downto 0);
    signal ExponentOut : std_logic_vector(6 downto 0);
    signal Overflow    : std_logic;

    -- Clock period definitions
    constant GClock_period : time := 10 ns;
 
BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
    finalOUT: fpAdd PORT MAP (
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

    -- Clock process definitions
    GClock_process :process
    begin
        GClock <= '0';
        wait for GClock_period/2;
        GClock <= '1';
        wait for GClock_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        ------------------------------------------------------------
        -- INITIALIZATION
        ------------------------------------------------------------
        GReset <= '0'; -- Hold Reset (Active Low)
        wait for 40 ns;
        GReset <= '1'; -- Release Reset
        wait for 50 ns;

        -- TEST CASE 1: A + B = 3.75
        SignA <= '0'; ExponentA <= "0111111"; MantissaA <= "01000000"; -- +1.25
        SignB <= '1'; ExponentB <= "1000000"; MantissaB <= "01000000"; -- +2.5

        wait for 10 ns; 
        GReset <= '0'; wait for 20 ns; GReset <= '1';

        wait for 200 ns; -- Wait for result


        


        assert false report "Simulation Finished" severity failure;
        wait;
    end process;

END behavior;