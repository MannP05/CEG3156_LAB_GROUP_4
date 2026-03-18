--------------------------------------------------------------------------------
-- Title         : ALU Control
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : ALU_control.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : An ALU control unit that determines the specific operation 
--               to be performed by the ALU. It takes a 2-bit ALU_Op signal 
--               and a 6-bit instruction funct field as inputs, and generates 
--               a 3-bit Operation control signal using combinational logic.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ALU_control is
    port(
        ALU_Op : in std_logic_vector(1 downto 0);
        funct  : in std_logic_vector(5 downto 0);
        Operation : out std_logic_vector(2 downto 0)
    );
end ALU_control;

architecture Structural of ALU_control is
    signal ALUOP_0, ALUOP_1: std_logic;

begin
    AluOP_0 <= ALU_Op(0);
    AluOP_1 <= ALU_Op(1);

    Operation(2) <= (ALUOP_1 and funct(1)) or ALUOP_0;
    Operation(1) <= (not funct(2)) or (not ALUOP_1);
    Operation(0) <= (funct(0) or funct(3)) and ALUOP_1;
end Structural;



