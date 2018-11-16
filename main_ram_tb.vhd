library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity main_ram_tb is
end main_ram_tb;

architecture tester of main_ram_tb  is
  signal CLK, WE : std_logic := '0';
   signal ADDR : natural range 0 to 4095;
   signal L, Q : std_logic_vector(7 downto 0);
begin
   CLK <= NOT CLK after 10 ns;
   
   ram : entity work.main_ram port map(CLK, WE, ADDR, L, Q);
   
   process
   begin
     wait until rising_edge(CLK);
     
     ADDR <= 0;
     L <= x"FF"; -- arbitrary data...
     wait until rising_edge(CLK);
     
     for I in 1 to 16 loop
       ADDR <= I;
       L <= std_logic_vector(to_unsigned(I, 8));
       WE <= '1';
       wait until rising_edge(CLK);
     end loop;
     
     ADDR <= 7;
     L <= x"FF"; -- arbitrary data...
     WE <= '0';
     wait until rising_edge(CLK);
     
     ADDR <= 0;
     wait until rising_edge(CLK);
     
     for I in 1 to 16 loop
       ADDR <= I;
       
       assert Q = std_logic_vector(to_unsigned(I, 8)) report
        "Data mismatch! => " & integer'image(to_integer(unsigned(Q))) & " " & integer'image(I) severity warning;
        
       wait until rising_edge(CLK);
     end loop;
     
     wait;
   end process;
end tester;