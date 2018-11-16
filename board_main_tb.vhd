library IEEE;
use IEEE.std_logic_1164.all;

entity board_main_tb is
end board_main_tb;

architecture behavior of board_main_tb is
  signal CLOCK_50 : std_logic := '0';
  signal KEY     : std_logic_vector(3 downto 0);
  signal SW      : std_logic_vector(9 downto 0);
  signal LEDR    : std_logic_vector(9 downto 0);
  signal VGA_HS		: std_logic;
	signal VGA_VS		: std_logic;
	signal VGA_R			: std_logic_vector(3 downto 0);
	signal VGA_G			: std_logic_vector(3 downto 0);
	signal VGA_B			: std_logic_vector(3 downto 0);
begin
  b : entity work.board_main port map(CLOCK_50, KEY, SW, LEDR,
    VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B); 
    
  SW(9) <= '1';
    
  CLOCK_50 <= NOT CLOCK_50 after 10 ns;
end behavior;
