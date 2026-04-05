library ieee;
use ieee.std_logic_1164.all;

entity tb_ALU is
end tb_ALU;

architecture behavior of tb_ALU is

    constant n : integer := 8;

    component nbit_ALU
        generic (n : integer := 8);
        port(
            i_A          : in  std_logic_vector(n-1 downto 0);
            i_B          : in  std_logic_vector(n-1 downto 0);
            i_ALUControl : in  std_logic_vector(2 downto 0);
            o_ALUResult  : out std_logic_vector(n-1 downto 0);
            o_Zero       : out std_logic
        );
    end component;

    signal tb_A          : std_logic_vector(n-1 downto 0) := (others => '0');
    signal tb_B          : std_logic_vector(n-1 downto 0) := (others => '0');
    signal tb_ALUControl : std_logic_vector(2 downto 0) := "000";
    signal tb_ALUResult  : std_logic_vector(n-1 downto 0);
    signal tb_Zero       : std_logic;

begin

    alu_1: nbit_ALU 
        generic map (n => n)
        port map (
            i_A          => tb_A,
            i_B          => tb_B,
            i_ALUControl => tb_ALUControl,
            o_ALUResult  => tb_ALUResult,
            o_Zero       => tb_Zero
        );

    stim_proc: process
    begin
        -- Test Case 1: AND operation (ALUControl = "000")
        tb_A <= "11110000";
        tb_B <= "10101010";
        tb_ALUControl <= "000";
        wait for 10 ns;
        assert (tb_ALUResult = "10100000") 
            report "Test Case 1 Failed: AND operation incorrect" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 1 Failed: Zero flag should be '0'" severity error;

        -- Test Case 2: OR operation (ALUControl = "001")
        tb_A <= "11110000";
        tb_B <= "10101010";
        tb_ALUControl <= "001";
        wait for 10 ns;
        assert (tb_ALUResult = "11111010") 
            report "Test Case 2 Failed: OR operation incorrect" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 2 Failed: Zero flag should be '0'" severity error;

        -- Test Case 3: ADD operation (ALUControl = "010")
        tb_A <= "00000101";  -- 5
        tb_B <= "00000011";  -- 3
        tb_ALUControl <= "010";
        wait for 10 ns;
        assert (tb_ALUResult = "00001000") 
            report "Test Case 3 Failed: ADD operation incorrect (5+3 should be 8)" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 3 Failed: Zero flag should be '0'" severity error;

        -- Test Case 4: SUB operation (ALUControl = "110")
        tb_A <= "00001000";  -- 8
        tb_B <= "00000011";  -- 3
        tb_ALUControl <= "110";
        wait for 10 ns;
        assert (tb_ALUResult = "00000101") 
            report "Test Case 4 Failed: SUB operation incorrect (8-3 should be 5)" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 4 Failed: Zero flag should be '0'" severity error;

        -- Test Case 5: SLT operation - A < B (ALUControl = "111")
        tb_A <= "00000011";  -- 3
        tb_B <= "00000101";  -- 5
        tb_ALUControl <= "111";
        wait for 10 ns;
        assert (tb_ALUResult = "00000001") 
            report "Test Case 5 Failed: SLT operation incorrect (3<5 should be 1)" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 5 Failed: Zero flag should be '0'" severity error;

        -- Test Case 6: SLT operation - A >= B (ALUControl = "111")
        tb_A <= "00000101";  -- 5
        tb_B <= "00000011";  -- 3
        tb_ALUControl <= "111";
        wait for 10 ns;
        assert (tb_ALUResult = "00000000") 
            report "Test Case 6 Failed: SLT operation incorrect (5>=3 should be 0)" severity error;
        assert (tb_Zero = '1') 
            report "Test Case 6 Failed: Zero flag should be '1'" severity error;

        -- Test Case 7: Zero flag test - Result is zero (SUB equal values)
        tb_A <= "00000101";  -- 5
        tb_B <= "00000101";  -- 5
        tb_ALUControl <= "110";  -- SUB
        wait for 10 ns;
        assert (tb_ALUResult = "00000000") 
            report "Test Case 7 Failed: SUB operation incorrect (5-5 should be 0)" severity error;
        assert (tb_Zero = '1') 
            report "Test Case 7 Failed: Zero flag should be '1' when result is zero" severity error;

        -- Test Case 8: Zero flag test - Result is not zero
        tb_A <= "00000101";  -- 5
        tb_B <= "00000011";  -- 3
        tb_ALUControl <= "010";  -- ADD
        wait for 10 ns;
        assert (tb_ALUResult = "00001000") 
            report "Test Case 8 Failed: ADD operation incorrect" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 8 Failed: Zero flag should be '0' when result is not zero" severity error;

        -- Test Case 9: Edge case with all 1s (AND)
        tb_A <= "11111111";
        tb_B <= "11111111";
        tb_ALUControl <= "000";
        wait for 10 ns;
        assert (tb_ALUResult = "11111111") 
            report "Test Case 9 Failed: AND with all 1s should give all 1s" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 9 Failed: Zero flag should be '0'" severity error;

        -- Test Case 10: Edge case with all 0s (OR)
        tb_A <= "00000000";
        tb_B <= "00000000";
        tb_ALUControl <= "001";
        wait for 10 ns;
        assert (tb_ALUResult = "00000000") 
            report "Test Case 10 Failed: OR with all 0s should give all 0s" severity error;
        assert (tb_Zero = '1') 
            report "Test Case 10 Failed: Zero flag should be '1'" severity error;

        -- Test Case 11: Overflow test (ADD)
        tb_A <= "01111111";  -- 127 (Max positive)
        tb_B <= "00000001";  -- 1
        tb_ALUControl <= "010";
        wait for 10 ns;
        assert (tb_ALUResult = "10000000") 
            report "Test Case 11 Failed: ADD overflow incorrect" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 11 Failed: Zero flag should be '0'" severity error;

        -- Test Case 12: Negative numbers (SUB)
        tb_A <= "11111111";  -- -1 in two's complement
        tb_B <= "00000001";  -- 1
        tb_ALUControl <= "110";
        wait for 10 ns;
        assert (tb_ALUResult = "11111110") 
            report "Test Case 12 Failed: SUB with negative numbers incorrect (-1 - 1 = -2)" severity error;
        assert (tb_Zero = '0') 
            report "Test Case 12 Failed: Zero flag should be '0'" severity error;

        -- All tests completed
        report "All test cases completed!" severity note;
        
        -- Stop the simulation
        wait;
    end process;

end behavior;