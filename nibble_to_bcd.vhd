------------------------------------------------------------
-- 4-bit hexadecimal to BCD-HEX converter
-- By Vitor Vilela (2016-10-21)
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity nibble_to_bcd is
	port(	number	: in std_logic_vector(3 downto 0);
			bcd		: out std_logic_vector(6 downto 0));
end nibble_to_bcd;

architecture logic of nibble_to_bcd is
begin
	process(number)
	begin
		case number is
			when x"0" => bcd <= "1000000";
			when x"1" => bcd <= "1111001";
			when x"2" => bcd <= "0100100";
			when x"3" => bcd <= "0110000";
			when x"4" => bcd <= "0011001";
			when x"5" => bcd <= "0010010";
			when x"6" => bcd <= "0000010";
			when x"7" => bcd <= "1111000";
			when x"8" => bcd <= "0000000";
			when x"9" => bcd <= "0010000";
			when x"A" => bcd <= "0001000";
			when x"B" => bcd <= "0000011";
			when x"C" => bcd <= "1000110";
			when x"D" => bcd <= "0100001";
			when x"E" => bcd <= "0000110";
			when x"F" => bcd <= "0001110";
		end case;
	end process;
end logic;
