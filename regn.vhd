------------------------------------------------------------
-- Generic n-bit register.
-- By Vitor Vilela (2016)
--
-- To reset the register, both RST and EN should be HIGH.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity regn is
   generic( N     : integer := 8);
   
   port( CLK      : in std_logic;
         RST      : in std_logic;
         EN       : in std_logic;
         L        : in std_logic_vector(N-1 downto 0);
         Q        : out std_logic_vector(N-1 downto 0));
end regn;

architecture rtl of regn is
begin
   process(CLK)
   begin
      if rising_edge(CLK) then
         if EN = '1' then
            if RST = '1' then
               Q <= (others => '0');
            else
               Q <= L;
            end if;
         end if;
      end if;
   end process;
end rtl;