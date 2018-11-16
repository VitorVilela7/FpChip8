library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity i_flow is
   port( I_SEL       : in natural range 0 to 3;
         VX_VAL      : in std_logic_vector(7 downto 0);
         NNN         : in std_logic_vector(11 downto 0);
         I_VAL       : in std_logic_vector(11 downto 0);
         I_LOAD      : out std_logic_vector(11 downto 0));
end i_flow;

architecture rtl of i_flow is
begin
   with I_SEL select
      I_LOAD <=   NNN when 0,
                  std_logic_vector(unsigned(I_VAL) + unsigned(VX_VAL)) when 1,
                  std_logic_vector(resize(resize(unsigned(VX_VAL), 4) * 5, 12)) when others;
                  
end rtl;