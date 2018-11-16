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
use IEEE.numeric_std.all;

entity main_ram is
   port( CLK         : in std_logic;
         WE          : in std_logic;
         ADDR        : in unsigned(11 downto 0);
         L           : in std_logic_vector(7 downto 0);
         Q           : out std_logic_vector(7 downto 0));
end main_ram;

architecture rtl of main_ram is
   signal RADDR, WADDR : std_logic_vector(11 downto 0);
begin
   RADDR <= std_logic_vector(ADDR);
   
   process(CLK)
   begin
      if rising_edge(CLK) then -- Register address for write...
         WADDR <= RADDR;
      end if;
   end process;
   
   ram : entity work.ram_dual port map(
      clock => CLK,
      data => L,
      rdaddress => RADDR,
      wraddress => WADDR,
      wren => WE,
      q => Q
   );
   
end rtl;