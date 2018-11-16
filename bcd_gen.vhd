------------------------------------------------------------
-- Hex-to-Decimal-BCD Converter
-- By Vitor Vilela (2018-11-02)
--
-- Converts the 8-bit hexadecimal number to 10-bit BCD
-- formatted number. Based on Double Dabble algorithm.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bcd_gen is
   port( CLK      : in std_logic;
         EN       : in std_logic;
         DATA     : in std_logic_vector(7 downto 0);
         DONE     : out std_logic;
         Q        : out std_logic_vector(9 downto 0));
end bcd_gen;

architecture rtl of bcd_gen is
   signal NEXT_SHIFT, CURRENT_SHIFT : unsigned(11 downto 0);
   signal DAT : unsigned(7 downto 1);
   signal CNT : unsigned(2 downto 0) := "111";
   signal DONE_S : std_logic;
begin
   CURRENT_SHIFT(11 downto 10) <= "00"; -- locked.
   DONE_S <= CNT(0) AND CNT(1) AND CNT(2);
   DONE <= DONE_S;
   
   Q <= std_logic_vector(CURRENT_SHIFT(9 DOWNTO 0));

   process(CURRENT_SHIFT)
   begin
      NEXT_SHIFT <= CURRENT_SHIFT;
      
      for K in 0 to 2 loop
         if CURRENT_SHIFT(4*K+3 downto 4*K) > 4 then
            NEXT_SHIFT(4*K+3 downto 4*K) <= CURRENT_SHIFT(4*K+3 downto 4*K) + 3;
         end if;
      end loop;
      
      NEXT_SHIFT(11 downto 10) <= "00";
   end process;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if EN = '1' then
            CURRENT_SHIFT(9 downto 1) <= (others => '0');
            CURRENT_SHIFT(0) <= DATA(7);
            DAT <= unsigned(DATA(6 downto 0));
            CNT <= "000";
         elsif DONE_S = '0' then
            CURRENT_SHIFT(9 downto 0) <= NEXT_SHIFT(8 downto 0) & DAT(7);
            DAT <= DAT SLL 1;
            CNT <= CNT + 1;
         end if;
      end if;
   end process;
end rtl;