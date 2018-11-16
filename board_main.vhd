library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity board_main is
   port( CLOCK_50    : in std_logic;
         KEY         : in std_logic_vector(3 downto 0);
         SW          : in std_logic_vector(9 downto 0);
         LEDR        : out std_logic_vector(9 downto 0);
         LEDG        : out std_logic_vector(7 downto 0);
         VGA_HS		: out std_logic;
			VGA_VS		: out std_logic;
			VGA_R			: out std_logic_vector(3 downto 0);
			VGA_G			: out std_logic_vector(3 downto 0);
			VGA_B			: out std_logic_vector(3 downto 0));
end board_main;

architecture rtl of board_main is
   signal PROG_N, PROG_FLAG : std_logic;
   signal PROG_ADDR : std_logic_vector(11 downto 0);
   signal PROG_DATA : std_logic_vector(7 downto 0);
   
   signal SW_PAD : std_logic_vector(1 downto 0);
   signal KEY_RES : std_logic_vector(15 downto 0);
   
   signal VIDEO_X : std_logic_vector(5 downto 0);
   signal VIDEO_Y : std_logic_vector(4 downto 0);
   signal VIDEO_OUT, BEEP_OUT : std_logic;
   
   signal R, G, B : std_logic_vector(3 downto 0);
   
   signal X_EN : std_logic;
   signal Y_EN : std_logic;
   signal X_ZERO : std_logic;
   signal Y_ZERO : std_logic;
   
   signal VIDEO_COLOR : std_logic_vector(1 downto 0);
begin
   c8 : entity work.chip8 port map(CLOCK_50, KEY_RES, PROG_N, PROG_ADDR, PROG_DATA, VIDEO_X, VIDEO_Y, VIDEO_OUT, BEEP_OUT, PROG_FLAG);
   
   c8p : entity work.c8_progfull port map(CLOCK_50, SW(9), SW(8 downto 3), PROG_FLAG, PROG_ADDR, PROG_DATA, PROG_N);
   
   vga : entity work.std_vga port map(CLOCK_50, R, G, B, open, open, X_EN, Y_EN, X_ZERO, Y_ZERO, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B);
   
   c8_to_vga : entity work.c8video_to_vga port map(CLOCK_50, X_EN, Y_EN, X_ZERO, Y_ZERO, VIDEO_COLOR, VIDEO_OUT, VIDEO_X, VIDEO_Y, R, G, B);

   key_ctrl : entity work.alt_keypad port map(CLOCK_50, SW_PAD, KEY, KEY_RES);

   SW_PAD <= SW(1 downto 0);
   
   LEDR(9) <= PROG_FLAG;
   LEDR(8) <= PROG_N;
   LEDR(7 downto 0) <= (others => BEEP_OUT);
   LEDG <= PROG_DATA;
   
   VIDEO_COLOR <= SW(3 downto 2);
end rtl;