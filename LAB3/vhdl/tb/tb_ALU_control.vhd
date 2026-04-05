library ieee;
use ieee.std_logic_1164.all;

entity tb_ALU_control is
end tb_ALU_control;

architecture behavior of tb_ALU_control is

    component ALU_control
        port(
            ALU_Op    : in std_logic_vector(1 downto 0);
            funct     : in std_logic_vector(5 downto 0);
            Operation : out std_logic_vector(2 downto 0)
        );
    end component;

    signal tb_ALU_Op    : std_logic_vector(1 downto 0) := "00";
    signal tb_funct     : std_logic_vector(5 downto 0) := "000000";
    signal tb_Operation : std_logic_vector(2 downto 0);

begin

    alu_1: ALU_control port map (
        ALU_Op    => tb_ALU_Op,
        funct     => tb_funct,
        Operation => tb_Operation
    );

    stim_proc: process
    begin
        -- Test Case 1: ALU_Op = "00" (Load/Store -> Add)
        tb_ALU_Op <= "00";
        tb_funct  <= "000000";  -- funct doesn't matter
        wait for 10 ns;
        assert (tb_Operation = "010") 
            report "Test Case 1 Failed: ALU_Op=00 should give ADD (010)" severity error;

        -- Test Case 2: ALU_Op = "01" (Branch -> Subtract)
        tb_ALU_Op <= "01";
        tb_funct  <= "000000";  -- funct doesn't matter
        wait for 10 ns;
        assert (tb_Operation = "110") 
            report "Test Case 2 Failed: ALU_Op=01 should give SUB (110)" severity error;

        -- Test Case 3: ALU_Op = "10", funct = "100000" (R-type ADD)
        tb_ALU_Op <= "10";
        tb_funct  <= "100000";
        wait for 10 ns;
        assert (tb_Operation = "010") 
            report "Test Case 3 Failed: R-type ADD should give 010" severity error;

        -- Test Case 4: ALU_Op = "10", funct = "100010" (R-type SUB)
        tb_ALU_Op <= "10";
        tb_funct  <= "100010";
        wait for 10 ns;
        assert (tb_Operation = "110") 
            report "Test Case 4 Failed: R-type SUB should give 110" severity error;

        -- Test Case 5: ALU_Op = "10", funct = "100100" (R-type AND)
        tb_ALU_Op <= "10";
        tb_funct  <= "100100";
        wait for 10 ns;
        assert (tb_Operation = "000") 
            report "Test Case 5 Failed: R-type AND should give 000" severity error;

        -- Test Case 6: ALU_Op = "10", funct = "100101" (R-type OR)
        tb_ALU_Op <= "10";
        tb_funct  <= "100101";
        wait for 10 ns;
        assert (tb_Operation = "001") 
            report "Test Case 6 Failed: R-type OR should give 001" severity error;

        -- Test Case 7: ALU_Op = "10", funct = "101010" (R-type SLT)
        tb_ALU_Op <= "10";
        tb_funct  <= "101010";
        wait for 10 ns;
        assert (tb_Operation = "111") 
            report "Test Case 7 Failed: R-type SLT should give 111" severity error;

        -- Test Case 8: ALU_Op = "11" (Undefined - testing edge case)
        tb_ALU_Op <= "11";
        tb_funct  <= "111111";
        wait for 10 ns;
        -- No assertion - undefined behavior

        -- Test Case 9: ALU_Op = "11", funct = "000000"
        tb_ALU_Op <= "11";
        tb_funct  <= "000000";
        wait for 10 ns;
        -- No assertion - undefined behavior

        -- Test Case 10: ALU_Op = "11", funct = "001010"
        tb_ALU_Op <= "11";
        tb_funct  <= "001010";
        wait for 10 ns;
        -- No assertion - undefined behavior

        report "All ALU_control test cases completed!" severity note;

        -- Stop the simulation
        wait;
    end process;

end behavior;