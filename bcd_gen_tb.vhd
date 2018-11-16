library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bcd_gen_tb is
end bcd_gen_tb;

architecture behavior of bcd_gen_tb is
  signal CLK, EN, DONE : std_logic := '0';
  signal DATA : std_logic_vector(7 downto 0);
  signal Q : std_logic_vector(9 downto 0);
  signal SUCCESS : std_logic := '0';
begin
  bcd : entity work.bcd_gen port map(CLK => CLK, EN => EN, DONE => DONE, DATA => DATA, Q => Q);
    
  CLK <= NOT CLK after 5 ns;
    
  process
  begin
    wait until rising_edge(CLK);
    
    SUCCESS <= '0';
    EN <= '1';
    
    for I in 0 to 255 loop
      DATA <= std_logic_vector(to_unsigned(I, 8));
      wait for 10 ns;
      EN <= '0';
      
      loop
        wait for 10 ns;
        exit when DONE = '1';
      end loop;
      
      EN <= '1';
      
      --assert (DONE = '1') report "Time out" severity error;
      assert (unsigned(Q(3 downto 0)) = (I REM 10)) report "Ones wrong" severity error;
      assert (unsigned(Q(7 downto 4)) = ((I / 10) REM 10)) report "Tens wrong" severity error;
      assert (unsigned(Q(9 downto 8)) = ((I / 100) REM 10)) report "100s wrong" severity error;        
    end loop;
    
    SUCCESS <= '1';
    wait;
  end process;
  
end behavior;
