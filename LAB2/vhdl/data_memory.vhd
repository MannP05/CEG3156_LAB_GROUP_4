-- ============================================================
-- CEG 3156 Lab 2 - Data Memory
-- LPM_RAM_DQ wrapper: 256 x 8-bit
--
-- Target: Cyclone IV E, Quartus II 13.1
-- Megafunction: lpm_ram_dq from Altera lpm library
--
-- Read  port:  combinatorial (UNREGISTERED) - required for single-cycle lw
-- Write port:  registered on rising edge of inclock - required for single-cycle sw
--
-- LPM_INDATA          = "REGISTERED"    -> write data latched on clock edge
-- LPM_ADDRESS_CONTROL = "REGISTERED"    -> address latched on clock edge (write)
-- LPM_OUTDATA         = "UNREGISTERED"  -> read data appears combinatorially
--
-- Port mapping in top-level:
--   address <- alu_result     (8-bit computed load/store address)
--   clock   <- GClock
--   data    <- read_data2     (rt register content, for sw)
--   wren    <- ctrl_MemWrite  (write enable, from control unit)
--   q       -> mem_read_data  (8-bit data read, for lw)
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
