library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

entity c8_progfull is
   port( CLK         : in std_logic;
         START       : in std_logic;
         GM_SEL      : in std_logic_vector(5 downto 0);
         PROG_FLAG   : in std_logic;
         PROG_ADDR   : out std_logic_vector(11 downto 0);
         PROG_DATA   : out std_logic_vector(7 downto 0);
         PROG_N      : out std_logic);
end c8_progfull;

architecture rtl of c8_progfull is
   -- Uploader State Machine ...
   type state_t is ( s_idle, s_wait, s_font, s_program_init, s_program, s_end );   
   signal CURRENT_STATE, STATE : state_t;
   
   -- Data structures.
   type nib_t is array (natural range <>) of std_logic_vector(3 downto 0);
   type word_t is array (natural range <>) of std_logic_vector(15 downto 0);
   
   -- ROM table. Use romtb utility if you wish to change the builtin ROMs.
	signal table : word_t(0 to 63) := (
		x"0000", x"0180", x"0AB4", x"0C3B", x"0CC0", x"0DD8", x"114A", x"120C",
		x"12A0", x"15F2", x"1676", x"1B79", x"1BF1", x"1C63", x"1C89", x"1DE2",
		x"1E96", x"1FBC", x"20C4", x"217C", x"23BE", x"23E0", x"31DE", x"32DF",
		x"36A7", x"3A59", x"3C89", x"3E77", x"405D", x"4CE0", x"4DC0", x"4FBB",
		x"50A1", x"5186", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF",
		x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF",
		x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF",
		x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF"
	);
   
   -- Base font. Only high nibble is uploaded.
   signal FONT : nib_t(0 to 127) := (
        x"F", x"9", x"9", x"9", x"F", -- 0
        x"2", x"6", x"2", x"2", x"7", -- 1
        x"F", x"1", x"F", x"8", x"F", -- 2
        x"F", x"1", x"F", x"1", x"F", -- 3
        x"9", x"9", x"F", x"1", x"1", -- 4
        x"F", x"8", x"F", x"1", x"F", -- 5
        x"F", x"8", x"F", x"9", x"F", -- 6
        x"F", x"1", x"2", x"4", x"4", -- 7
        x"F", x"9", x"F", x"9", x"F", -- 8
        x"F", x"9", x"F", x"1", x"F", -- 9
        x"F", x"9", x"F", x"9", x"9", -- A
        x"E", x"9", x"E", x"9", x"E", -- B
        x"F", x"8", x"8", x"8", x"F", -- C
        x"E", x"9", x"9", x"9", x"E", -- D
        x"F", x"8", x"F", x"8", x"F", -- E
        x"F", x"8", x"F", x"8", x"8", -- F
        
        x"0", x"0", x"0", x"0", x"0", -- fill rest of space with zeros.
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0", x"0", x"0", 
        x"0", x"0", x"0"
   );
   
   signal ADDR : unsigned(12 downto 0);
   signal IADDR : natural range 0 to 32767;
   
   signal ADDR_RST, ADDR_START, LOW_PTR, HI_PTR : std_logic;
   signal ADDR_END, FONT_END, GM_INDEX : std_logic;
   
   signal FONT_Q : std_logic_vector(3 downto 0);
   signal PROG_Q : std_logic_vector(7 downto 0);
   
   signal ADDR_BASE : std_logic_vector(15 downto 0);
   
   signal START_COPY, START_COPY2 : std_logic;
   
   signal SOURCE : std_logic;
begin
   boot_rom : entity work.c8_prog_rom port map(CLK, IADDR, PROG_Q);
   
   IADDR <= to_integer(unsigned(ADDR_BASE)) + to_integer(ADDR) - 512;
   
   PROG_ADDR <= std_logic_vector(ADDR(11 downto 0));
   
   ADDR_END <= '1' when ADDR(12) = '1' else '0';
   
   FONT_END <= '1' when ADDR(7) = '1' else '0';
   
   PROG_DATA <= FONT_Q & "0000" when SOURCE = '1' else PROG_Q;

   -- Moore State Machine
   -- TO DO: extra steps s_clear (zero 000-FFF), s_font (overwrite first 80 bytes), s_program (0x200 and ahead.)
   process(CURRENT_STATE, START_COPY2, PROG_FLAG, ADDR_END, FONT_END)
   begin
      PROG_N <= '0';
      ADDR_RST <= '1';
      ADDR_START <= '0';
      SOURCE <= '0';
      
      case CURRENT_STATE is
         when s_idle =>
            PROG_N <= '1';
            
            if START_COPY2 = '1' then
               STATE <= s_wait;
            else
               STATE <= s_idle;
            end if;
            
         when s_wait =>
            if PROG_FLAG = '1' then
               STATE <= s_font;
            else
               STATE <= s_wait;
            end if;
           
         when s_font =>
            SOURCE <= '1';
            STATE <= s_font;
            ADDR_RST <= '0';
            
            if FONT_END = '1' then
               STATE <= s_program_init;
            end if;
            
         when s_program_init =>
            ADDR_START <= '1';
            ADDR_RST <= '0';
            STATE <= s_program;
            
         when s_program =>
            STATE <= s_program;
            ADDR_RST <= '0';
            
            if ADDR_END = '1' then
               STATE <= s_end;
            end if;
            
         when s_end =>
            PROG_N <= '1';
            
            if START_COPY2 = '1' then
               STATE <= s_end;
            else
               STATE <= s_idle;
            end if;
            
      end case;
   end process;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if ADDR_RST = '1' then
            ADDR <= (others => '0');
         elsif ADDR_START = '1' then
            ADDR <= "0" & x"200";
         else
            ADDR <= ADDR + 1;
         end if;
      end if;
   end process;

   process(CLK)
   begin
      if rising_edge(CLK) then
         CURRENT_STATE <= STATE;
         FONT_Q <= FONT(to_integer(ADDR(6 downto 0)));
         ADDR_BASE <= TABLE(to_integer(unsigned(GM_SEL)));
         START_COPY <= START;
         START_COPY2 <= START_COPY;
      end if;
   end process;
end rtl;   