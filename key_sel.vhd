library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity key_sel is
   port( CLK      : in std_logic;
         KEY      : in std_logic_vector(15 downto 0);
         SEL      : in std_logic_vector(3 downto 0);
         KEY_OUT  : out std_logic;
         KEY_NEW  : out std_logic;
         KEY_ENC  : out std_logic_vector(3 downto 0));
end key_sel;

architecture rtl of key_sel is
   signal PREV_KEY : std_logic_vector(15 downto 0);
begin
   KEY_OUT <= KEY(to_integer(unsigned(SEL)));
   KEY_NEW <= '1' when (KEY AND (NOT PREV_KEY)) /= X"0000" else '0';
   
   process(KEY)
   begin
      KEY_ENC <= x"0";
      
      for I in 0 to 15 loop
         if KEY(I) = '1' then
            KEY_ENC <= std_logic_vector(to_unsigned(I, 4));
         end if;
      end loop;
   end process;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         PREV_KEY <= KEY;
      end if;
   end process;
   
end rtl;