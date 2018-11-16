------------------------------------------------------------
-- CHIP-8 PC Stack Implementation (tested)
-- By Vitor Vilela (2018-10-28)
--
-- PUSH Usage:
-- Set EN and PUSH to HIGH, D to push data.
-- Wait one clock.
--
-- PULL Usage:
-- Set EN to HIGH and PUSH to LOW. Wait one clock.
-- Set EN to LOW. Wait another clock.
-- Data is now on Q output.
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity stack is
   port( CLK      : in std_logic;
         EN       : in std_logic;
         PUSH     : in std_logic;
         D        : in std_logic_vector(11 downto 0);
         Q        : out std_logic_vector(11 downto 0));
end stack;

architecture rtl of stack is
   signal ADDR, NEXT_ADDR : natural range 0 to 15;
   signal WE : std_logic;
begin
   process(CLK)
   begin
      if rising_edge(CLK) then
         if EN = '1' then
            if PUSH = '1' then
               ADDR <= ADDR + 1;
               
               if ADDR = 15 then
                  ADDR <= 0;
               end if;
            else
               ADDR <= ADDR - 1;
               
               if ADDR = 0 then
                  ADDR <= 15;
               end if;
            end if;
         end if;
      end if;
   end process;
   
   WE <= EN AND PUSH;
   
   mem : entity work.stack_ram port map(CLK => CLK, WE => WE, ADDR => ADDR, L => D, Q => Q);
      
end rtl;