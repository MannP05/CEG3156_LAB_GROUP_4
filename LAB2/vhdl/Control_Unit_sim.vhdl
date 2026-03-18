library ieee;
use ieee.std_logic_1164.all;

entity control_unit_sim is
end control_unit_sim;

architecture behavior of control_unit_sim is

    component Control_Unit
        port(
            opcode   : in std_logic_vector(5 downto 0);
            RegDst   : out std_logic;
            ALUSrc   : out std_logic;
            MemtoReg : out std_logic;
            RegWrite : out std_logic;
            MemRead  : out std_logic;
            MemWrite : out std_logic;
            Branch   : out std_logic;
            ALUOp    : out std_logic_vector(1 downto 0)
        );
    end component;

    signal tb_opcode   : std_logic_vector(5 downto 0) := (others => '0');
    signal tb_RegDst   : std_logic;
    signal tb_ALUSrc   : std_logic;
    signal tb_MemtoReg : std_logic;
    signal tb_RegWrite : std_logic;
    signal tb_MemRead  : std_logic;
    signal tb_MemWrite : std_logic;
    signal tb_Branch   : std_logic;
    signal tb_ALUOp    : std_logic_vector(1 downto 0);

begin

    UUT: Control_Unit port map (
        opcode   => tb_opcode,
        RegDst   => tb_RegDst,
        ALUSrc   => tb_ALUSrc,
        MemtoReg => tb_MemtoReg,
        RegWrite => tb_RegWrite,
        MemRead  => tb_MemRead,
        MemWrite => tb_MemWrite,
        Branch   => tb_Branch,
        ALUOp    => tb_ALUOp
    );

    stim_proc: process
    begin
        tb_opcode <= "000000";
        wait for 10 ns;
       
        tb_opcode <= "111111";
        wait for 10 ns;
       
        tb_opcode <= "101010"; 
        wait for 10 ns;

        tb_opcode <= "000100";
        wait for 10 ns;
        wait;
    end process;

end behavior;