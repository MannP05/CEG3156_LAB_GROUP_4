-- ============================================================
-- Hazard Detection Unit
-- Detects load-use data hazards and generates stall signal
--
-- Stall when:
--   IDEX_MemRead = '1' AND
--   (IDEX_rt = IFID_rs OR IDEX_rt = IFID_rt)
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY hazard_detection_unit IS
    PORT(
        IDEX_MemRead  : IN  STD_LOGIC;
        IDEX_rt       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        IFID_rs       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        IFID_rt       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        PCWrite       : OUT STD_LOGIC;   -- '0' = stall PC
        IFID_Write    : OUT STD_LOGIC;   -- '0' = stall IF/ID reg
        ctrl_flush    : OUT STD_LOGIC    -- '1' = insert NOP into ID/EX
    );
END hazard_detection_unit;

ARCHITECTURE structural OF hazard_detection_unit IS

    -- Bit-wise equality comparison signals
    SIGNAL eq_rs   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL eq_rt   : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL match_rs : STD_LOGIC;
    SIGNAL match_rt : STD_LOGIC;
    SIGNAL hazard   : STD_LOGIC;

    -- XNOR for equality on each bit
    SIGNAL xnor_rs  : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL xnor_rt  : STD_LOGIC_VECTOR(2 DOWNTO 0);

BEGIN

    -- Compare IDEX_rt with IFID_rs  (bitwise XNOR = equality)
    xnor_rs(0) <= NOT (IDEX_rt(0) XOR IFID_rs(0));
    xnor_rs(1) <= NOT (IDEX_rt(1) XOR IFID_rs(1));
    xnor_rs(2) <= NOT (IDEX_rt(2) XOR IFID_rs(2));
    match_rs   <= xnor_rs(0) AND xnor_rs(1) AND xnor_rs(2);

    -- Compare IDEX_rt with IFID_rt
    xnor_rt(0) <= NOT (IDEX_rt(0) XOR IFID_rt(0));
    xnor_rt(1) <= NOT (IDEX_rt(1) XOR IFID_rt(1));
    xnor_rt(2) <= NOT (IDEX_rt(2) XOR IFID_rt(2));
    match_rt   <= xnor_rt(0) AND xnor_rt(1) AND xnor_rt(2);

    -- Hazard condition
    hazard  <= IDEX_MemRead AND (match_rs OR match_rt);

    -- When hazard: freeze PC and IF/ID, flush ID/EX (insert bubble)
    PCWrite    <= NOT hazard;
    IFID_Write <= NOT hazard;
    ctrl_flush <= hazard;

END structural;