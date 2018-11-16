------------------------------------------------------------
-- Pseudo-Random Number Generator
-- By Vitor Vilela (2018-11-02)
--
-- Generates a 8-bit random number based on Galois LFSR.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity prng is
  port( CLK   : in std_logic;
        EN    : in std_logic;
        Q     : out std_logic_vector(7 downto 0));
end prng;

architecture rtl of prng is
  signal VAL : unsigned(7 downto 0) := x"AC"; -- must be non-zero.
  signal SR : unsigned(7 downto 0);
begin
  Q <= std_logic_vector(VAL);
  SR <= VAL SRL 1;
  
  process(CLK)
  begin
    if rising_edge(CLK) then
      if EN = '1' then
        VAL <= SR;
        
        if VAL(0) = '1' then
          VAL <= SR XOR X"B4";
        end if;
      end if;
    end if;
  end process;
end rtl;