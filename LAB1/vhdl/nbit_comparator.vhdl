LIBRARY ieee;
use ieee.std_logic_1164.ALL;

-- Generic version of the provided threebitcomparator provided on brightspace
-- Only works for unsigned integers
entity nbit_comparator is
    GENERIC (
                BITS : natural := 8
            );
    port (
             in_a : in STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
             in_b : in STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0);
             a_gt_b : out STD_LOGIC;
             a_gteq_b : out STD_LOGIC;
             a_lt_b : out STD_LOGIC;
             a_lteq_b : out STD_LOGIC;
             a_eq_b : out STD_LOGIC
    );
end entity nbit_comparator;

architecture rtl of nbit_comparator is
    SIGNAL s_a_lt_b : STD_LOGIC_VECTOR(BITS DOWNTO 0) := (others => '0'); -- longer so the cary in can be 0
    SIGNAL s_a_gt_b : STD_LOGIC_VECTOR(BITS DOWNTO 0) := (others => '0');

	COMPONENT oneBitComparator
	PORT(
		i_GTPrevious, i_LTPrevious	: IN	STD_LOGIC;
		i_Ai, i_Bi			: IN	STD_LOGIC;
		o_GT, o_LT			: OUT	STD_LOGIC);
	END COMPONENT;

begin
    compare : for i in BITS - 1 DOWNTO 0 generate
        comp: oneBitComparator
        PORT MAP (i_GTPrevious => s_a_gt_b(i + 1), 
                  i_LTPrevious => s_a_lt_b(i + 1),
                  i_Ai => in_a(i),
                  i_Bi => in_b(i),
                  o_GT => s_a_gt_b(i),
                  o_LT => s_a_lt_b(i)
              );
    end generate;

    a_gt_b <= s_a_gt_b(0);
    a_lt_b <= s_a_lt_b(0);
    a_eq_b <= s_a_gt_b(0) NOR s_a_lt_b(0);
    a_gteq_b <= s_a_gt_b(0) OR (s_a_gt_b(0) NOR s_a_lt_b(0));
    a_lteq_b <= s_a_lt_b(0) OR (s_a_gt_b(0) NOR s_a_lt_b(0));

end architecture rtl;
