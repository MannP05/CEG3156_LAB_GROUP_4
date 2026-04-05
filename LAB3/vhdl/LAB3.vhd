-- ============================================================
-- CEG 3156 Lab 3 - Pipelined RISC Processor
--
-- 5-Stage Pipeline: IF -> ID -> EX -> MEM -> WB
-- Features:
--   - Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
--   - Forwarding unit  : resolves data hazards
--   - Hazard detection : resolves load-use hazards (stall)
--   - Branch resolution: flushes pipeline on taken branch
--
-- 8-bit datapath, 32-bit instructions, 8 x 8-bit registers
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LAB3 IS
    PORT(
        GClock         : IN  STD_LOGIC;
        GReset         : IN  STD_LOGIC;
        ValueSelect    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        InstrSelect    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        MuxOut         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        InstructionOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        BranchOut      : OUT STD_LOGIC;
        ZeroOut        : OUT STD_LOGIC;
        MemWriteOut    : OUT STD_LOGIC;
        RegWriteOut    : OUT STD_LOGIC
    );
END LAB3;

ARCHITECTURE structural OF LAB3 IS

    -- ==========================================================
    -- COMPONENT DECLARATIONS
    -- ==========================================================

    COMPONENT pc_reg IS
        PORT(
            i_clock : IN  STD_LOGIC;
            i_reset : IN  STD_LOGIC;
            i_d     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_q     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT nBitAddSubUnit IS
        GENERIC(n : INTEGER := 8);
        PORT(
            i_A        : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            i_Bi       : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            i_OpFlag   : IN  STD_LOGIC;
            o_CarryOut : OUT STD_LOGIC;
            o_Sum      : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT instruction_memory IS
        PORT(
            address : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            clock   : IN  STD_LOGIC;
            q       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Control_Unit IS
        PORT(
            opcode   : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
            RegDst   : OUT STD_LOGIC;
            ALUSrc   : OUT STD_LOGIC;
            MemtoReg : OUT STD_LOGIC;
            RegWrite : OUT STD_LOGIC;
            MemRead  : OUT STD_LOGIC;
            MemWrite : OUT STD_LOGIC;
            Branch   : OUT STD_LOGIC;
            Jump     : OUT STD_LOGIC;
            ALUOp    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT nBitMux2to1 IS
        GENERIC(n : INTEGER := 4);
        PORT(
            i_sel      : IN  STD_LOGIC;
            i_d0, i_d1 : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            o_q        : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT register_file IS
        PORT(
            clock      : IN  STD_LOGIC;
            reset      : IN  STD_LOGIC;
            RegWrite   : IN  STD_LOGIC;
            read_reg1  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            read_reg2  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            write_reg  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            write_data : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            read_data1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            read_data2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT sign_extended IS
        PORT(
            i : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            o : OUT STD_LOGIC_VECTOR(7  DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT ALU_control IS
        PORT(
            ALU_Op    : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            funct     : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
            Operation : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT nbit_ALU IS
        GENERIC(n : INTEGER := 8);
        PORT(
            i_A          : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            i_B          : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            i_ALUControl : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_ALUResult  : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            o_Zero       : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT data_memory IS
        PORT(
            address : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            clock   : IN  STD_LOGIC;
            data    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            wren    : IN  STD_LOGIC;
            q       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT nBitMux4to1 IS
        GENERIC(n : INTEGER := 4);
        PORT(
            s0, s1          : IN  STD_LOGIC;
            x0, x1, x2, x3 : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            y               : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT IFID_reg IS
        PORT(
            i_clock       : IN  STD_LOGIC;
            i_reset       : IN  STD_LOGIC;
            i_flush       : IN  STD_LOGIC;
            i_stall       : IN  STD_LOGIC;
            i_PC4         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_instruction : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            o_PC4         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_instruction : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT IDEX_reg IS
        PORT(
            i_clock      : IN  STD_LOGIC;
            i_reset      : IN  STD_LOGIC;
            i_flush      : IN  STD_LOGIC;
            i_RegDst     : IN  STD_LOGIC;
            i_ALUSrc     : IN  STD_LOGIC;
            i_MemtoReg   : IN  STD_LOGIC;
            i_RegWrite   : IN  STD_LOGIC;
            i_MemRead    : IN  STD_LOGIC;
            i_MemWrite   : IN  STD_LOGIC;
            i_Branch     : IN  STD_LOGIC;
            i_Jump       : IN  STD_LOGIC;
            i_ALUOp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            i_PC4        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_ReadData1  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_ReadData2  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_SignExt    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_rs         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            i_rt         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            i_rd         : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            i_funct      : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
            o_RegDst     : OUT STD_LOGIC;
            o_ALUSrc     : OUT STD_LOGIC;
            o_MemtoReg   : OUT STD_LOGIC;
            o_RegWrite   : OUT STD_LOGIC;
            o_MemRead    : OUT STD_LOGIC;
            o_MemWrite   : OUT STD_LOGIC;
            o_Branch     : OUT STD_LOGIC;
            o_Jump       : OUT STD_LOGIC;
            o_ALUOp      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            o_PC4        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_ReadData1  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_ReadData2  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_SignExt    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_rs         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_rt         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_rd         : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_funct      : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT EXMEM_reg IS
        PORT(
            i_clock        : IN  STD_LOGIC;
            i_reset        : IN  STD_LOGIC;
            i_flush        : IN  STD_LOGIC;
            i_MemtoReg     : IN  STD_LOGIC;
            i_RegWrite     : IN  STD_LOGIC;
            i_MemRead      : IN  STD_LOGIC;
            i_MemWrite     : IN  STD_LOGIC;
            i_Branch       : IN  STD_LOGIC;
            i_Jump         : IN  STD_LOGIC;
            i_BranchTarget : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_JumpAddr     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_Zero         : IN  STD_LOGIC;
            i_ALUResult    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_ReadData2    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_WriteReg     : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_MemtoReg     : OUT STD_LOGIC;
            o_RegWrite     : OUT STD_LOGIC;
            o_MemRead      : OUT STD_LOGIC;
            o_MemWrite     : OUT STD_LOGIC;
            o_Branch       : OUT STD_LOGIC;
            o_Jump         : OUT STD_LOGIC;
            o_BranchTarget : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_JumpAddr     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_Zero         : OUT STD_LOGIC;
            o_ALUResult    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_ReadData2    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_WriteReg     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT MEMWB_reg IS
        PORT(
            i_clock       : IN  STD_LOGIC;
            i_reset       : IN  STD_LOGIC;
            i_MemtoReg    : IN  STD_LOGIC;
            i_RegWrite    : IN  STD_LOGIC;
            i_MemReadData : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_ALUResult   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_WriteReg    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_MemtoReg    : OUT STD_LOGIC;
            o_RegWrite    : OUT STD_LOGIC;
            o_MemReadData : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_ALUResult   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_WriteReg    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT hazard_detection_unit IS
        PORT(
            IDEX_MemRead  : IN  STD_LOGIC;
            IDEX_rt       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            IFID_rs       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            IFID_rt       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            PCWrite       : OUT STD_LOGIC;
            IFID_Write    : OUT STD_LOGIC;
            ctrl_flush    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT forwarding_unit IS
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
    END COMPONENT;

    -- ==========================================================
    -- SIGNAL DECLARATIONS
    -- ==========================================================

    -- ---------- IF Stage ----------
    SIGNAL if_pc_current    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL if_pc_next       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL if_pc_plus4      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL if_instruction   : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL if_carry_pc4     : STD_LOGIC;
    SIGNAL if_pc_write      : STD_LOGIC;    -- from hazard unit

    -- Mux before PC register
    SIGNAL if_pc_branch_or_seq  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL if_pc_final          : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ---------- IF/ID Register outputs ----------
    SIGNAL ifid_pc4         : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ifid_instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ifid_stall       : STD_LOGIC;    -- from hazard unit (NOT PCWrite)
    SIGNAL ifid_flush       : STD_LOGIC;    -- branch taken flush

    -- ---------- ID Stage ----------
    SIGNAL id_ctrl_RegDst   : STD_LOGIC;
    SIGNAL id_ctrl_ALUSrc   : STD_LOGIC;
    SIGNAL id_ctrl_MemtoReg : STD_LOGIC;
    SIGNAL id_ctrl_RegWrite : STD_LOGIC;
    SIGNAL id_ctrl_MemRead  : STD_LOGIC;
    SIGNAL id_ctrl_MemWrite : STD_LOGIC;
    SIGNAL id_ctrl_Branch   : STD_LOGIC;
    SIGNAL id_ctrl_Jump     : STD_LOGIC;
    SIGNAL id_ctrl_ALUOp    : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL id_read_data1    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL id_read_data2    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL id_sign_ext      : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Hazard unit outputs
    SIGNAL haz_PCWrite      : STD_LOGIC;
    SIGNAL haz_IFIDWrite    : STD_LOGIC;
    SIGNAL haz_ctrl_flush   : STD_LOGIC;

    -- Control mux for stall (zero out controls on stall)
    SIGNAL id_ctrl_RegDst_s   : STD_LOGIC;
    SIGNAL id_ctrl_ALUSrc_s   : STD_LOGIC;
    SIGNAL id_ctrl_MemtoReg_s : STD_LOGIC;
    SIGNAL id_ctrl_RegWrite_s : STD_LOGIC;
    SIGNAL id_ctrl_MemRead_s  : STD_LOGIC;
    SIGNAL id_ctrl_MemWrite_s : STD_LOGIC;
    SIGNAL id_ctrl_Branch_s   : STD_LOGIC;
    SIGNAL id_ctrl_Jump_s     : STD_LOGIC;
    SIGNAL id_ctrl_ALUOp_s    : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- ---------- ID/EX Register outputs ----------
    SIGNAL idex_ctrl_RegDst   : STD_LOGIC;
    SIGNAL idex_ctrl_ALUSrc   : STD_LOGIC;
    SIGNAL idex_ctrl_MemtoReg : STD_LOGIC;
    SIGNAL idex_ctrl_RegWrite : STD_LOGIC;
    SIGNAL idex_ctrl_MemRead  : STD_LOGIC;
    SIGNAL idex_ctrl_MemWrite : STD_LOGIC;
    SIGNAL idex_ctrl_Branch   : STD_LOGIC;
    SIGNAL idex_ctrl_Jump     : STD_LOGIC;
    SIGNAL idex_ctrl_ALUOp    : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL idex_pc4           : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL idex_read_data1    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL idex_read_data2    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL idex_sign_ext      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL idex_rs            : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL idex_rt            : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL idex_rd            : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL idex_funct         : STD_LOGIC_VECTOR(5 DOWNTO 0);

    -- ---------- EX Stage ----------
    SIGNAL ex_alu_ctrl        : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ex_write_reg       : STD_LOGIC_VECTOR(2 DOWNTO 0);  -- RegDst mux output
    SIGNAL ex_fwd_a           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ex_fwd_b           : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ex_alu_a           : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- after forwarding mux A
    SIGNAL ex_alu_b_pre       : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- after forwarding mux B
    SIGNAL ex_alu_b           : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- after ALUSrc mux
    SIGNAL ex_alu_result      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ex_zero            : STD_LOGIC;
    SIGNAL ex_branch_offset   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ex_branch_target   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ex_jump_addr       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ex_carry_branch    : STD_LOGIC;

    -- WB data needed for forwarding mux in EX
    SIGNAL wb_write_data      : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ---------- EX/MEM Register outputs ----------
    SIGNAL exmem_ctrl_MemtoReg   : STD_LOGIC;
    SIGNAL exmem_ctrl_RegWrite   : STD_LOGIC;
    SIGNAL exmem_ctrl_MemRead    : STD_LOGIC;
    SIGNAL exmem_ctrl_MemWrite   : STD_LOGIC;
    SIGNAL exmem_ctrl_Branch     : STD_LOGIC;
    SIGNAL exmem_ctrl_Jump       : STD_LOGIC;
    SIGNAL exmem_branch_target   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL exmem_jump_addr       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL exmem_zero            : STD_LOGIC;
    SIGNAL exmem_alu_result      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL exmem_read_data2      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL exmem_write_reg       : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- ---------- MEM Stage ----------
    SIGNAL mem_read_data         : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_take_branch       : STD_LOGIC;
    SIGNAL mem_pc_branch_or_seq  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mem_notCLK            : STD_LOGIC;

    -- ---------- MEM/WB Register outputs ----------
    SIGNAL memwb_ctrl_MemtoReg  : STD_LOGIC;
    SIGNAL memwb_ctrl_RegWrite  : STD_LOGIC;
    SIGNAL memwb_mem_read_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL memwb_alu_result     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL memwb_write_reg      : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- ---------- PC stall mux ----------
    SIGNAL pc_held              : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ---------- Output mux signals ----------
    SIGNAL ctrl_info            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_01            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_23            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_45            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s2_0123          : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s2_4567          : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ---------- Instruction select mux ----------
    SIGNAL instr_zeros          : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL idex_instruction     : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL exmem_instruction    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL memwb_instruction    : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- ==========================================================
    -- IF STAGE: Instruction Fetch
    -- ==========================================================

    mem_notCLK <= NOT GClock;

    -- PC register with stall capability
    -- When stall: hold PC (feed back pc_current through mux)
    U_PC_HOLD_MUX : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => haz_PCWrite,     -- '1' = update, '0' = hold (active low enable)
            i_d0  => if_pc_current,   -- hold (sel=0 means stall, so keep current)
            i_d1  => if_pc_final,     -- normal next PC
            o_q   => pc_held
        );

    -- Note: haz_PCWrite = '1' means no hazard (normal), '0' means stall
    -- We invert logic: when PCWrite='0', feed pc_current back; when '1', feed pc_final
    -- The mux above: sel='1' => normal (pc_final), sel='0' => stall (pc_current)
    -- This is correct since PCWrite='1' = normal operation

    U_PC : pc_reg
        PORT MAP(
            i_clock => GClock,
            i_reset => GReset,
            i_d     => pc_held,
            o_q     => if_pc_current
        );

    U_PC_ADD : nBitAddSubUnit
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A        => if_pc_current,
            i_Bi       => x"04",
            i_OpFlag   => '0',
            o_CarryOut => if_carry_pc4,
            o_Sum      => if_pc_plus4
        );

    U_IMEM : instruction_memory
        PORT MAP(
            address => if_pc_current,
            clock   => GClock,
            q       => if_instruction
        );

    -- ==========================================================
    -- IF/ID PIPELINE REGISTER
    -- ==========================================================

    -- Flush IF/ID when branch is taken (resolved in MEM stage)
    ifid_flush <= mem_take_branch OR exmem_ctrl_Jump;
    ifid_stall <= NOT haz_IFIDWrite;   -- stall = hold register

    U_IFID : IFID_reg
        PORT MAP(
            i_clock       => GClock,
            i_reset       => GReset,
            i_flush       => ifid_flush,
            i_stall       => ifid_stall,
            i_PC4         => if_pc_plus4,
            i_instruction => if_instruction,
            o_PC4         => ifid_pc4,
            o_instruction => ifid_instruction
        );

    -- ==========================================================
    -- ID STAGE: Instruction Decode & Register File Read
    -- ==========================================================

    U_CTRL : Control_Unit
        PORT MAP(
            opcode   => ifid_instruction(31 DOWNTO 26),
            RegDst   => id_ctrl_RegDst,
            ALUSrc   => id_ctrl_ALUSrc,
            MemtoReg => id_ctrl_MemtoReg,
            RegWrite => id_ctrl_RegWrite,
            MemRead  => id_ctrl_MemRead,
            MemWrite => id_ctrl_MemWrite,
            Branch   => id_ctrl_Branch,
            Jump     => id_ctrl_Jump,
            ALUOp    => id_ctrl_ALUOp
        );

    -- Hazard Detection Unit
    U_HAZ : hazard_detection_unit
        PORT MAP(
            IDEX_MemRead  => idex_ctrl_MemRead,
            IDEX_rt       => idex_rt,
            IFID_rs       => ifid_instruction(23 DOWNTO 21),
            IFID_rt       => ifid_instruction(18 DOWNTO 16),
            PCWrite       => haz_PCWrite,
            IFID_Write    => haz_IFIDWrite,
            ctrl_flush    => haz_ctrl_flush
        );

    -- On stall: zero all control signals entering ID/EX (insert NOP bubble)
    id_ctrl_RegDst_s   <= id_ctrl_RegDst   AND (NOT haz_ctrl_flush);
    id_ctrl_ALUSrc_s   <= id_ctrl_ALUSrc   AND (NOT haz_ctrl_flush);
    id_ctrl_MemtoReg_s <= id_ctrl_MemtoReg AND (NOT haz_ctrl_flush);
    id_ctrl_RegWrite_s <= id_ctrl_RegWrite AND (NOT haz_ctrl_flush);
    id_ctrl_MemRead_s  <= id_ctrl_MemRead  AND (NOT haz_ctrl_flush);
    id_ctrl_MemWrite_s <= id_ctrl_MemWrite AND (NOT haz_ctrl_flush);
    id_ctrl_Branch_s   <= id_ctrl_Branch   AND (NOT haz_ctrl_flush);
    id_ctrl_Jump_s     <= id_ctrl_Jump     AND (NOT haz_ctrl_flush);
    id_ctrl_ALUOp_s(0) <= id_ctrl_ALUOp(0) AND (NOT haz_ctrl_flush);
    id_ctrl_ALUOp_s(1) <= id_ctrl_ALUOp(1) AND (NOT haz_ctrl_flush);

    U_REGFILE : register_file
        PORT MAP(
            clock      => GClock,
            reset      => GReset,
            RegWrite   => memwb_ctrl_RegWrite,
            read_reg1  => ifid_instruction(23 DOWNTO 21),
            read_reg2  => ifid_instruction(18 DOWNTO 16),
            write_reg  => memwb_write_reg,
            write_data => wb_write_data,
            read_data1 => id_read_data1,
            read_data2 => id_read_data2
        );

    U_SIGN_EXT : sign_extended
        PORT MAP(
            i => ifid_instruction(15 DOWNTO 0),
            o => id_sign_ext
        );

    -- ==========================================================
    -- ID/EX PIPELINE REGISTER
    -- ==========================================================

    U_IDEX : IDEX_reg
        PORT MAP(
            i_clock      => GClock,
            i_reset      => GReset,
            i_flush      => '0',           -- hazard flush handled by zeroing controls above
            i_RegDst     => id_ctrl_RegDst_s,
            i_ALUSrc     => id_ctrl_ALUSrc_s,
            i_MemtoReg   => id_ctrl_MemtoReg_s,
            i_RegWrite   => id_ctrl_RegWrite_s,
            i_MemRead    => id_ctrl_MemRead_s,
            i_MemWrite   => id_ctrl_MemWrite_s,
            i_Branch     => id_ctrl_Branch_s,
            i_Jump       => id_ctrl_Jump_s,
            i_ALUOp      => id_ctrl_ALUOp_s,
            i_PC4        => ifid_pc4,
            i_ReadData1  => id_read_data1,
            i_ReadData2  => id_read_data2,
            i_SignExt    => id_sign_ext,
            i_rs         => ifid_instruction(23 DOWNTO 21),
            i_rt         => ifid_instruction(18 DOWNTO 16),
            i_rd         => ifid_instruction(13 DOWNTO 11),
            i_funct      => ifid_instruction(5 DOWNTO 0),
            o_RegDst     => idex_ctrl_RegDst,
            o_ALUSrc     => idex_ctrl_ALUSrc,
            o_MemtoReg   => idex_ctrl_MemtoReg,
            o_RegWrite   => idex_ctrl_RegWrite,
            o_MemRead    => idex_ctrl_MemRead,
            o_MemWrite   => idex_ctrl_MemWrite,
            o_Branch     => idex_ctrl_Branch,
            o_Jump       => idex_ctrl_Jump,
            o_ALUOp      => idex_ctrl_ALUOp,
            o_PC4        => idex_pc4,
            o_ReadData1  => idex_read_data1,
            o_ReadData2  => idex_read_data2,
            o_SignExt    => idex_sign_ext,
            o_rs         => idex_rs,
            o_rt         => idex_rt,
            o_rd         => idex_rd,
            o_funct      => idex_funct
        );

    -- ==========================================================
    -- EX STAGE: Execute / Address Calculation
    -- ==========================================================

    -- Forwarding Unit
    U_FWD : forwarding_unit
        PORT MAP(
            IDEX_rs        => idex_rs,
            IDEX_rt        => idex_rt,
            EXMEM_RegWrite => exmem_ctrl_RegWrite,
            EXMEM_rd       => exmem_write_reg,
            MEMWB_RegWrite => memwb_ctrl_RegWrite,
            MEMWB_rd       => memwb_write_reg,
            ForwardA       => ex_fwd_a,
            ForwardB       => ex_fwd_b
        );

    -- Forwarding Mux A: select ALU input A
    -- 00=ID/EX ReadData1, 01=MEM/WB write data, 10=EX/MEM ALU result
    U_MUX_FWDA : nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => ex_fwd_a(0),
            s1 => ex_fwd_a(1),
            x0 => idex_read_data1,   -- 00: no forwarding
            x1 => wb_write_data,     -- 01: MEM/WB
            x2 => exmem_alu_result,  -- 10: EX/MEM
            x3 => exmem_alu_result,  -- 11: (unused, same as 10)
            y  => ex_alu_a
        );

    -- Forwarding Mux B: select ALU input B (before ALUSrc mux)
    U_MUX_FWDB : nBitMux4to1
        GENERIC MAP(n => 8)
        PORT MAP(
            s0 => ex_fwd_b(0),
            s1 => ex_fwd_b(1),
            x0 => idex_read_data2,   -- 00: no forwarding
            x1 => wb_write_data,     -- 01: MEM/WB
            x2 => exmem_alu_result,  -- 10: EX/MEM
            x3 => exmem_alu_result,  -- 11: (unused)
            y  => ex_alu_b_pre
        );

    -- ALUSrc mux: '0'=register, '1'=sign-extended immediate
    U_MUX_ALUSRC : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => idex_ctrl_ALUSrc,
            i_d0  => ex_alu_b_pre,
            i_d1  => idex_sign_ext,
            o_q   => ex_alu_b
        );

    -- ALU Control
    U_ALU_CTRL : ALU_control
        PORT MAP(
            ALU_Op    => idex_ctrl_ALUOp,
            funct     => idex_funct,
            Operation => ex_alu_ctrl
        );

    -- ALU
    U_ALU : nbit_ALU
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A          => ex_alu_a,
            i_B          => ex_alu_b,
            i_ALUControl => ex_alu_ctrl,
            o_ALUResult  => ex_alu_result,
            o_Zero       => ex_zero
        );

    -- RegDst mux: '0'=rt (I-type), '1'=rd (R-type)
    U_MUX_REGDST : nBitMux2to1
        GENERIC MAP(n => 3)
        PORT MAP(
            i_sel => idex_ctrl_RegDst,
            i_d0  => idex_rt,
            i_d1  => idex_rd,
            o_q   => ex_write_reg
        );

    -- Branch target = PC+4 + (sign_ext << 2)
    -- shift left 2 = multiply offset by 4
    ex_branch_offset(0) <= '0';
    ex_branch_offset(1) <= '0';
    ex_branch_offset(2) <= idex_sign_ext(0);
    ex_branch_offset(3) <= idex_sign_ext(1);
    ex_branch_offset(4) <= idex_sign_ext(2);
    ex_branch_offset(5) <= idex_sign_ext(3);
    ex_branch_offset(6) <= idex_sign_ext(4);
    ex_branch_offset(7) <= idex_sign_ext(5);

    U_BRANCH_ADD : nBitAddSubUnit
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A        => idex_pc4,
            i_Bi       => ex_branch_offset,
            i_OpFlag   => '0',
            o_CarryOut => ex_carry_branch,
            o_Sum      => ex_branch_target
        );

    -- Jump address from instruction[5:0] shifted left 2
    ex_jump_addr(0) <= '0';
    ex_jump_addr(1) <= '0';
    ex_jump_addr(2) <= ifid_instruction(0);
    ex_jump_addr(3) <= ifid_instruction(1);
    ex_jump_addr(4) <= ifid_instruction(2);
    ex_jump_addr(5) <= ifid_instruction(3);
    ex_jump_addr(6) <= ifid_instruction(4);
    ex_jump_addr(7) <= ifid_instruction(5);

    -- ==========================================================
    -- EX/MEM PIPELINE REGISTER
    -- ==========================================================

    U_EXMEM : EXMEM_reg
        PORT MAP(
            i_clock        => GClock,
            i_reset        => GReset,
            i_flush        => '0',
            i_MemtoReg     => idex_ctrl_MemtoReg,
            i_RegWrite     => idex_ctrl_RegWrite,
            i_MemRead      => idex_ctrl_MemRead,
            i_MemWrite     => idex_ctrl_MemWrite,
            i_Branch       => idex_ctrl_Branch,
            i_Jump         => idex_ctrl_Jump,
            i_BranchTarget => ex_branch_target,
            i_JumpAddr     => ex_jump_addr,
            i_Zero         => ex_zero,
            i_ALUResult    => ex_alu_result,
            i_ReadData2    => ex_alu_b_pre,   -- forwarded value for sw
            i_WriteReg     => ex_write_reg,
            o_MemtoReg     => exmem_ctrl_MemtoReg,
            o_RegWrite     => exmem_ctrl_RegWrite,
            o_MemRead      => exmem_ctrl_MemRead,
            o_MemWrite     => exmem_ctrl_MemWrite,
            o_Branch       => exmem_ctrl_Branch,
            o_Jump         => exmem_ctrl_Jump,
            o_BranchTarget => exmem_branch_target,
            o_JumpAddr     => exmem_jump_addr,
            o_Zero         => exmem_zero,
            o_ALUResult    => exmem_alu_result,
            o_ReadData2    => exmem_read_data2,
            o_WriteReg     => exmem_write_reg
        );

    -- ==========================================================
    -- MEM STAGE: Memory Access
    -- ==========================================================

    -- Branch resolution
    mem_take_branch <= exmem_ctrl_Branch AND exmem_zero;

    U_DMEM : data_memory
        PORT MAP(
            address => exmem_alu_result,
            clock   => mem_notCLK,
            data    => exmem_read_data2,
            wren    => exmem_ctrl_MemWrite,
            q       => mem_read_data
        );

    -- PC next selection:
    -- First: branch vs sequential
    U_MUX_BRANCH : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => mem_take_branch,
            i_d0  => if_pc_plus4,
            i_d1  => exmem_branch_target,
            o_q   => if_pc_branch_or_seq
        );

    -- Then: jump vs branch/sequential
    U_MUX_JUMP : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => exmem_ctrl_Jump,
            i_d0  => if_pc_branch_or_seq,
            i_d1  => exmem_jump_addr,
            o_q   => if_pc_final
        );

    -- ==========================================================
    -- MEM/WB PIPELINE REGISTER
    -- ==========================================================

    U_MEMWB : MEMWB_reg
        PORT MAP(
            i_clock       => GClock,
            i_reset       => GReset,
            i_MemtoReg    => exmem_ctrl_MemtoReg,
            i_RegWrite    => exmem_ctrl_RegWrite,
            i_MemReadData => mem_read_data,
            i_ALUResult   => exmem_alu_result,
            i_WriteReg    => exmem_write_reg,
            o_MemtoReg    => memwb_ctrl_MemtoReg,
            o_RegWrite    => memwb_ctrl_RegWrite,
            o_MemReadData => memwb_mem_read_data,
            o_ALUResult   => memwb_alu_result,
            o_WriteReg    => memwb_write_reg
        );

    -- ==========================================================
    -- WB STAGE: Write Back
    -- ==========================================================

    -- MemtoReg mux: '0'=ALU result, '1'=memory read data
    U_MUX_MEMTOREG : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => memwb_ctrl_MemtoReg,
            i_d0  => memwb_alu_result,
            i_d1  => memwb_mem_read_data,
            o_q   => wb_write_data
        );

    -- wb_write_data feeds back to register file and forwarding muxes

    -- ==========================================================
    -- INSTRUCTION SELECT OUTPUT (InstrSelect)
    -- Shows which instruction is in each pipeline stage
    -- ==========================================================

    instr_zeros <= (OTHERS => '0');

    -- For simplicity we show:
    --   000 = IF stage  (if_instruction)
    --   001 = ID stage  (ifid_instruction)
    --   010 = EX stage  (need to store - use idex reconstruction)
    --   011 = MEM stage
    --   100 = WB stage
    -- We use a simple 8-to-1 mux on 32-bit words using the 3-bit InstrSelect

    PROCESS(InstrSelect, if_instruction, ifid_instruction, instr_zeros)
    BEGIN
        CASE InstrSelect IS
            WHEN "000"  => InstructionOut <= if_instruction;
            WHEN "001"  => InstructionOut <= ifid_instruction;
            WHEN OTHERS => InstructionOut <= instr_zeros;
        END CASE;
    END PROCESS;

    -- ==========================================================
    -- OUTPUT MULTIPLEXER (ValueSelect -> MuxOut)
    -- ==========================================================

    ctrl_info(7) <= '0';
    ctrl_info(6) <= idex_ctrl_RegDst;
    ctrl_info(5) <= idex_ctrl_Jump;
    ctrl_info(4) <= idex_ctrl_MemRead;
    ctrl_info(3) <= idex_ctrl_MemtoReg;
    ctrl_info(2) <= idex_ctrl_ALUOp(1);
    ctrl_info(1) <= idex_ctrl_ALUOp(0);
    ctrl_info(0) <= idex_ctrl_ALUSrc;

    U_OMUX_01 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => if_pc_current,
            i_d1  => exmem_alu_result,
            o_q   => mux_s1_01
        );

    U_OMUX_23 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => id_read_data1,
            i_d1  => id_read_data2,
            o_q   => mux_s1_23
        );

    U_OMUX_45 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => wb_write_data,
            i_d1  => ctrl_info,
            o_q   => mux_s1_45
        );

    U_OMUX_0123 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(1),
            i_d0  => mux_s1_01,
            i_d1  => mux_s1_23,
            o_q   => mux_s2_0123
        );

    U_OMUX_4567 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(1),
            i_d0  => mux_s1_45,
            i_d1  => ctrl_info,
            o_q   => mux_s2_4567
        );

    U_OMUX_FINAL : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(2),
            i_d0  => mux_s2_0123,
            i_d1  => mux_s2_4567,
            o_q   => MuxOut
        );

    -- ==========================================================
    -- PRIMARY OUTPUT ASSIGNMENTS
    -- ==========================================================
    BranchOut   <= exmem_ctrl_Branch;
    ZeroOut     <= exmem_zero;
    MemWriteOut <= exmem_ctrl_MemWrite;
    RegWriteOut <= memwb_ctrl_RegWrite;

END structural;