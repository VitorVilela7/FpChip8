library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
   generic( W     : natural);

   port( CLK      : in std_logic;
         EN       : in std_logic;
         RST      : in std_logic;
         Q        : out std_logic_vector(W-1 downto 0));
end counter;

architecture rtl of counter is
   signal COUNT : unsigned(W-1 downto 0);
begin
   Q <= std_logic_vector(COUNT);
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if RST = '1' then
            COUNT <= (others => '0');
         elsif EN = '1' then
            COUNT <= COUNT + 1;
         end if;
      end if;
   end process;
end rtl;
