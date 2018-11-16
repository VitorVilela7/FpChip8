------------------------------------------------------------
-- Main memory module.
-- By Vitor Vilela (2018-10-28)
--
-- Writing takes an additional cycle to match
-- the pipelined behavior of reads.
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity stack_ram is
   generic( N        : integer := 12;
            SIZE     : integer := 16);

   port( CLK         : in std_logic;
         WE          : in std_logic;
         ADDR        : in natural range 0 to SIZE-1;
         L           : in std_logic_vector(N-1 downto 0);
         Q           : out std_logic_vector(N-1 downto 0));
end stack_ram;

architecture rtl of stack_ram is
   type int_array is array(0 to SIZE-1) of std_logic_vector(N-1 downto 0);
   signal RAM : int_array;
begin
   process(CLK)
   begin
      if rising_edge(CLK) then   
         if WE = '1' then
            RAM(ADDR) <= L;
         end if;
         
         -- Send output
         Q <= RAM(ADDR);
      end if;
   end process;
end rtl;