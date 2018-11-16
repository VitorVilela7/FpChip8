library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

entity chip8_tb is
end chip8_tb;

architecture tester of chip8_tb is
   signal CLK, PROG_N, PROG_FLAG : std_logic := '0';
   signal PROG_ADDR : std_logic_vector(11 downto 0);
   signal PROG_DATA : std_logic_vector(7 downto 0);
   signal KEY : std_logic_vector(15 downto 0);
   
   signal OUT_X : std_logic_vector(5 downto 0);
   signal OUT_Y : std_logic_vector(4 downto 0);
   signal OUT_PIXEL : std_logic;
begin
   c8 : entity work.chip8 port map(CLK, KEY, PROG_N, PROG_ADDR, PROG_DATA, OUT_X, OUT_Y, OUT_PIXEL, PROG_FLAG);
   CLK <= NOT CLK after 10 ns;
   
  screen_render : process
    variable screen : string(1 to 65*32);
  begin
    -- Latch
    wait for 100 us;
    
    -- Render process.
    wait for 50 ns;
    wait until rising_edge(CLK);
  
    for Y in 0 to 31 loop
      for X in 0 to 63 loop
        OUT_X <= std_logic_vector(to_unsigned(X, 6));
        OUT_Y <= std_logic_vector(to_unsigned(Y, 5));
        
        wait for 1 ns; wait until rising_edge(CLK); wait for 1 ns;
        
        if OUT_PIXEL = '0' then
          screen(Y*65+X+1) := '.';
        else
          screen(Y*65+X+1) := '@';
        end if;
      end loop;
      
      screen(Y*65+65) := cr;
    end loop;
    
    wait for 1 ns;
    report "SCREEN: " & cr & screen;
  end process;
   
  process
     type uarray is array(natural range<>) of std_logic_vector(7 downto 0);
     type t_char_file is file of character;
     
     variable data : uarray(0 to 255);
     
     file file_in : t_char_file open read_mode is "test.bin";
     variable char_buf : character;
   begin
     -- load file and feed to data...
     for I in data'range loop
       read(file_in, char_buf);
       data(i) := std_logic_vector(to_unsigned(character'pos(char_buf), 8));
     end loop;
     
     file_close(file_in);
     
     PROG_N <= '0';
     PROG_ADDR <= (others => '0');
     PROG_DATA <= (others => '0');
     
     wait until CLK'event and CLK = '1';
     
     while (PROG_FLAG = '0') loop
       wait for 20 ns;
     end loop;
     
     PROG_ADDR <= x"200";
     
     wait for 20 ns;
     
     for I in 0 to 255 loop
       PROG_ADDR <= std_logic_vector(to_unsigned(I+1+512, 12));
       PROG_DATA <= data(I);
       wait for 20 ns;
     end loop;
     
     -- end program.
     PROG_N <= '1';
     
     wait;
   end process;
end tester;
