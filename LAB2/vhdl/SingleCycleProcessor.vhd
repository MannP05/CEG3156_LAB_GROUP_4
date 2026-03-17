library ieee;
use ieee.std_logic_1164.all;
use work.mux_package.all;

entity SingleCycleProcessor is
    port(
        GClock : in std_logic;
        GReset : in std_logic;
        ValueSelect : in std_logic_vector(2 downto 0);
        MuxOut : out std_logic_vector(7 downto 0);
        InstructionOut : out std_logic_vector(31 downto 0);
        BranchOut : out std_logic;
        ZeroOut : out std_logic;
        MemWriteOut : out std_logic;
        RegWriteOut : out std_logic
    );
end SingleCycleProcessor;

architecture structural of SingleCycleProcessor is

    component nbitaddsubunit
        generic (n : integer := 8);
        port(
            i_A : in std_logic_vector(n-1 downto 0);
            i_Bi : in std_logic_vector(n-1 downto 0);
            i_OpFlag : in std_logic;  -- '0' for add, '1' for subtract
            o_CarryOut : out std_logic;
            o_Sum : out std_logic_vector(n-1 downto 0)
        );
    end component;

    -- Component declarations
    component instruction_memory
        port (
            clock   : in  std_logic;  
            read_address : in  std_logic_vector(7 downto 0);
            instruction    : out std_logic_vector(31 downto 0)
        );
    end component;

    component Control_Unit
        port(
            opcode : in std_logic_vector(5 downto 0);
            RegDst : out std_logic;
            ALUSrc : out std_logic;
            MemtoReg : out std_logic;
            RegWrite : out std_logic;
            MemRead : out std_logic;
            MemWrite : out std_logic;
            Branch : out std_logic;
            ALUOp : out std_logic_vector(1 downto 0)
        );
    end component;

    component register_file
        port(
            clock      : in  std_logic;
            reset      : in  std_logic;
            RegWrite   : in  std_logic;
            read_reg1  : in  std_logic_vector(2 downto 0);
            read_reg2  : in  std_logic_vector(2 downto 0);
            write_reg  : in  std_logic_vector(2 downto 0);
            write_data : in  std_logic_vector(7 downto 0);
            read_data1 : out std_logic_vector(7 downto 0);
            read_data2 : out std_logic_vector(7 downto 0)
        );
    end component;

    component ALU_control
        port(
            ALU_Op : in std_logic_vector(1 downto 0);
            funct  : in std_logic_vector(5 downto 0);
            Operation : out std_logic_vector(2 downto 0)
        );
    end component;

    component nbit_ALU
        generic (n : integer := 8);
        port(
            i_A          : in  std_logic_vector(n-1 downto 0);
            i_B          : in  std_logic_vector(n-1 downto 0);
            i_ALUControl : in  std_logic_vector(2 downto 0);
            o_ALUResult  : out std_logic_vector(n-1 downto 0);
            o_Zero       : out std_logic
        );
    end component;

    component data_memory
        port (
            i_clock     : in  std_logic;
            i_address   : in  std_logic_vector(7 downto 0);
            i_writeData : in  std_logic_vector(7 downto 0);
            i_MemWrite  : in  std_logic;
            i_MemRead   : in  std_logic;
            o_readData  : out std_logic_vector(7 downto 0)
        );
    end component;

    component sign_extended
        port(
            i  : in  std_logic_vector(15 downto 0);
            o : out std_logic_vector(7 downto 0)
        );
    end component;

    component nBitMux2to1
        generic (n : integer := 8);
        port(
            i_sel : in std_logic;
            i_d0 : in std_logic_vector(n-1 downto 0);
            i_d1 : in std_logic_vector(n-1 downto 0);
            o_q : out std_logic_vector(n-1 downto 0)
        );
    end component;

    component reg_8
        port(
            i_d     : in  std_logic_vector(7 downto 0);
            i_load  : in  std_logic;
            i_clock : in  std_logic;
            i_reset : in  std_logic;
            o_q     : out std_logic_vector(7 downto 0)
        );
    end component;

    component mux_8to1_8bit
        port(
            i_inputs : in bus_array_8;
            i_sel : in std_logic_vector(2 downto 0);
            o_y : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Signals
    signal PC : std_logic_vector(7 downto 0);
    signal PC_next : std_logic_vector(7 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal opcode : std_logic_vector(5 downto 0);
    signal rs : std_logic_vector(2 downto 0);
    signal rt : std_logic_vector(2 downto 0);
    signal rd : std_logic_vector(2 downto 0);
    signal funct : std_logic_vector(5 downto 0);
    signal immediate : std_logic_vector(15 downto 0);
    signal sign_ext_imm : std_logic_vector(7 downto 0);

    -- Control signals
    signal RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch : std_logic;
    signal ALUOp : std_logic_vector(1 downto 0);
    signal ALUControl : std_logic_vector(2 downto 0);

    -- Register file signals
    signal read_data1, read_data2 : std_logic_vector(7 downto 0);
    signal write_reg : std_logic_vector(2 downto 0);
    signal write_data : std_logic_vector(7 downto 0);

    -- ALU signals
    signal ALU_result : std_logic_vector(7 downto 0);
    signal ALU_zero : std_logic;
    signal ALU_src_B : std_logic_vector(7 downto 0);

    -- Data memory signals
    signal mem_read_data : std_logic_vector(7 downto 0);

    -- PC signals
    signal PC_plus_4 : std_logic_vector(7 downto 0);
    signal PC_branch : std_logic_vector(7 downto 0);
    signal PCSrc : std_logic;
    signal mux_inputs : bus_array_8;

begin

    -- PC register
    pc_reg: reg_8 port map(
        i_d => PC_next,
        i_load => '1',  -- always load
        i_clock => GClock,
        i_reset => GReset,
        o_q => PC
    );

    -- PC + 4 adder
    pc_adder: nBitAddSubUnit generic map(n => 8) port map(
        i_A => PC,
        i_Bi => "00000100",  -- 4
        i_OpFlag => '0',  -- add
        o_CarryOut => open,
        o_Sum => PC_plus_4
    );

    -- Instruction memory
    im: instruction_memory port map(
        clock => GClock,
        read_address => PC,
        instruction => instruction
    );

    -- Parse instruction
    opcode <= instruction(31 downto 26);
    rs <= instruction(25 downto 23);  -- 3-bit registers
    rt <= instruction(22 downto 20);
    rd <= instruction(19 downto 17);
    funct <= instruction(5 downto 0);
    immediate <= instruction(15 downto 0);

    -- Control unit
    cu: Control_Unit port map(
        opcode => opcode,
        RegDst => RegDst,
        ALUSrc => ALUSrc,
        MemtoReg => MemtoReg,
        RegWrite => RegWrite,
        MemRead => MemRead,
        MemWrite => MemWrite,
        Branch => Branch,
        ALUOp => ALUOp
    );

    -- ALU control
    alu_ctrl: ALU_control port map(
        ALU_Op => ALUOp,
        funct => funct,
        Operation => ALUControl
    );

    -- Register file
    rf: register_file port map(
        clock => GClock,
        reset => GReset,
        RegWrite => RegWrite,
        read_reg1 => rs,
        read_reg2 => rt,
        write_reg => write_reg,
        write_data => write_data,
        read_data1 => read_data1,
        read_data2 => read_data2
    );

    -- Write reg mux
    write_reg_mux: nBitMux2to1 generic map(n => 3) port map(
        i_sel => RegDst,
        i_d0 => rt,
        i_d1 => rd,
        o_q => write_reg
    );

    -- Sign extend
    se: sign_extended port map(
        i => immediate,
        o => sign_ext_imm
    );

    -- ALU src B mux
    alu_src_mux: nBitMux2to1 generic map(n => 8) port map(
        i_sel => ALUSrc,
        i_d0 => read_data2,
        i_d1 => sign_ext_imm,
        o_q => ALU_src_B
    );

    -- ALU
    alu: nbit_ALU generic map(n => 8) port map(
        i_A => read_data1,
        i_B => ALU_src_B,
        i_ALUControl => ALUControl,
        o_ALUResult => ALU_result,
        o_Zero => ALU_zero
    );

    -- Data memory
    dm: data_memory port map(
        i_clock => GClock,
        i_address => ALU_result,
        i_writeData => read_data2,
        i_MemWrite => MemWrite,
        i_MemRead => MemRead,
        o_readData => mem_read_data
    );

    -- Write data mux
    write_data_mux: nBitMux2to1 generic map(n => 8) port map(
        i_sel => MemtoReg,
        i_d0 => ALU_result,
        i_d1 => mem_read_data,
        o_q => write_data
    );

    -- Branch logic
    PCSrc <= Branch and ALU_zero;

    -- PC branch adder (PC+4 + sign_ext_imm)
    pc_branch_adder: nBitAddSubUnit generic map(n => 8) port map(
        i_A => PC_plus_4,
        i_Bi => sign_ext_imm,
        i_OpFlag => '0',  -- add
        o_CarryOut => open,
        o_Sum => PC_branch
    );

    -- PC next mux
    pc_next_mux: nBitMux2to1 generic map(n => 8) port map(
        i_sel => PCSrc,
        i_d0 => PC_plus_4,
        i_d1 => PC_branch,
        o_q => PC_next
    );

    -- Mux inputs for MuxOut
    mux_inputs(0) <= PC;
    mux_inputs(1) <= PC_plus_4;
    mux_inputs(2) <= ALU_result;
    mux_inputs(3) <= read_data1;
    mux_inputs(4) <= read_data2;
    mux_inputs(5) <= write_data;
    mux_inputs(6) <= mem_read_data;
    mux_inputs(7) <= sign_ext_imm;

    -- Mux for MuxOut
    value_mux: mux_8to1_8bit port map(
        i_inputs => mux_inputs,
        i_sel => ValueSelect,
        o_y => MuxOut
    );

    -- Output assignments
    InstructionOut <= instruction;
    BranchOut <= Branch;
    ZeroOut <= ALU_zero;
    MemWriteOut <= MemWrite;
    RegWriteOut <= RegWrite;

end structural;
