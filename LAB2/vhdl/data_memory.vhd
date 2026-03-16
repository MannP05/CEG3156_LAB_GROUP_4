library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity data_memory is
    port (
        i_clock     : in  std_logic;
        i_address   : in  std_logic_vector(7 downto 0);
        i_writeData : in  std_logic_vector(7 downto 0);
        i_MemWrite  : in  std_logic;
        i_MemRead   : in  std_logic;
        o_readData  : out std_logic_vector(7 downto 0)
    );
end entity;

architecture structural of data_memory is
    signal s_ramOut : std_logic_vector(7 downto 0);
begin
    ram_inst : altsyncram
        generic map (
            operation_mode         => "SINGLE_PORT",
            width_a                => 8,
            widthad_a              => 8,
            numwords_a             => 256,
            init_file              => "data_memory.mif",
            outdata_reg_a          => "UNREGISTERED",
            intended_device_family => "Cyclone IV E"
        )
        port map (
            clock0    => i_clock,
            address_a => i_address,
            data_a    => i_writeData,
            wren_a    => i_MemWrite,
            q_a       => s_ramOut,
            -- Tie off unused
            rden_a    => '1',
            aclr0     => '0',
            aclr1     => '0',
            clocken0  => '1'
        );

    o_readData <= s_ramOut when i_MemRead = '1' else (others => '0');
end architecture;