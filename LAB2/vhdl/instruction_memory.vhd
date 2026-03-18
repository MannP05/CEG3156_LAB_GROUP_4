-- ============================================================
-- CEG 3156 Lab 2 - Instruction Memory
-- LPM_ROM: 256 x 32-bit, synchronous address (Cyclone IV E)
--
-- Target: Cyclone IV E, Quartus II 13.1
--
-- FIX: Cyclone IV E only supports synchronous ROM.
--   LPM_ADDRESS_CONTROL = "REGISTERED" -> address latched on inclock
--   LPM_OUTDATA         = "UNREGISTERED" -> data output combinatorial
--
--
-- Port mapping in top-level:
--   address <- pc_next   (fed BEFORE the clock edge)
--   clock   <- GClock
--   q       -> instruction
-- ============================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

ENTITY instruction_memory IS
    PORT(
        address : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);   -- fed from pc_next
        clock   : IN  STD_LOGIC;
        q       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END instruction_memory;

ARCHITECTURE structural OF instruction_memory IS
BEGIN

    ROM_inst : lpm_rom
        GENERIC MAP(
            LPM_WIDTH           => 32,
            LPM_WIDTHAD         => 8,
            LPM_NUMWORDS        => 256,
            LPM_FILE            => "instruction_memory.mif",
            LPM_ADDRESS_CONTROL => "REGISTERED",    -- required for Cyclone IV E
            LPM_OUTDATA         => "UNREGISTERED",  -- combinatorial output
            LPM_TYPE            => "LPM_ROM"
        )
        PORT MAP(
            address => address,
            inclock => clock,
            q       => q
        );

END structural;