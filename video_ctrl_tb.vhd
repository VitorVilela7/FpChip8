library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_ctrl_tb is
end video_ctrl_tb;

architecture behavior of video_ctrl_tb is
  signal CLK, CLS, EN : std_logic := '0';
  signal X_LOAD : std_logic_vector(5 downto 0);
  signal Y_LOAD : std_logic_vector(4 downto 0);
  signal LINES : std_logic_vector(3 downto 0);
  signal MEM_LOAD : std_logic_vector(7 downto 0);
  signal HIT, DONE : std_logic;
  
  signal OUT_X : std_logic_vector(5 downto 0) := "000000";
  signal OUT_Y : std_logic_vector(4 downto 0) := "00000";
  signal OUT_PIXEL : std_logic;
begin
  video : entity work.video_main port map(CLK,CLS,EN,X_LOAD,Y_LOAD,LINES,MEM_LOAD,OUT_X,OUT_Y,OUT_PIXEL,HIT,DONE);
  
  CLK <= NOT CLK after 10 ns;

  screen_render : process
    variable screen : string(1 to 65*32);
  begin
    -- Latch
    wait until rising_edge(DONE);
    
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
    type arr_t is array(natural range <>) of std_logic_vector(7 downto 0);
    variable sprite : arr_t(0 to 14) := ( x"F0", x"90", x"F0", x"10", x"F0", x"80", x"40", x"20", x"10", x"08", x"04", x"02", x"01", x"82", x"0F" );
  begin
    for P in 0 to 0 loop
    wait until rising_edge(CLK);
    
    EN <= '1';
    CLS <= '0';
    LINES <= x"F";
    X_LOAD <= "000000";
    Y_LOAD <= "00100";
    
    wait for 1 ns; wait until rising_edge(CLK); wait for 1 ns;
    
    EN <= '0';
    
    -- render '9'
    -- 0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    for X in 0 to 14 loop
      MEM_LOAD <= sprite(X);
    
      for I in 0 to 16 loop
        wait for 1 ns; wait until rising_edge(CLK); wait for 1 ns;
        MEM_LOAD <= (others => 'X');
      end loop;
    end loop;
  end loop;
    
    wait;
    
  end process;
end behavior;