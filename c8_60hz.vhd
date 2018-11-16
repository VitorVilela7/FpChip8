library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity c8_60hz is
   port( CLK      : in std_logic;
         TICK     : out std_logic);
end c8_60hz;

architecture rtl of c8_60hz is
   -- FPGA clock is 50 MHz.
   -- 50 MHz / 60 Hz = 833333.3

   constant MAX : natural := 833333 - 1;
   signal COUNTER : natural range 0 to MAX;
begin
   TICK <= '1' when COUNTER = MAX else '0';
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         COUNTER <= COUNTER + 1;
         
         if COUNTER = MAX then
            COUNTER <= 0;
         end if;
      end if;
   end process;
end rtl;