--------------------------------------------------------------------------------
-- Title         : Top-Level Single-Cycle MIPS Processor
-- Project       : Lab2
-------------------------------------------------------------------------------
-- File          : lab2.vhdl
-- Author        : Surya & Mann
-------------------------------------------------------------------------------
-- Description : A structural top-level entity integrating the datapath and 
--               control unit of an 8-bit data, 32-bit instruction single-cycle 
--               MIPS processor. It instantiates and connects all components 
--               for the fetch, decode, execute, memory, and write-back stages, 
--               and includes a debugging multiplexer to output internal signals.
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY LAB2 IS
    PORT(
        GClock         : IN  STD_LOGIC;
        GReset         : IN  STD_LOGIC;
        ValueSelect    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        MuxOut         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        InstructionOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        BranchOut      : OUT STD_LOGIC;
        ZeroOut        : OUT STD_LOGIC;
        MemWriteOut    : OUT STD_LOGIC;
        RegWriteOut    : OUT STD_LOGIC
    );
END LAB2;

ARCHITECTURE structural OF LAB2 IS

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

    -- ==========================================================
    -- INTERNAL SIGNALS
    -- ==========================================================

    SIGNAL pc_current    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pc_plus4      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pc_branch_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pc_next       : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL instruction   : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL ctrl_RegDst   : STD_LOGIC;
    SIGNAL ctrl_ALUSrc   : STD_LOGIC;
    SIGNAL ctrl_MemtoReg : STD_LOGIC;
    SIGNAL ctrl_RegWrite : STD_LOGIC;
    SIGNAL ctrl_MemRead  : STD_LOGIC;
    SIGNAL ctrl_MemWrite : STD_LOGIC;
    SIGNAL ctrl_Branch   : STD_LOGIC;
    SIGNAL ctrl_Jump     : STD_LOGIC;
    SIGNAL ctrl_ALUOp    : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL take_branch   : STD_LOGIC;

    SIGNAL reg_write_addr : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL read_data1     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL read_data2     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL reg_write_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL sign_ext_out   : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL alu_ctrl       : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL alu_b_in       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_result     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL alu_zero       : STD_LOGIC;

    SIGNAL mem_read_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL branch_offset  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL branch_target  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL jump_addr      : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL carry_pc4      : STD_LOGIC;
    SIGNAL carry_branch   : STD_LOGIC;

    SIGNAL ctrl_info      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_01      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_23      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_45      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s1_67      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s2_0123    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mux_s2_4567    : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    U_PC : pc_reg
        PORT MAP(
            i_clock => GClock,
            i_reset => GReset,
            i_d     => pc_next,
            o_q     => pc_current
        );

    U_PC_ADD : nBitAddSubUnit
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A        => pc_current,
            i_Bi       => x"04",
            i_OpFlag   => '0',
            o_CarryOut => carry_pc4,
            o_Sum      => pc_plus4
        );

    U_IMEM : instruction_memory
        PORT MAP(
            address => pc_next,
            clock   => GClock,
            q       => instruction
        );

    InstructionOut <= instruction;

    U_CTRL : Control_Unit
        PORT MAP(
            opcode   => instruction(31 DOWNTO 26),
            RegDst   => ctrl_RegDst,
            ALUSrc   => ctrl_ALUSrc,
            MemtoReg => ctrl_MemtoReg,
            RegWrite => ctrl_RegWrite,
            MemRead  => ctrl_MemRead,
            MemWrite => ctrl_MemWrite,
            Branch   => ctrl_Branch,
            Jump     => ctrl_Jump,
            ALUOp    => ctrl_ALUOp
        );

    U_MUX_REGDST : nBitMux2to1
        GENERIC MAP(n => 3)
        PORT MAP(
            i_sel => ctrl_RegDst,
            i_d0  => instruction(18 DOWNTO 16),
            i_d1  => instruction(13 DOWNTO 11),
            o_q   => reg_write_addr
        );

    U_REGFILE : register_file
        PORT MAP(
            clock      => GClock,
            reset      => GReset,
            RegWrite   => ctrl_RegWrite,
            read_reg1  => instruction(23 DOWNTO 21),
            read_reg2  => instruction(18 DOWNTO 16),
            write_reg  => reg_write_addr,
            write_data => reg_write_data,
            read_data1 => read_data1,
            read_data2 => read_data2
        );

    U_SIGN_EXT : sign_extended
        PORT MAP(
            i => instruction(15 DOWNTO 0),
            o => sign_ext_out
        );

    U_ALU_CTRL : ALU_control
        PORT MAP(
            ALU_Op    => ctrl_ALUOp,
            funct     => instruction(5 DOWNTO 0),
            Operation => alu_ctrl
        );

    U_MUX_ALUSRC : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ctrl_ALUSrc,
            i_d0  => read_data2,
            i_d1  => sign_ext_out,
            o_q   => alu_b_in
        );

    U_ALU : nbit_ALU
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A          => read_data1,
            i_B          => alu_b_in,
            i_ALUControl => alu_ctrl,
            o_ALUResult  => alu_result,
            o_Zero       => alu_zero
        );


    U_DMEM : data_memory
        PORT MAP(
            address => alu_result,
            clock   => GClock,
            data    => read_data2,
            wren    => ctrl_MemWrite,
            q       => mem_read_data
        );


    U_MUX_MEMTOREG : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ctrl_MemtoReg,
            i_d0  => alu_result,
            i_d1  => mem_read_data,
            o_q   => reg_write_data
        );

    branch_offset(0) <= '0';
    branch_offset(1) <= '0';
    branch_offset(2) <= sign_ext_out(0);
    branch_offset(3) <= sign_ext_out(1);
    branch_offset(4) <= sign_ext_out(2);
    branch_offset(5) <= sign_ext_out(3);
    branch_offset(6) <= sign_ext_out(4);
    branch_offset(7) <= sign_ext_out(5);

    U_BRANCH_ADD : nBitAddSubUnit
        GENERIC MAP(n => 8)
        PORT MAP(
            i_A        => pc_plus4,
            i_Bi       => branch_offset,
            i_OpFlag   => '0',
            o_CarryOut => carry_branch,
            o_Sum      => branch_target
        );

    take_branch <= ctrl_Branch AND alu_zero;

    U_MUX_BRANCH : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => take_branch,
            i_d0  => pc_plus4,
            i_d1  => branch_target,
            o_q   => pc_branch_out
        );

    jump_addr(0) <= '0';
    jump_addr(1) <= '0';
    jump_addr(2) <= instruction(0);
    jump_addr(3) <= instruction(1);
    jump_addr(4) <= instruction(2);
    jump_addr(5) <= instruction(3);
    jump_addr(6) <= instruction(4);
    jump_addr(7) <= instruction(5);

    U_MUX_JUMP : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ctrl_Jump,
            i_d0  => pc_branch_out,
            i_d1  => jump_addr,
            o_q   => pc_next
        );

    ctrl_info(7) <= '0';
    ctrl_info(6) <= ctrl_RegDst;
    ctrl_info(5) <= ctrl_Jump;
    ctrl_info(4) <= ctrl_MemRead;
    ctrl_info(3) <= ctrl_MemtoReg;
    ctrl_info(2) <= ctrl_ALUOp(1);
    ctrl_info(1) <= ctrl_ALUOp(0);
    ctrl_info(0) <= ctrl_ALUSrc;

    U_OMUX_S1_01 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => pc_current,
            i_d1  => alu_result,
            o_q   => mux_s1_01
        );

    U_OMUX_S1_23 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => read_data1,
            i_d1  => read_data2,
            o_q   => mux_s1_23
        );

    U_OMUX_S1_45 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => reg_write_data,
            i_d1  => ctrl_info,
            o_q   => mux_s1_45
        );

    U_OMUX_S1_67 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(0),
            i_d0  => ctrl_info,
            i_d1  => ctrl_info,
            o_q   => mux_s1_67
        );

    U_OMUX_S2_0123 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(1),
            i_d0  => mux_s1_01,
            i_d1  => mux_s1_23,
            o_q   => mux_s2_0123
        );

    U_OMUX_S2_4567 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(1),
            i_d0  => mux_s1_45,
            i_d1  => mux_s1_67,
            o_q   => mux_s2_4567
        );

    U_OMUX_S3 : nBitMux2to1
        GENERIC MAP(n => 8)
        PORT MAP(
            i_sel => ValueSelect(2),
            i_d0  => mux_s2_0123,
            i_d1  => mux_s2_4567,
            o_q   => MuxOut
        );

    -- ==========================================================
    -- OUTPUT PORT ASSIGNMENTS
    -- ==========================================================
    BranchOut   <= ctrl_Branch;
    ZeroOut     <= alu_zero;
    MemWriteOut <= ctrl_MemWrite;
    RegWriteOut <= ctrl_RegWrite;

END structural;