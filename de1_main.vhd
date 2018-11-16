------------------------------------------------------------
-- CHIP-8 Top-Entity and DE1 Board Entity
-- By Vitor Vilela (2018-11-15)
--
-- Requires a 4x4 Keypad hooked to GPIO_1 pins
-- 10, 12, 14, 16, 18, 20, 22 and 24.
--
-- A 250 Hz buzzer output is set at GPIO_0 pin 0.
--
-- The main CHIP-8 entity is chip8.vhd. Advised to use it in
-- case you're porting to already structured system.
--
-- Otherwise, if you're planning to port into other boards
-- straight way, edit and change this file.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity de1_main is
   port( CLOCK_50    : in std_logic;
         KEY         : in std_logic_vector(3 downto 0);
         SW          : in std_logic_vector(9 downto 0);
         GPIO_0      : out std_logic_vector(0 downto 0);         
         GPIO_1      : inout std_logic_vector(24 downto 10);
         HEX2        : out std_logic_vector(6 downto 0);
         HEX3        : out std_logic_vector(6 downto 0);
         HEX0        : out std_logic_vector(6 downto 0);
         HEX1        : out std_logic_vector(6 downto 0);
         LEDR        : out std_logic_vector(9 downto 0);
         LEDG        : out std_logic_vector(7 downto 0);
         VGA_HS		: out std_logic;
			VGA_VS		: out std_logic;
			VGA_R			: out std_logic_vector(3 downto 0);
			VGA_G			: out std_logic_vector(3 downto 0);
			VGA_B			: out std_logic_vector(3 downto 0));
end de1_main;

architecture rtl of de1_main is
   signal PROG_N, PROG_FLAG : std_logic;
   signal PROG_ADDR : std_logic_vector(11 downto 0);
   signal PROG_DATA, ZERO : std_logic_vector(7 downto 0);
   
   signal KEY_RES : std_logic_vector(15 downto 0);
   
   signal VIDEO_X : std_logic_vector(5 downto 0);
   signal VIDEO_Y : std_logic_vector(4 downto 0);
   signal VIDEO_OUT, BEEP_OUT : std_logic;
   
   signal R, G, B : std_logic_vector(3 downto 0);
   
   signal X_EN : std_logic;
   signal Y_EN : std_logic;
   signal X_ZERO : std_logic;
   signal Y_ZERO : std_logic;
   
   signal CHANGE_GAME : std_logic := '1';
   signal GAME_NUM : unsigned(5 downto 0) := to_unsigned(16#03#, 6); -- start with BOOT game...
   signal GAME_NUM_STD : std_logic_vector(7 downto 0);
   
   signal VIDEO_COLOR : std_logic_vector(1 downto 0);
   
   signal BASE_CNT : natural range 0 to 99999 := 0;
   signal BASE_250HZ : std_logic := '0';
   
   signal COL, LIN : std_logic_vector(3 downto 0);
   signal KEY_STABLE, KEY_ONCE, KEY_PREV : std_logic_vector(3 downto 0);
   
begin
   c8 : entity work.chip8 port map(CLOCK_50, KEY_RES, PROG_N, PROG_ADDR, PROG_DATA, VIDEO_X, VIDEO_Y, VIDEO_OUT, BEEP_OUT, PROG_FLAG);
   
   c8p : entity work.c8_progfull port map(CLOCK_50, CHANGE_GAME, GAME_NUM, PROG_FLAG, PROG_ADDR, PROG_DATA, PROG_N);
   
   vga : entity work.std_vga port map(CLOCK_50, R, G, B, open, open, X_EN, Y_EN, X_ZERO, Y_ZERO, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B);
   
   c8_to_vga : entity work.c8video_to_vga port map(CLOCK_50, X_EN, Y_EN, X_ZERO, Y_ZERO, VIDEO_COLOR, VIDEO_OUT, VIDEO_X, VIDEO_Y, R, G, B);

   -- Button input from GPIO_1:
   -- 10, 12, 14, 16, 18, 20, 22, 24
   COL(0) <= GPIO_1(10);
   GPIO_1(11) <= '0';
   COL(1) <= GPIO_1(12);
   GPIO_1(13) <= '0';
   COL(2) <= GPIO_1(14);
   GPIO_1(15) <= '0';
   COL(3) <= GPIO_1(16);
   GPIO_1(17) <= '0';
   GPIO_1(18) <= LIN(0);
   GPIO_1(19) <= '0';
   GPIO_1(20) <= LIN(1);
   GPIO_1(21) <= '0';
   GPIO_1(22) <= LIN(2);
   GPIO_1(23) <= '0';
   GPIO_1(24) <= LIN(3);
   
   pad : entity work.keypad port map(CLOCK_50, COL, LIN, KEY_RES);
   
   LEDR(9) <= PROG_N;
   LEDR(8) <= PROG_FLAG;
   LEDR(7 downto 0) <= (others => BEEP_OUT);
   LEDG <= (others => BEEP_OUT);
   
   GAME_NUM_STD <= "00" & std_logic_vector(GAME_NUM);
   ZERO <= x"00";
   
   h0 : entity work.hex_to_bcd port map(GAME_NUM_STD, HEX0, HEX1);
   h1 : entity work.hex_to_bcd port map(ZERO, HEX2, HEX3);
   
   
   process(CLOCK_50)
   begin
      if rising_edge(CLOCK_50) then
         -- Stabilize and swap key.
         KEY_STABLE <= NOT KEY;
         KEY_PREV <= KEY_STABLE;
         KEY_ONCE <= KEY_STABLE AND NOT KEY_PREV;
         
         if KEY_ONCE(3) = '1' then
            -- If key pressed, change video color.
            VIDEO_COLOR <= std_logic_vector(unsigned(VIDEO_COLOR) + 1);
         end if;
         
         CHANGE_GAME <= '0';
         
         if KEY_ONCE(2) = '1' then
            -- If key pressed, reprogram game...
            CHANGE_GAME <= '1';
         end if;
         
         if KEY_ONCE(1) = '1' then
            GAME_NUM <= GAME_NUM + 1;
            
            if GAME_NUM = 16#21# then
               GAME_NUM <= (others => '0');
            end if;
         elsif KEY_ONCE(0) = '1' then
            GAME_NUM <= (GAME_NUM - 1);
            
            if GAME_NUM = 0 then
               GAME_NUM <= to_unsigned(16#21#, 6);
            end if;
         end if;
      end if;
   end process;
   
   -- 250 Hz clock to output buzzer.
   GPIO_0(0) <= BASE_250HZ AND BEEP_OUT;
   
   process(CLOCK_50)
   begin
      if rising_edge(CLOCK_50) then
         BASE_CNT <= BASE_CNT + 1;
         
         if BASE_CNT = 99999 then
            BASE_CNT <= 0;
            BASE_250HZ <= NOT BASE_250HZ;
         end if;
      end if;
   end process;
end rtl;