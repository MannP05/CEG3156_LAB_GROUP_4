library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity instruction_memory is
    port (
        clock   : in  std_logic;  
        read_address : in  std_logic_vector(7 downto 0);
        instruction    : out std_logic_vector(31 downto 0)
    );
end entity;

architecture structural of instruction_memory is
begin
    rom_inst : altsyncram
        generic map (
            operation_mode         => "ROM",
            width_a                => 32,
            widthad_a              => 8,
            numwords_a             => 256,
            init_file              => "instruction_memory.mif",
            outdata_reg_a          => "UNREGISTERED",  -- no extra output register
            address_aclr_a         => "NONE",
            intended_device_family => "Cyclone IV E"
        )
        port map (
            clock0    => clock,
            address_a => read_address,
            q_a       => instruction,
            -- Tie off unused ports
            data_a    => (others => '0'),
            wren_a    => '0',
            rden_a    => '1',
            aclr0     => '0',
            aclr1     => '0',
            clocken0  => '1'
        );
end architecture;