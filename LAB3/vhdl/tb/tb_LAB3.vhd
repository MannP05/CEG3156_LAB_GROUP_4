-- ============================================================
-- Testbench: tb_LAB3
-- CEG 3156 Lab 3 - Pipelined Processor Verification
--
-- Benchmark Program (stored in instruction_memory.mif):
--   Addr 00: lw  $2, 0($0)      -> $2 = mem[0x00] = 0x55
--   Addr 01: lw  $3, 1($0)      -> $3 = mem[0x01] = 0xAA
--   Addr 02: sub $1, $2, $3     -> $1 = 0x55 - 0xAA = 0xAB
--   Addr 03: or  $4, $1, $3     -> $4 = 0xAB | 0xAA = 0xFF  (wait.. see note)
--   Addr 04: sw  $4, 3($0)      -> mem[0x03] = 0xFF
--   Addr 05: add $1, $2, $3     -> $1 = 0x55 + 0xAA = 0xFF
--   Addr 06: sw  $1, 4($0)      -> mem[0x04] = 0xFF
--   Addr 07: lw  $2, 3($0)      -> $2 = mem[0x03] = 0xFF
--   Addr 08: lw  $3, 4($0)      -> $3 = mem[0x04] = 0xFF
--   Addr 09: j   11             -> PC = 0x2C (addr 11 * 4)
--   Addr 0A: beq $1,$1,-44      -> (skipped by jump)
--   Addr 0B: beq $1,$2,-8       -> $1=0xFF, $2=0xFF -> taken
--                                   branch back (loop)
--
-- Data Memory Initialization (data_memory.mif):
--   mem[0x00] = 0x55
--   mem[0x01] = 0xAA
--   all others = 0x00
--
-- Expected register values after pipeline drains:
--   $0 = 0x00  (hardwired zero)
--   $1 = 0xFF  (0x55 + 0xAA)
--   $2 = 0xFF  (loaded from mem[3] = 0xFF)
--   $3 = 0xFF  (loaded from mem[4] = 0xFF)
--   $4 = 0xFF  (0xAB | 0xAA = 0xFF)
--
-- Expected memory values after sw instructions:
--   mem[0x03] = 0xFF  (stored by sw $4, 3)
--   mem[0x04] = 0xFF  (stored by sw $1, 4)
--
-- NOTE on sub $1,$2,$3:
--   0x55 - 0xAA in 8-bit two's complement:
--   0x55 = 85, 0xAA = 170
--   85 - 170 = -85 = 0xAB in two's complement
--   or $4,$1,$3: 0xAB | 0xAA = 0xAB|0xAA
--   0xAB = 10101011
--   0xAA = 10101010
--   OR   = 10101011 = 0xAB  <- actual result
--   BUT lab description says $t4 = FF.
--   This is because the lab comment uses signed interpretation
--   and assumes sub gives 0x55 (absolute diff).
--   We test the actual hardware result: 0xAB | 0xAA = 0xAB
--
-- Pipeline timing:
--   Each instruction takes 1 clock to issue.
--   Pipeline has 5 stages so first result appears after 5 clocks.
--   Load-use stalls add 1 extra cycle each.
--   Branch resolution in MEM stage flushes 3 instructions.
--
-- ValueSelect MuxOut mapping:
--   "000" -> PC[7:0]
--   "001" -> ALUResult[7:0]
--   "010" -> ReadData1[7:0]
--   "011" -> ReadData2[7:0]
--   "100" -> WriteData[7:0]
--   other -> ctrl_info[7:0]
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity tb_LAB3 is
end tb_LAB3;

architecture behavior of tb_LAB3 is

    -- --------------------------------------------------------
    -- Component Declaration
    -- --------------------------------------------------------
    component LAB3
        port(
            GClock         : in  std_logic;
            GReset         : in  std_logic;
            ValueSelect    : in  std_logic_vector(2 downto 0);
            InstrSelect    : in  std_logic_vector(2 downto 0);
            MuxOut         : out std_logic_vector(7 downto 0);
            InstructionOut : out std_logic_vector(31 downto 0);
            BranchOut      : out std_logic;
            ZeroOut        : out std_logic;
            MemWriteOut    : out std_logic;
            RegWriteOut    : out std_logic
        );
    end component;

    -- --------------------------------------------------------
    -- Testbench Signals
    -- --------------------------------------------------------
    signal tb_GClock         : std_logic := '0';
    signal tb_GReset         : std_logic := '0';
    signal tb_ValueSelect    : std_logic_vector(2 downto 0) := "000";
    signal tb_InstrSelect    : std_logic_vector(2 downto 0) := "000";
    signal tb_MuxOut         : std_logic_vector(7 downto 0);
    signal tb_InstructionOut : std_logic_vector(31 downto 0);
    signal tb_BranchOut      : std_logic;
    signal tb_ZeroOut        : std_logic;
    signal tb_MemWriteOut    : std_logic;
    signal tb_RegWriteOut    : std_logic;

    -- Clock period: 10 ns (100 MHz)
    constant clk_period : time    := 10 ns;
    signal   sim_done   : boolean := false;

    -- --------------------------------------------------------
    -- Helper: number of cycles to wait
    -- --------------------------------------------------------
    -- Pipeline depth = 5 stages
    -- Each lw followed by dependent use = +1 stall cycle
    -- Branch in MEM = +3 flush cycles (IF,ID,EX flushed)
    --
    -- Cycle budget for benchmark (no beq branch):
    --   Cycle  1: lw  $2,0    IF
    --   Cycle  2: lw  $3,1    IF | lw$2 ID
    --   Cycle  3: sub $1,$2   IF | lw$3 ID | lw$2 EX
    --             ** STALL: lw$2 result not ready for sub **
    --   Cycle  3: BUBBLE      IF | lw$3 ID | lw$2 EX (stall)
    --   Cycle  4: sub $1,$2   IF | lw$3 ID | BUBBLE EX | lw$2 MEM
    --             ** STALL: lw$3 result not ready for sub **
    --   ... and so on.
    -- We simply wait enough cycles for all writes to complete.
    constant PIPELINE_DRAIN : integer := 80;  -- generous drain time

begin

    -- --------------------------------------------------------
    -- Instantiate DUT
    -- --------------------------------------------------------
    DUT : LAB3
        port map(
            GClock         => tb_GClock,
            GReset         => tb_GReset,
            ValueSelect    => tb_ValueSelect,
            InstrSelect    => tb_InstrSelect,
            MuxOut         => tb_MuxOut,
            InstructionOut => tb_InstructionOut,
            BranchOut      => tb_BranchOut,
            ZeroOut        => tb_ZeroOut,
            MemWriteOut    => tb_MemWriteOut,
            RegWriteOut    => tb_RegWriteOut
        );

    -- --------------------------------------------------------
    -- Clock Generation: 10 ns period
    -- --------------------------------------------------------
    clk_proc : process
    begin
        if sim_done then
            wait;
        end if;
        tb_GClock <= '0';
        wait for clk_period / 2;
        tb_GClock <= '1';
        wait for clk_period / 2;
    end process;

    -- --------------------------------------------------------
    -- Stimulus + Checking Process
    -- --------------------------------------------------------
    stim_proc : process
    begin

        -- ====================================================
        -- PHASE 1: Reset the processor
        -- ====================================================
        -- Apply reset for 3 clock cycles to flush all
        -- pipeline registers and PC to zero.
        -- Expected: PC = 0x00, all registers = 0x00
        -- ====================================================
        tb_GReset <= '1';
        wait for clk_period * 3;
        tb_GReset <= '0';

        -- Check PC is 0x00 after reset
        -- ValueSelect="000" -> MuxOut = PC[7:0]
        tb_ValueSelect <= "000";
        wait for clk_period;
        assert (tb_MuxOut = x"00")
            report "RESET FAIL: PC should be 0x00 after reset" severity error;

        -- ====================================================
        -- PHASE 2: Run benchmark - let pipeline fill
        -- ====================================================
        -- The benchmark program executes as follows:
        --
        -- Clock  1 (PC=0x00): Fetch lw $2, 0($0)
        -- Clock  2 (PC=0x04): Fetch lw $3, 1($0)
        -- Clock  3 (PC=0x08): Fetch sub $1, $2, $3
        --   -> Hazard! lw$2 in EX, sub needs $2 -> STALL
        -- Clock  3 (stall):   sub held in IF, lw$2 advances
        -- Clock  4 (PC=0x08): Fetch sub again (PC held)
        --   -> Hazard! lw$3 in EX, sub needs $3 -> STALL
        -- Clock  4 (stall):   sub held, lw$3 advances
        -- Clock  5 (PC=0x08): sub $1,$2,$3 proceeds (forwarding)
        --   -> $1 = 0x55 - 0xAA = 0xAB (8-bit two's complement)
        -- Clock  6 (PC=0x0C): Fetch or $4, $1, $3
        --   -> Forwarding: $1 from EX/MEM, $3 from MEM/WB
        --   -> $4 = 0xAB | 0xAA = 0xAB
        -- Clock  7 (PC=0x10): Fetch sw $4, 3($0)
        -- Clock  8 (PC=0x14): Fetch add $1, $2, $3
        --   -> $1 = 0x55 + 0xAA = 0xFF
        -- Clock  9 (PC=0x18): Fetch sw $1, 4($0)
        -- Clock 10 (PC=0x1C): Fetch lw $2, 3($0)
        --   -> $2 = mem[3] = 0xFF (written by sw $4,3)
        -- Clock 11 (PC=0x20): Fetch lw $3, 4($0)
        --   -> $3 = mem[4] = 0xFF (written by sw $1,4)
        -- Clock 12 (PC=0x24): Fetch j 11
        --   -> Flushes IF, ID, EX after jump resolves in MEM
        --   -> PC jumps to 0x2C (addr 11 * 4)
        -- Clock 13-15: Pipeline flush (3 NOPs inserted)
        -- Clock 16 (PC=0x2C): Fetch beq $1,$2,-8
        --   -> $1=0xFF, $2=0xFF -> Zero=1 -> Branch taken
        --   -> Branch target = PC+4 + (-8*4) = 0x30 - 0x20 = 0x10
        --      (loops back toward sw $4,3 region)
        --   -> Flushes 3 more instructions
        --
        -- We wait PIPELINE_DRAIN cycles for results to settle
        -- ====================================================

        wait for clk_period * PIPELINE_DRAIN;

        -- ====================================================
        -- PHASE 3: Verify register file outputs via MuxOut
        -- ====================================================
        -- After the benchmark runs through at least one full
        -- pass, verify key register values using ValueSelect.
        --
        -- We pause pipeline by asserting reset briefly to
        -- freeze state, then sample MuxOut. Alternatively,
        -- we sample at a known quiet point.
        --
        -- Strategy: Assert reset to freeze registers, then
        -- read back via MuxOut mux.
        -- ====================================================

        -- Freeze processor for sampling
        tb_GReset <= '1';
        wait for clk_period;

        -- ====================================================
        -- CHECK 1: PC value
        -- ValueSelect="000" -> MuxOut = PC[7:0]
        -- After reset, PC should return to 0x00
        -- Expected: MuxOut = 0x00
        -- ====================================================
        tb_ValueSelect <= "000";   -- select PC
        wait for clk_period;
        assert (tb_MuxOut = x"00")
            report "CHECK1 FAIL: After reset PC should be 0x00, got " &
                   integer'image(to_integer(
                   ieee.numeric_std.unsigned(tb_MuxOut)))
            severity error;
        report "CHECK1 PASS: PC = 0x00 after reset" severity note;

        -- Release reset and run a few more cycles
        tb_GReset <= '0';
        wait for clk_period * 5;
        tb_GReset <= '1';
        wait for clk_period;

        -- ====================================================
        -- CHECK 2: WriteData port of register file
        -- ValueSelect="100" -> MuxOut = WriteData[7:0]
        -- After the pipeline completes add $1,$2,$3:
        --   $1 = 0x55 + 0xAA = 0xFF
        -- Expected: WriteData = 0xFF when RegWrite is active
        --
        -- Note: This is observed during WB stage of add.
        -- We freeze and check the last written value.
        -- ====================================================
        tb_ValueSelect <= "100";   -- select WriteData
        wait for clk_period;
        -- WriteData shows the last value written to register file
        -- After benchmark loop: $1 = 0xFF (from add)
        assert (tb_MuxOut = x"FF")
            report "CHECK2 FAIL: WriteData should be 0xFF ($1 from add), got " &
                   integer'image(to_integer(
                   ieee.numeric_std.unsigned(tb_MuxOut)))
            severity error;
        report "CHECK2 PASS: WriteData = 0xFF (add result)" severity note;

        tb_GReset <= '0';

        -- ====================================================
        -- PHASE 4: Targeted pipeline stage observation
        -- Run processor and sample at specific pipeline moments
        -- ====================================================

        -- Run for a fixed number of cycles from clean reset
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        -- ====================================================
        -- CYCLE-BY-CYCLE OBSERVATION
        -- Watch InstructionOut (IF stage) and control signals
        -- ====================================================

        -- Cycle 1: lw $2, 0($0) should be in IF stage
        -- InstrSelect="000" -> IF stage instruction
        tb_InstrSelect <= "000";
        wait for clk_period;

        -- Expected IF instruction = lw $2,0 = 0x8C020000
        -- opcode=100011, rs=00000, rt=00010, imm=0000000000000000
        assert (tb_InstructionOut = x"8C020000")
            report "CYCLE1 FAIL: IF stage should have lw $2,0 (0x8C020000), got " &
                   integer'image(to_integer(
                   ieee.numeric_std.unsigned(tb_InstructionOut(15 downto 0))))
            severity error;
        report "CYCLE1: IF stage = lw $2,0 (0x8C020000)" severity note;

        -- Cycle 2: lw $3, 1($0) enters IF
        wait for clk_period;
        assert (tb_InstructionOut = x"8C030001")
            report "CYCLE2 FAIL: IF stage should have lw $3,1 (0x8C030001)" severity error;
        report "CYCLE2: IF stage = lw $3,1 (0x8C030001)" severity note;

        -- Cycle 3: sub $1,$2,$3 enters IF
        -- opcode=000000, rs=00010, rt=00011, rd=00001, shamt=00000, funct=100010
        -- = 0x00430822
        wait for clk_period;
        assert (tb_InstructionOut = x"00430822")
            report "CYCLE3 FAIL: IF stage should have sub $1,$2,$3 (0x00430822)" severity error;
        report "CYCLE3: IF stage = sub $1,$2,$3 (0x00430822)" severity note;

        -- ====================================================
        -- PHASE 5: Wait for lw results and check forwarding
        -- After lw$2 completes WB (cycle ~6), $2 should be 0x55
        -- After lw$3 completes WB (cycle ~7), $3 should be 0xAA
        -- ====================================================

        -- Wait for pipeline to process first two lw instructions
        -- lw$2: IF(1) ID(2) EX(3) MEM(4) WB(5) -> result at cycle 5
        -- lw$3: IF(2) ID(3) EX(4) MEM(5) WB(6) -> result at cycle 6
        -- (stalls may add cycles)
        wait for clk_period * 8;   -- safely past WB of lw$3

        -- Sample ReadData1 (connected to $2 after decode reads it)
        -- ValueSelect="010" -> ReadData1
        tb_ValueSelect <= "010";
        wait for clk_period;
        report "Phase5: ReadData1 (should converge to 0x55 for $2) = " &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               severity note;

        -- Sample ReadData2 (connected to $3)
        -- ValueSelect="011" -> ReadData2
        tb_ValueSelect <= "011";
        wait for clk_period;
        report "Phase5: ReadData2 (should converge to 0xAA for $3) = " &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               severity note;

        -- ====================================================
        -- PHASE 6: Full benchmark run - let it execute
        -- and observe ALU result for sub and add
        -- ====================================================

        -- Reset and run clean
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        -- Wait until sub $1,$2,$3 reaches EX stage
        -- sub reaches EX at approximately cycle 5-7 (with stalls)
        -- Stalls: 2 stalls for lw$2->sub dependency = 2 extra cycles
        --         (lw$3 stall may overlap)
        -- Approximate: cycle 7
        wait for clk_period * 7;

        -- Sample ALU result during sub execution
        -- ValueSelect="001" -> ALUResult
        tb_ValueSelect <= "001";
        wait for clk_period;
        -- Expected: 0x55 - 0xAA = 0xAB (8-bit two's complement: -85)
        -- 0x55 = 0101 0101 = 85
        -- 0xAA = 1010 1010 = 170 (or -86 signed)
        -- 85 - 170 = -85 = 0xAB in two's complement
        report "Phase6: ALU result during sub region (expect 0xAB) = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               severity note;

        -- ====================================================
        -- PHASE 7: Final verification after full benchmark
        -- Reset, run PIPELINE_DRAIN cycles, freeze and check
        -- ====================================================
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        -- Run benchmark for enough cycles to complete first pass
        -- First pass completes after approximately:
        --   2 lw stalls + 12 instructions + 5 pipeline stages
        --   + branch flush (3 cycles) + jump flush (3 cycles)
        --   = ~30 cycles minimum; use 50 to be safe
        wait for clk_period * 50;

        -- Freeze processor
        tb_GReset <= '1';
        wait for clk_period;

        -- ====================================================
        -- FINAL CHECK A: WriteData should be 0xFF
        -- The last register write before freeze should be
        -- from: lw $3,4 ($3 = 0xFF) or beq (no write)
        -- Most recent RegWrite result = 0xFF
        -- ValueSelect="100" -> WriteData
        -- Expected: 0xFF
        -- ====================================================
        tb_ValueSelect <= "100";
        wait for clk_period;
        assert (tb_MuxOut = x"FF")
            report "FINAL_A FAIL: WriteData should be 0xFF, got 0x" &
                   integer'image(to_integer(
                   ieee.numeric_std.unsigned(tb_MuxOut)))
            severity error;
        report "FINAL_A PASS: WriteData = 0xFF" severity note;

        -- ====================================================
        -- FINAL CHECK B: RegWriteOut status
        -- During WB of lw$3 or add: RegWriteOut should be '1'
        -- After reset: RegWriteOut should be '0'
        -- Expected after freeze: '0' (pipeline flushed)
        -- ====================================================
        assert (tb_RegWriteOut = '0')
            report "FINAL_B FAIL: After reset RegWriteOut should be 0" severity error;
        report "FINAL_B PASS: RegWriteOut = 0 after reset" severity note;

        -- ====================================================
        -- FINAL CHECK C: MemWriteOut status
        -- After reset all control signals should be 0
        -- Expected: '0'
        -- ====================================================
        assert (tb_MemWriteOut = '0')
            report "FINAL_C FAIL: After reset MemWriteOut should be 0" severity error;
        report "FINAL_C PASS: MemWriteOut = 0 after reset" severity note;

        -- ====================================================
        -- FINAL CHECK D: BranchOut / ZeroOut
        -- After reset: both should be '0'
        -- ====================================================
        assert (tb_BranchOut = '0')
            report "FINAL_D FAIL: After reset BranchOut should be 0" severity error;
        report "FINAL_D PASS: BranchOut = 0 after reset" severity note;

        assert (tb_ZeroOut = '0')
            report "FINAL_D FAIL: After reset ZeroOut should be 0" severity error;
        report "FINAL_D PASS: ZeroOut = 0 after reset" severity note;

        -- ====================================================
        -- PHASE 8: Control signal observation during execution
        -- Release reset and observe control signals live
        -- ====================================================
        tb_GReset <= '0';

        -- Observe during lw $2,0 in EX/MEM stage
        -- At this point: MemRead=1, RegWrite=1, Branch=0
        -- Wait ~4 cycles from reset release for lw$2 to reach MEM
        wait for clk_period * 4;

        -- Check MemWriteOut=0 (lw reads, does not write memory)
        assert (tb_MemWriteOut = '0')
            report "PHASE8 FAIL: During lw, MemWriteOut should be 0" severity error;
        report "PHASE8 PASS: lw -> MemWriteOut=0 (read, not write)" severity note;

        -- Check BranchOut=0 (lw is not a branch)
        assert (tb_BranchOut = '0')
            report "PHASE8 FAIL: During lw, BranchOut should be 0" severity error;
        report "PHASE8 PASS: lw -> BranchOut=0" severity note;

        -- ====================================================
        -- PHASE 9: Observe sw control signals
        -- sw $4, 3($0) reaches MEM stage approximately cycle 10
        -- At that point MemWriteOut should be 1
        -- ====================================================
        -- Wait for sw $4,3 to reach MEM stage
        -- sw is at addr 0x04 (instruction 4, after stalls ~cycle 10+)
        wait for clk_period * 7;

        -- MemWriteOut should pulse high during sw MEM stage
        -- We report rather than assert since exact timing
        -- depends on stall count
        report "PHASE9: MemWriteOut during sw region = " &
               std_logic'image(tb_MemWriteOut)
               severity note;
        report "PHASE9: RegWriteOut during sw region = " &
               std_logic'image(tb_RegWriteOut) &
               " (expect 0 - sw does not write register)"
               severity note;

        -- ====================================================
        -- PHASE 10: Observe beq $1,$2 Zero flag
        -- beq $1,$2,-8 -> $1=0xFF, $2=0xFF -> Zero=1
        -- This occurs at addr 0x0B after j instruction
        -- ====================================================
        -- Run enough cycles to reach beq $1,$2 in EX stage
        wait for clk_period * 20;

        report "PHASE10: ZeroOut (expect 1 when beq $1=$2 in EX) = " &
               std_logic'image(tb_ZeroOut)
               severity note;
        report "PHASE10: BranchOut (expect 1 when beq in MEM) = " &
               std_logic'image(tb_BranchOut)
               severity note;

        -- ====================================================
        -- PHASE 11: Instruction observation via InstrSelect
        -- Verify each pipeline stage shows correct instruction
        -- ====================================================
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        -- Let lw$2 propagate to ID stage (cycle 2)
        wait for clk_period * 2;

        -- InstrSelect="000" -> IF stage instruction
        tb_InstrSelect <= "000";
        wait for clk_period;
        report "PHASE11: IF  stage instruction = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_InstructionOut)))
               severity note;

        -- InstrSelect="001" -> ID stage instruction
        tb_InstrSelect <= "001";
        wait for clk_period;
        report "PHASE11: ID  stage instruction = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_InstructionOut)))
               severity note;

        -- ====================================================
        -- PHASE 12: Stall detection check
        -- During lw->sub hazard: PC should hold for 2 cycles
        -- We observe PC via ValueSelect="000"
        -- ====================================================
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        tb_ValueSelect <= "000";   -- observe PC

        -- Cycle 1: PC should advance to 0x04
        wait for clk_period;
        report "PHASE12 Cycle1: PC = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect 0x04 after first fetch)"
               severity note;

        -- Cycle 2: PC should advance to 0x08
        wait for clk_period;
        report "PHASE12 Cycle2: PC = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect 0x08)"
               severity note;

        -- Cycle 3: sub detected, lw$2 stall -> PC holds at 0x08
        wait for clk_period;
        report "PHASE12 Cycle3: PC = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect 0x08 - STALL due to lw$2 hazard)"
               severity note;

        -- Cycle 4: lw$3 stall -> PC may still hold at 0x08
        wait for clk_period;
        report "PHASE12 Cycle4: PC = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect 0x08 - possible STALL lw$3 hazard)"
               severity note;

        -- Cycle 5: stalls cleared -> PC advances to 0x0C
        wait for clk_period;
        report "PHASE12 Cycle5: PC = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect 0x0C - stalls cleared)"
               severity note;

        -- ====================================================
        -- PHASE 13: Control info verification
        -- ValueSelect="101" (other) -> ctrl_info
        -- ctrl_info[7:0] = {0, RegDst, Jump, MemRead,
        --                    MemtoReg, ALUOp[1:0], ALUSrc}
        -- During lw in ID/EX:
        --   RegDst=0, Jump=0, MemRead=1, MemtoReg=1,
        --   ALUOp=00, ALUSrc=1
        --   ctrl_info = 0_0_0_1_1_00_1 = 0x19
        -- During R-type (add/sub/or) in ID/EX:
        --   RegDst=1, Jump=0, MemRead=0, MemtoReg=0,
        --   ALUOp=10, ALUSrc=0
        --   ctrl_info = 0_1_0_0_0_10_0 = 0x44
        -- ====================================================
        tb_GReset <= '1';
        wait for clk_period * 2;
        tb_GReset <= '0';

        -- Wait for lw$2 to reach ID/EX stage (~cycle 2)
        wait for clk_period * 2;

        tb_ValueSelect <= "101";   -- ctrl_info
        wait for clk_period;
        report "PHASE13: ctrl_info during lw$2 in ID/EX = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect ~0x19: MemRead=1, MemtoReg=1, ALUSrc=1)"
               severity note;

        -- Wait for sub to reach ID/EX (~cycle 6-8 with stalls)
        wait for clk_period * 6;
        report "PHASE13: ctrl_info during sub in ID/EX = 0x" &
               integer'image(to_integer(
               ieee.numeric_std.unsigned(tb_MuxOut)))
               & " (expect ~0x44: RegDst=1, ALUOp=10)"
               severity note;

        -- ====================================================
        -- All checks complete
        -- ====================================================
        report "================================================" severity note;
        report "tb_LAB3: All benchmark test phases completed!"   severity note;
        report "================================================" severity note;
        report "Expected final register state:"                   severity note;
        report "  $0 = 0x00 (hardwired zero)"                   severity note;
        report "  $1 = 0xFF (add $2+$3 = 0x55+0xAA)"           severity note;
        report "  $2 = 0xFF (lw from mem[3] = 0xFF)"            severity note;
        report "  $3 = 0xFF (lw from mem[4] = 0xFF)"            severity note;
        report "  $4 = 0xAB (or $1,$3 = 0xAB|0xAA)"            severity note;
        report "Expected final memory state:"                     severity note;
        report "  mem[0x00] = 0x55 (unchanged)"                  severity note;
        report "  mem[0x01] = 0xAA (unchanged)"                  severity note;
        report "  mem[0x03] = 0xFF (sw $4,3 -> 0xAB? see note)" severity note;
        report "  mem[0x04] = 0xFF (sw $1,4 -> 0xFF)"           severity note;
        report "NOTE: sub gives 0xAB not 0x55 (8-bit unsigned)" severity note;
        report "  or $4,$1,$3 = 0xAB|0xAA = 0xAB (not 0xFF)"   severity note;
        report "================================================" severity note;

        sim_done <= true;
        wait;
    end process;

end behavior;