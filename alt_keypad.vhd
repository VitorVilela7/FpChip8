------------------------------------------------------------
-- CHIP-8 Alternate Keypad.
-- By Vitor Vilela (2018-11-02)
--
-- Altenative keypad for who don't have the 4x4 keypad.
-- Uses the switch(0..1) to select which line to play and
-- ~KEY(0..3) to map which button pressed.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alt_keypad is
   port( CLK      : in std_logic;
         SW       : in std_logic_vector(1 downto 0);
         KEY      : in std_logic_vector(3 downto 0);
         RES      : out std_logic_vector(15 downto 0));
end alt_keypad;

architecture rtl of alt_keypad is
   type matrix_t is array(0 to 3) of std_logic_vector(3 downto 0);
   signal INDEX : natural range 0 to 3;
   signal MATRIX, MATRIX_STABLE : matrix_t;
   
   type int_t is array(natural range <>) of integer;
   
   constant REMAP : int_t(0 to 15) := (
      1, 2, 3, 12,
      4, 5, 6, 13,
      7, 8, 9, 14,
      10, 0, 11, 15
   );
begin
   op: for I in 0 to 3 generate
      opj : for J in 0 to 3 generate
         RES(REMAP(I*4+3-J)) <= MATRIX_STABLE(I)(J);
      end generate;
   end generate;
   
   INDEX <= to_integer(unsigned(SW));
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         MATRIX <= (others => (others => '0'));
         MATRIX(INDEX) <= NOT KEY;
         
         MATRIX_STABLE <= MATRIX;
      end if;
   end process;
end rtl;