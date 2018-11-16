------------------------------------------------------------
-- CHIP-8 Program Counter Data Path
-- By Vitor Vilela (2018-11-15)
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pc_flow is
   port( PROG_FLAG   : in std_logic;
         PC_SEL      : in natural range 0 to 3;
         VX_VAL      : in std_logic_vector(7 downto 0);
         PC_VAL      : in std_logic_vector(11 downto 0);
         NNN         : in std_logic_vector(11 downto 0);
         STACK       : in std_logic_vector(11 downto 0);
         PC_LOAD     : out std_logic_vector(11 downto 0));
end pc_flow;

architecture rtl of pc_flow is
   signal PC_LOAD_Q : std_logic_vector(11 downto 0);
begin
   PC_LOAD <= PC_LOAD_Q when PROG_FLAG = '0' else x"200";
   
   with PC_SEL select
      PC_LOAD_Q <=   std_logic_vector(unsigned(PC_VAL) + 1) when 0,
                     NNN when 1,
                     std_logic_vector(unsigned(NNN) + unsigned(VX_VAL)) when 2,
                     STACK when 3;
end rtl;