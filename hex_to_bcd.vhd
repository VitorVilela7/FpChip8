------------------------------------------------------------
-- 8-bit hexadecimal to BCD-HEX converter
-- By Vitor Vilela (2016-10-21)
--
-- Requirs nibble_to_bcd.vhd for 4-bit partial conversion.
------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

entity hex_to_bcd is
	port(	number					: in std_logic_vector(7 downto 0);
			nibble_l, nibble_h	: out std_logic_vector(6 downto 0));
end hex_to_bcd;

architecture logic of hex_to_bcd is
begin
	low_byte  : entity work.nibble_to_bcd port map(number(3 downto 0), nibble_l);
	high_byte : entity work.nibble_to_bcd port map(number(7 downto 4), nibble_h);
end logic;