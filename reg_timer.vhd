------------------------------------------------------------
-- Countdown timer.
-- By Vitor Vilela (2018-11-09)
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_timer is
   port( CLK         : in std_logic;
         RST         : in std_logic;
         EN          : in std_logic;
         TICK        : in std_logic;
         L           : in std_logic_vector(7 downto 0);
         Q           : out std_logic_vector(7 downto 0);
         ZERO        : out std_logic);
end reg_timer;

architecture rtl of reg_timer is
   signal COUNTER : unsigned(7 downto 0);
   signal ZERO_Q : std_logic;
begin
   Q <= std_logic_vector(COUNTER);
   ZERO <= ZERO_Q;
   
   ZERO_Q <= '1' when COUNTER = X"00" else '0';
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if RST = '1' then
            COUNTER <= (others => '0');
         elsif EN = '1' then
            COUNTER <= unsigned(L);
         elsif TICK = '1' then
            COUNTER <= COUNTER - 1;
            
            if ZERO_Q = '1' then
               COUNTER <= x"00";
            end if;
         end if;
      end if;
   end process;
end rtl;