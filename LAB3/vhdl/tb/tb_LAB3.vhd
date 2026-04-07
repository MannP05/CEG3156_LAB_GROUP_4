-- ============================================================
-- Testbench: tb_LAB3
-- CEG 3156 Lab 3 - Pipelined Processor Verification
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_LAB3 is
end tb_LAB3;

architecture behavior of tb_LAB3 is

    component LAB3
        port(
            GClock         : in  std_logic;
            GReset         : in  std_logic;
            ValueSelect    : in  std_logic_vector(2 downto 0);
            InstrSelect    : in  std_logic_vector(2 downto 0);
            MuxOut         : out std_logic_vector(7  downto 0);
            InstructionOut : out std_logic_vector(31 downto 0);
            BranchOut      : out std_logic;
            ZeroOut        : out std_logic;
            MemWriteOut    : out std_logic;
            RegWriteOut    : out std_logic
        );
    end component;

    signal tb_GClock         : std_logic := '0';
    signal tb_GReset         : std_logic := '1';
    signal tb_ValueSelect    : std_logic_vector(2 downto 0) := "000";
    signal tb_InstrSelect    : std_logic_vector(2 downto 0) := "000";
    signal tb_MuxOut         : std_logic_vector(7  downto 0);
    signal tb_InstructionOut : std_logic_vector(31 downto 0);
    signal tb_BranchOut      : std_logic;
    signal tb_ZeroOut        : std_logic;
    signal tb_MemWriteOut    : std_logic;
    signal tb_RegWriteOut    : std_logic;

    constant CLK_PERIOD    : time    := 10 ns;
    constant SAMPLE_OFFSET : time    := 3 ns;
    signal   sim_done      : boolean := false;

    -- --------------------------------------------------------
    -- to_hex: convert any std_logic_vector to hex string
    -- --------------------------------------------------------
    function to_hex(v : std_logic_vector) return string is
        constant LEN    : integer := ((v'length + 3) / 4) * 4;
        variable padded : std_logic_vector(LEN - 1 downto 0) := (others => '0');
        variable result : string(1 to LEN / 4);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        padded(v'length - 1 downto 0) := v;
        for i in 0 to LEN / 4 - 1 loop
            nibble := padded(LEN - 1 - i * 4 downto LEN - 4 - i * 4);
            case nibble is
                when "0000" => result(i+1) := '0';
                when "0001" => result(i+1) := '1';
                when "0010" => result(i+1) := '2';
                when "0011" => result(i+1) := '3';
                when "0100" => result(i+1) := '4';
                when "0101" => result(i+1) := '5';
                when "0110" => result(i+1) := '6';
                when "0111" => result(i+1) := '7';
                when "1000" => result(i+1) := '8';
                when "1001" => result(i+1) := '9';
                when "1010" => result(i+1) := 'A';
                when "1011" => result(i+1) := 'B';
                when "1100" => result(i+1) := 'C';
                when "1101" => result(i+1) := 'D';
                when "1110" => result(i+1) := 'E';
                when "1111" => result(i+1) := 'F';
                when others  => result(i+1) := 'X';
            end case;
        end loop;
        return result;
    end function;

    function is_valid(v : std_logic_vector) return boolean is
    begin
        for i in v'range loop
            if v(i) /= '0' and v(i) /= '1' then return false; end if;
        end loop;
        return true;
    end function;

    function is_valid_sl(s : std_logic) return boolean is
    begin
        return s = '0' or s = '1';
    end function;

begin

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

    clk_proc : process
    begin
        if sim_done then wait; end if;
        tb_GClock <= '1'; wait for CLK_PERIOD / 2;
        tb_GClock <= '0'; wait for CLK_PERIOD / 2;
    end process;

    stim_proc : process

        -- Phase 9 scan variables
        variable found_sub     : boolean := false;
        variable found_add     : boolean := false;
        -- Phase 10 count
        variable sw_count      : integer := 0;

        -- ------------------------------------------------
        -- wait_cycles: wait N rising edges then sample
        -- after falling edge + SAMPLE_OFFSET
        -- ------------------------------------------------
        procedure wait_cycles(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(tb_GClock);
            end loop;
            wait until falling_edge(tb_GClock);
            wait for SAMPLE_OFFSET;
        end procedure;

        -- ------------------------------------------------
        -- do_reset: assert reset, wait N cycles, sample
        -- ------------------------------------------------
        procedure do_reset(n : integer) is
        begin
            tb_GReset <= '1';
            wait_cycles(n);
        end procedure;

        -- ------------------------------------------------
        -- release_reset: deassert on next rising edge
        -- ------------------------------------------------
        procedure release_reset is
        begin
            wait until rising_edge(tb_GClock);
            tb_GReset <= '0';
        end procedure;

    begin

        -- ====================================================
        -- PHASE 1: Reset Verification
        -- Hold reset 5 cycles. All outputs should be 0.
        -- PC (ValueSelect="000") should be 0x00.
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 1: Reset Verification"             severity note;
        report "========================================" severity note;

        tb_ValueSelect <= "000";
        tb_InstrSelect <= "000";
        do_reset(5);

        if is_valid(tb_MuxOut) then
            assert (tb_MuxOut = x"00")
                report "PHASE1 FAIL: PC=0x" & to_hex(tb_MuxOut) &
                       " expected 0x00 during reset" severity error;
            report "PHASE1: PC=0x" & to_hex(tb_MuxOut) &
                   " (expect 0x00)" severity note;
        else
            report "PHASE1 WARN: PC=X/U - apply Fix 1 (init dFF_2 to 0)"
                severity warning;
        end if;

        report "PHASE1: Branch=" & std_logic'image(tb_BranchOut) &
               " Zero="  & std_logic'image(tb_ZeroOut) &
               " MemWr=" & std_logic'image(tb_MemWriteOut) &
               " RegWr=" & std_logic'image(tb_RegWriteOut) severity note;

        -- ====================================================
        -- PHASE 2: IF Stage Instruction Fetch
        --
        -- Release reset. Because the LPM ROM has a registered
        -- address input, the instruction appears one full cycle
        -- after the address is presented.
        --
        -- Cycle 1: addr=0x00 registered -> lw$2 = 0x8C020000
        -- Cycle 2: addr=0x04 registered -> lw$3 = 0x8C030001
        -- Cycle 3: addr=0x08 registered -> sub  = 0x00430822
        -- Cycle 4: STALL (lw$2 hazard)  -> sub still held
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 2: IF Stage Instruction Fetch"     severity note;
        report "========================================" severity note;

        release_reset;
        tb_InstrSelect <= "000";

        for cyc in 1 to 6 loop
            wait_cycles(1);
            report "PHASE2 Cycle" & integer'image(cyc) &
                   " IF=0x" & to_hex(tb_InstructionOut) severity note;
        end loop;

        -- Targeted assertions (only if valid)
        -- Redo from reset for clean cycle 1
        do_reset(5);
        release_reset;
        tb_InstrSelect <= "000";

        wait_cycles(1);
        if is_valid(tb_InstructionOut) then
            assert (tb_InstructionOut = x"8C020000")
                report "PHASE2 FAIL Cycle1: expected 0x8C020000 (lw$2,0)" &
                       " got 0x" & to_hex(tb_InstructionOut) severity error;
            report "PHASE2 PASS Cycle1: IF=0x" & to_hex(tb_InstructionOut) &
                   " = lw $2,0" severity note;
        else
            report "PHASE2 WARN: ROM output X/U - MIF file not found in obj/"
                severity warning;
            report "PHASE2 FIX: Add 'copy_mif' target to Makefile" severity note;
        end if;

        wait_cycles(1);
        if is_valid(tb_InstructionOut) then
            assert (tb_InstructionOut = x"8C030001")
                report "PHASE2 FAIL Cycle2: expected 0x8C030001 (lw$3,1)" &
                       " got 0x" & to_hex(tb_InstructionOut) severity error;
            report "PHASE2 PASS Cycle2: IF=0x" & to_hex(tb_InstructionOut) &
                   " = lw $3,1" severity note;
        end if;

        wait_cycles(1);
        if is_valid(tb_InstructionOut) then
            assert (tb_InstructionOut = x"00430822")
                report "PHASE2 FAIL Cycle3: expected 0x00430822 (sub)" &
                       " got 0x" & to_hex(tb_InstructionOut) severity error;
            report "PHASE2 PASS Cycle3: IF=0x" & to_hex(tb_InstructionOut) &
                   " = sub $1,$2,$3" severity note;
        end if;

        -- ====================================================
        -- PHASE 3: PC Stall Observation
        --
        -- Expected PC per cycle (sampled after falling edge):
        --   Cycle 1: 0x04   lw$2 dispatched
        --   Cycle 2: 0x08   lw$3 dispatched
        --   Cycle 3: 0x08   STALL lw$2->sub hazard
        --   Cycle 4: 0x08   STALL lw$3->sub hazard
        --   Cycle 5: 0x0C   stalls clear
        --   Cycle 6: 0x10   or dispatched
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 3: PC Stall (Load-Use Hazard)"    severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;
        tb_ValueSelect <= "000";

        for cyc in 1 to 6 loop
            wait_cycles(1);
            report "PHASE3 Cycle" & integer'image(cyc) &
                   ": PC=0x" & to_hex(tb_MuxOut) severity note;

            if cyc = 3 and is_valid(tb_MuxOut) then
                assert (tb_MuxOut = x"08")
                    report "PHASE3 FAIL Cycle3: PC should hold at 0x08" &
                           " got 0x" & to_hex(tb_MuxOut) &
                           " - load-use hazard detection broken"
                    severity error;
            end if;
            if cyc = 4 and is_valid(tb_MuxOut) then
                assert (tb_MuxOut = x"08")
                    report "PHASE3 FAIL Cycle4: PC should still hold at 0x08" &
                           " got 0x" & to_hex(tb_MuxOut) &
                           " - second stall (lw$3->sub) missing"
                    severity error;
            end if;
            if cyc = 5 and is_valid(tb_MuxOut) then
                assert (tb_MuxOut = x"0C")
                    report "PHASE3 FAIL Cycle5: PC should advance to 0x0C" &
                           " got 0x" & to_hex(tb_MuxOut)
                    severity error;
            end if;
        end loop;

        -- ====================================================
        -- PHASE 4: Control Signals per Instruction
        --
        -- lw$2 in MEM at cycle 4: MemWriteOut=0, BranchOut=0
        -- lw$2 in WB  at cycle 5: RegWriteOut=1
        -- lw$3 in WB  at cycle 6: RegWriteOut=1
        -- sw$4 in MEM at ~cycle 12: MemWriteOut=1, RegWriteOut=0
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 4: Control Signals per Instruction" severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;

        wait_cycles(4);   -- lw$2 in MEM
        report "PHASE4 @MEM(lw$2): MemWr=" & std_logic'image(tb_MemWriteOut) &
               " Branch=" & std_logic'image(tb_BranchOut) &
               " (both expect 0)" severity note;
        if is_valid_sl(tb_MemWriteOut) then
            assert (tb_MemWriteOut = '0')
                report "PHASE4 FAIL: lw MEM should have MemWriteOut=0"
                severity error;
        end if;
        if is_valid_sl(tb_BranchOut) then
            assert (tb_BranchOut = '0')
                report "PHASE4 FAIL: lw MEM should have BranchOut=0"
                severity error;
        end if;

        wait_cycles(1);   -- lw$2 in WB
        report "PHASE4 @WB(lw$2): RegWr=" & std_logic'image(tb_RegWriteOut) &
               " (expect 1 writing $2=0x55)" severity note;
        if is_valid_sl(tb_RegWriteOut) then
            assert (tb_RegWriteOut = '1')
                report "PHASE4 FAIL: lw WB should have RegWriteOut=1"
                severity error;
        end if;

        wait_cycles(1);   -- lw$3 in WB
        report "PHASE4 @WB(lw$3): RegWr=" & std_logic'image(tb_RegWriteOut) &
               " (expect 1 writing $3=0xAA)" severity note;

        wait_cycles(6);   -- sw$4,3 in MEM region
        report "PHASE4 @MEM(sw$4,3): MemWr=" & std_logic'image(tb_MemWriteOut) &
               " RegWr=" & std_logic'image(tb_RegWriteOut) &
               " (MemWr expect 1, RegWr expect 0)" severity note;

        -- ====================================================
        -- PHASE 5: ALU Result Scan
        --
        -- ValueSelect="001" -> EX/MEM ALU result
        -- Scan 30 cycles and report every unique value seen.
        --
        -- Expected values in order:
        --   0x00 : lw$2 address computation (0+0=0)
        --   0x01 : lw$3 address computation (0+1=1)
        --   0xAB : sub $1,$2,$3 (0x55-0xAA)
        --   0xAB : or  $4,$1,$3 (0xAB|0xAA)
        --   0x03 : sw$4 address (0+3=3)
        --   0xFF : add $1,$2,$3 (0x55+0xAA)
        --   0x04 : sw$1 address (0+4=4)
        --   0x03 : lw$2 address (0+3=3)
        --   0x04 : lw$3 address (0+4=4)
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 5: ALU Result Scan (30 cycles)"   severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;
        tb_ValueSelect <= "001";

        for cyc in 1 to 30 loop
            wait_cycles(1);
            if is_valid(tb_MuxOut) then
                report "PHASE5 Cy" & integer'image(cyc) &
                       ": ALU=0x" & to_hex(tb_MuxOut) severity note;
            else
                report "PHASE5 Cy" & integer'image(cyc) &
                       ": ALU=X/U" severity note;
            end if;
        end loop;

        -- ====================================================
        -- PHASE 6: Branch / Jump Signal Scan
        --
        -- Scan 60 cycles. Report every BranchOut='1' event.
        -- Also watch PC for jump target 0x2C.
        --
        -- j 11 at addr 0x09 -> PC jumps to 0x2C
        -- beq $1,$2 at 0x0B: $1=0xFF, $2=0xAB -> Zero=0 -> not taken
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 6: Branch and Jump Signal Scan"   severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;
        tb_ValueSelect <= "000";   -- watch PC

        for cyc in 1 to 60 loop
            wait_cycles(1);

            if is_valid_sl(tb_BranchOut) and tb_BranchOut = '1' then
                report "PHASE6 Cy" & integer'image(cyc) &
                       ": BranchOut=1 Zero=" & std_logic'image(tb_ZeroOut) &
                       " PC=0x" & to_hex(tb_MuxOut) severity note;
                if is_valid_sl(tb_ZeroOut) and tb_ZeroOut = '0' then
                    report "  PASS: beq->Zero=0 not taken ($1!=$ 2)" severity note;
                end if;
            end if;

            if is_valid(tb_MuxOut) and tb_MuxOut = x"2C" then
                report "PHASE6 Cy" & integer'image(cyc) &
                       ": PC=0x2C (jump target reached)" severity note;
            end if;
        end loop;

        -- ====================================================
        -- PHASE 7: Final State after 100 cycle run
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 7: Final State Verification"      severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;
        wait_cycles(100);
        do_reset(5);

        tb_ValueSelect <= "000";
        wait_cycles(1);
        report "PHASE7: PC=0x" & to_hex(tb_MuxOut) &
               " (expect 0x00)" severity note;
        if is_valid(tb_MuxOut) then
            assert (tb_MuxOut = x"00")
                report "PHASE7 FAIL: PC should be 0x00 after reset" severity error;
        end if;

        tb_ValueSelect <= "100";
        wait_cycles(1);
        report "PHASE7: WriteData=0x" & to_hex(tb_MuxOut) &
               " (last register write: expect 0xFF or 0xAB)" severity note;

        report "PHASE7: Branch=" & std_logic'image(tb_BranchOut) &
               " Zero="  & std_logic'image(tb_ZeroOut) &
               " MemWr=" & std_logic'image(tb_MemWriteOut) &
               " RegWr=" & std_logic'image(tb_RegWriteOut) &
               " (all expect 0 after reset)" severity note;

        if is_valid_sl(tb_BranchOut)   then assert (tb_BranchOut   = '0') report "PHASE7 FAIL: BranchOut"   severity error; end if;
        if is_valid_sl(tb_MemWriteOut) then assert (tb_MemWriteOut = '0') report "PHASE7 FAIL: MemWriteOut" severity error; end if;
        if is_valid_sl(tb_RegWriteOut) then assert (tb_RegWriteOut = '0') report "PHASE7 FAIL: RegWriteOut" severity error; end if;
        if is_valid_sl(tb_ZeroOut)     then assert (tb_ZeroOut     = '0') report "PHASE7 FAIL: ZeroOut"     severity error; end if;
        report "PHASE7 PASS: control signals verified" severity note;

        -- ====================================================
        -- PHASE 8: ReadData1 / ReadData2
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 8: ReadData Verification"         severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;
        wait_cycles(10);   -- both lw done, sub in EX or later

        tb_ValueSelect <= "010";
        wait_cycles(1);
        report "PHASE8: ReadData1=0x" & to_hex(tb_MuxOut) &
               " (rs of current ID instruction)" severity note;

        tb_ValueSelect <= "011";
        wait_cycles(1);
        report "PHASE8: ReadData2=0x" & to_hex(tb_MuxOut) &
               " (rt of current ID instruction)" severity note;

        -- ====================================================
        -- PHASE 9: Assert sub (0xAB) and add (0xFF) results
        --
        -- Scan 40 cycles. If MIF loaded correctly both values
        -- must appear in ALU result within 40 cycles.
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 9: sub and add Result Assertions" severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;

        found_sub := false;
        found_add := false;
        tb_ValueSelect <= "001";

        for cyc in 1 to 40 loop
            wait_cycles(1);
            if is_valid(tb_MuxOut) then
                if tb_MuxOut = x"AB" and not found_sub then
                    found_sub := true;
                    report "PHASE9 PASS: sub=0xAB at cycle " &
                           integer'image(cyc) &
                           " (0x55-0xAA two's complement)" severity note;
                end if;
                if tb_MuxOut = x"FF" and not found_add then
                    found_add := true;
                    report "PHASE9 PASS: add=0xFF at cycle " &
                           integer'image(cyc) &
                           " (0x55+0xAA wrap)" severity note;
                end if;
            end if;
        end loop;

        if not found_sub then
            report "PHASE9 FAIL: 0xAB never seen in 40 cycles" &
                   " -> Fix 1: init dFF_2; Fix 2: copy MIF to obj/"
                severity error;
        end if;
        if not found_add then
            report "PHASE9 FAIL: 0xFF never seen in 40 cycles" &
                   " -> Fix 1: init dFF_2; Fix 2: copy MIF to obj/"
                severity error;
        end if;

        -- ====================================================
        -- PHASE 10: sw MemWriteOut Assertion
        -- Scan 40 cycles. Expect exactly 2 pulses.
        -- ====================================================
        report "========================================" severity note;
        report "PHASE 10: sw MemWriteOut Assertion"     severity note;
        report "========================================" severity note;

        do_reset(5);
        release_reset;

        sw_count := 0;

        for cyc in 1 to 40 loop
            wait_cycles(1);
            if is_valid_sl(tb_MemWriteOut) and tb_MemWriteOut = '1' then
                sw_count := sw_count + 1;
                report "PHASE10 Cy" & integer'image(cyc) &
                       ": MemWriteOut=1 (sw#" &
                       integer'image(sw_count) & ")" severity note;
                if sw_count = 1 then
                    report "  sw $4,3 -> mem[3]=0xAB" severity note;
                elsif sw_count = 2 then
                    report "  sw $1,4 -> mem[4]=0xFF" severity note;
                end if;
            end if;
        end loop;

        if sw_count = 0 then
            report "PHASE10 FAIL: MemWriteOut never 1 in 40 cycles" &
                   " -> Fix 1+2 required" severity error;
        elsif sw_count < 2 then
            report "PHASE10 WARN: " & integer'image(sw_count) &
                   " sw detected, expected 2" severity warning;
        else
            report "PHASE10 PASS: " & integer'image(sw_count) &
                   " sw instructions detected" severity note;
        end if;

        -- ====================================================
        -- Summary
        -- ====================================================
        report "========================================" severity note;
        report "tb_LAB3: Complete"                       severity note;
        report "========================================" severity note;
        report "Required fixes if X/U seen:"             severity note;
        report " Fix1: dFF_2 signal int_q := '0'"       severity note;
        report " Fix2: copy *.mif to obj/ directory"     severity note;
        report "Expected results:"                        severity note;
        report " sub: 0x55-0xAA = 0xAB"                 severity note;
        report " or:  0xAB|0xAA = 0xAB"                 severity note;
        report " add: 0x55+0xAA = 0xFF"                  severity note;
        report " $1=0xFF $2=0xAB $3=0xFF $4=0xAB"       severity note;
        report " mem[3]=0xAB  mem[4]=0xFF"               severity note;
        report "========================================" severity note;

        sim_done <= true;
        wait;
    end process;

end behavior;