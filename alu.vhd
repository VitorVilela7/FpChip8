------------------------------------------------------------
-- CHIP-8 ALU
-- By Vitor Vilela (2018-11-02)
--
-- Circuit responsible for the most of the aritmetic
-- operations.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
   port( A     : in std_logic_vector(7 downto 0);
         B     : in std_logic_vector(7 downto 0);
         SEL   : in natural range 0 to 7;
         Q     : out std_logic_vector(7 downto 0);
         ZERO  : out std_logic;
         FLG   : out std_logic);
end alu;

architecture rtl of alu is
   signal X, Y, ADD1, SUB1, SUB2 : signed(8 downto 0);
   signal RES : std_logic_vector(7 downto 0);
begin
   X <= resize(signed(A), 9);
   Y <= resize(signed(B), 9);
   
   ADD1 <= X + Y;
   SUB1 <= X - Y;
   SUB2 <= Y - X;
   
   Q <= RES;
   ZERO <= '1' when RES = x"00" else '0';

   process(A, B, ADD1, SUB1, SUB2, SEL)
   begin
      FLG <= '-';
      
      case SEL is
         when 0 => RES <= A(6 downto 0) & "0"; FLG <= A(7);
         when 1 => RES <= A OR B;
         when 2 => RES <= A AND B;
         when 3 => RES <= A XOR B;
         when 4 => RES <= std_logic_vector(ADD1(7 downto 0)); FLG <= ADD1(8);
         when 5 => RES <= std_logic_vector(SUB1(7 downto 0)); FLG <= NOT SUB1(8);
         when 6 => RES <= "0" & A(7 downto 1); FLG <= A(0);
         when 7 => RES <= std_logic_vector(SUB2(7 downto 0)); FLG <= NOT SUB2(8);
      end case;
   end process;
end rtl;



