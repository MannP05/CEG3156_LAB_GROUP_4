library ieee;
use ieee.std_logic_1164.all;
entity Control_Unit is
    port(
        opcode : in std_logic_vector(5 downto 0);

        RegDst : out std_logic;
        ALUSrc : out std_logic;
        MemtoReg : out std_logic;
        RegWrite : out std_logic;
        MemRead : out std_logic;
        MemWrite : out std_logic;
        Branch : out std_logic;
        ALUOp : out std_logic_vector(1 downto 0)
    );
end Control_Unit;

architecture structural of Control_Unit is
    signal R_format, lw, sw, beq : std_logic;
begin

    R_format <= (not opcode(5)) and (not opcode(4)) and (not opcode(3)) and (not opcode(2)) and (not opcode(1)) and (not opcode(0));
    lw <= opcode(5) and (not opcode(4)) and (not opcode(3)) and (not opcode(2)) and  opcode(1) and opcode(0);
    sw <= opcode(5) and (not opcode(4)) and opcode(3) and (not opcode(2)) and  opcode(1) and  opcode(0);
    beq <= (not opcode(5)) and (not opcode(4)) and (not opcode(3)) and opcode(2) and (not opcode(1)) and (not opcode(0));

    RegDst <= R_format;
    AluSrc <= lw or sw;
    MemtoReg <= lw;
    RegWrite <= R_format or lw;
    MemRead <= lw;
    MemWrite <= sw;
    Branch <= beq;
    ALUOp(0) <= beq;
    ALUOp(1) <= R_format;
end structural;

