-- ============================================================
-- Forwarding Unit
-- Resolves data hazards via forwarding from EX/MEM and MEM/WB
--
-- ForwardA / ForwardB encoding:
--   "00" -> use register file output (no forwarding)
--   "01" -> forward from MEM/WB stage
--   "10" -> forward from EX/MEM stage
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY forwarding_unit IS
    PORT(
        IDEX_rs        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        IDEX_rt        : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        EXMEM_RegWrite : IN  STD_LOGIC;
        EXMEM_rd       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        MEMWB_RegWrite : IN  STD_LOGIC;
        MEMWB_rd       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        ForwardA       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        ForwardB       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END forwarding_unit;

ARCHITECTURE structural OF forwarding_unit IS

    -- Match signals for EX/MEM -> EX forwarding (A path)
    SIGNAL exmem_match_rs : STD_LOGIC;
    SIGNAL exmem_nonzero  : STD_LOGIC;
    SIGNAL exmem_fwd_A    : STD_LOGIC;

    -- Match signals for MEM/WB -> EX forwarding (A path)
    SIGNAL memwb_match_rs : STD_LOGIC;
    SIGNAL memwb_nonzero  : STD_LOGIC;
    SIGNAL memwb_fwd_A    : STD_LOGIC;

    -- Match signals for EX/MEM -> EX forwarding (B path)
    SIGNAL exmem_match_rt : STD_LOGIC;
    SIGNAL exmem_fwd_B    : STD_LOGIC;

    -- Match signals for MEM/WB -> EX forwarding (B path)
    SIGNAL memwb_match_rt : STD_LOGIC;
    SIGNAL memwb_fwd_B    : STD_LOGIC;

    -- Bit comparisons
    SIGNAL xnor_exmem_rs  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL xnor_memwb_rs  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL xnor_exmem_rt  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL xnor_memwb_rt  : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Non-zero register check (register 0 never forwarded)
    SIGNAL exmem_rd_nz    : STD_LOGIC;
    SIGNAL memwb_rd_nz    : STD_LOGIC;

BEGIN

    -- ---- Non-zero rd check ----
    exmem_rd_nz <= EXMEM_rd(0) OR EXMEM_rd(1) OR EXMEM_rd(2);
    memwb_rd_nz <= MEMWB_rd(0) OR MEMWB_rd(1) OR MEMWB_rd(2);

    -- ---- EX/MEM match with IDEX_rs ----
    xnor_exmem_rs(0) <= NOT (EXMEM_rd(0) XOR IDEX_rs(0));
    xnor_exmem_rs(1) <= NOT (EXMEM_rd(1) XOR IDEX_rs(1));
    xnor_exmem_rs(2) <= NOT (EXMEM_rd(2) XOR IDEX_rs(2));
    exmem_match_rs   <= xnor_exmem_rs(0) AND xnor_exmem_rs(1) AND xnor_exmem_rs(2);
    exmem_fwd_A      <= EXMEM_RegWrite AND exmem_rd_nz AND exmem_match_rs;

    -- ---- MEM/WB match with IDEX_rs ----
    xnor_memwb_rs(0) <= NOT (MEMWB_rd(0) XOR IDEX_rs(0));
    xnor_memwb_rs(1) <= NOT (MEMWB_rd(1) XOR IDEX_rs(1));
    xnor_memwb_rs(2) <= NOT (MEMWB_rd(2) XOR IDEX_rs(2));
    memwb_match_rs   <= xnor_memwb_rs(0) AND xnor_memwb_rs(1) AND xnor_memwb_rs(2);
    -- Only forward from MEM/WB if EX/MEM is not already forwarding
    memwb_fwd_A <= MEMWB_RegWrite AND memwb_rd_nz AND memwb_match_rs
                   AND (NOT exmem_fwd_A);

    -- ---- ForwardA encoding ----
    -- "10" if EX/MEM hazard, "01" if MEM/WB hazard, else "00"
    ForwardA(1) <= exmem_fwd_A;
    ForwardA(0) <= memwb_fwd_A;

    -- ---- EX/MEM match with IDEX_rt ----
    xnor_exmem_rt(0) <= NOT (EXMEM_rd(0) XOR IDEX_rt(0));
    xnor_exmem_rt(1) <= NOT (EXMEM_rd(1) XOR IDEX_rt(1));
    xnor_exmem_rt(2) <= NOT (EXMEM_rd(2) XOR IDEX_rt(2));
    exmem_match_rt   <= xnor_exmem_rt(0) AND xnor_exmem_rt(1) AND xnor_exmem_rt(2);
    exmem_fwd_B      <= EXMEM_RegWrite AND exmem_rd_nz AND exmem_match_rt;

    -- ---- MEM/WB match with IDEX_rt ----
    xnor_memwb_rt(0) <= NOT (MEMWB_rd(0) XOR IDEX_rt(0));
    xnor_memwb_rt(1) <= NOT (MEMWB_rd(1) XOR IDEX_rt(1));
    xnor_memwb_rt(2) <= NOT (MEMWB_rd(2) XOR IDEX_rt(2));
    memwb_match_rt   <= xnor_memwb_rt(0) AND xnor_memwb_rt(1) AND xnor_memwb_rt(2);
    memwb_fwd_B <= MEMWB_RegWrite AND memwb_rd_nz AND memwb_match_rt
                   AND (NOT exmem_fwd_B);

    -- ---- ForwardB encoding ----
    ForwardB(1) <= exmem_fwd_B;
    ForwardB(0) <= memwb_fwd_B;

END structural;