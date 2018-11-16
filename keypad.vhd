------------------------------------------------------------
-- Main keypad. Latches and controls the 4x4 keypad.
-- By Vitor Vilela (2018-11-16)
--
-- Please enable weak pull-up on the input pins (COL).
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity keypad is
	port(	CLK		: in std_logic;
			COL		: in std_logic_vector(3 downto 0);
			LIN		: out std_logic_vector(3 downto 0);
			RES		: out std_logic_vector(15 downto 0));
end keypad;

architecture rtl of keypad is
	type matrix_t is array(0 to 3) of std_logic_vector(3 downto 0);
   type int_t is array(natural range <>) of integer;
   
	signal INDEX : natural range 0 to 3;
   signal MATRIX, MATRIX_STABLE : matrix_t;
   signal LIN_N : std_logic_vector(3 downto 0);
   
   -- Important to "smooth" output.
   signal INT_CNT : unsigned(15 downto 0);
   
   -- Key remapping
   -- Explanation, the keypad is mapped the following way:
   -- 1 2 3 C
   -- 4 5 6 D
   -- 7 8 9 E
   -- A 0 B F
   --
   -- While signals are read as:
   -- C D E F
   -- 8 9 A B
   -- 4 5 6 7
   -- 0 1 2 3
   --
   -- Hence both remappings.
   
   constant REMAP : int_t(0 to 15) := (
      1, 2, 3, 12,
      4, 5, 6, 13,
      7, 8, 9, 14,
      10, 0, 11, 15
   );
   
   constant INDEX_REMAP : int_t(0 to 3) := (
      3, 2, 1, 0
   );
begin
   op: for I in 0 to 3 generate
      opj : for J in 0 to 3 generate
         RES(REMAP(I*4+3-J)) <= MATRIX_STABLE(I)(J);
      end generate;
   end generate;
   
   LIN <= NOT LIN_N;
   
	process(INDEX)
	begin
		LIN_N <= (others => '0');
		LIN_N(INDEX_REMAP(INDEX)) <= '1';
	end process;
	
	process(CLK)
	begin
		if rising_edge(CLK) then
         INT_CNT <= INT_CNT + 1;
         
         -- Wait enough time to get a sample...
         if INT_CNT = 65535 then
            INDEX <= INDEX + 1;
            MATRIX(INDEX) <= NOT COL;
         end if;
         
         MATRIX_STABLE <= MATRIX;
		end if;
	end process;
	
end rtl;