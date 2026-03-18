-- ============================================================
-- CEG 3156 Lab 2 - Data Memory
--
-- ============================================================

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

ENTITY data_memory IS
    PORT(
        address : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- 8-bit address from ALU
        clock   : IN  STD_LOGIC;                      -- GClock
        data    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- write data (from rt register)
        wren    : IN  STD_LOGIC;                      -- write enable (MemWrite)
        q       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)   -- read data output (for lw)
    );
END data_memory;

ARCHITECTURE structural OF data_memory IS
BEGIN

    RAM_inst : lpm_ram_dq
        GENERIC MAP(
            LPM_WIDTH           => 8,           -- 8-bit data width
            LPM_WIDTHAD         => 8,           -- 8-bit address (256 locations)
            LPM_NUMWORDS        => 256,          -- 256 words
            LPM_FILE            => "data_memory.mif",   -- initialization file
            LPM_INDATA          => "REGISTERED",         -- write data registered on clock
            LPM_ADDRESS_CONTROL => "REGISTERED",         -- address registered on clock
            LPM_OUTDATA         => "UNREGISTERED",       -- read output combinatorial
            LPM_TYPE            => "LPM_RAM_DQ"
        )
        PORT MAP(
            address => address,
            data    => data,
            we      => wren,
            inclock => clock,    -- write clock edge
            q       => q
            -- outclock omitted: UNREGISTERED output does not need it
        );

END structural;
