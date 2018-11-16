library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

entity c8_programmer is
   port( CLK         : in std_logic;
         START       : in std_logic;
         PROG_FLAG   : in std_logic;
         PROG_ADDR   : out std_logic_vector(11 downto 0);
         PROG_DATA   : out std_logic_vector(7 downto 0);
         PROG_N      : out std_logic);
end c8_programmer;

architecture rtl of c8_programmer is
   -- Uploader State Machine ...
   type state_t is ( s_idle, s_wait, s_program, s_end );   
   signal CURRENT_STATE, STATE : state_t;
   
   -- ROM structure
   type rom_t is array (natural range <>) of std_logic_vector(7 downto 0);
   
   constant font : rom_t(0 to 79) := (
        x"F0", x"90", x"90", x"90", x"F0", -- 0
        x"20", x"60", x"20", x"20", x"70", -- 1
        x"F0", x"10", x"F0", x"80", x"F0", -- 2
        x"F0", x"10", x"F0", x"10", x"F0", -- 3
        x"90", x"90", x"F0", x"10", x"10", -- 4
        x"F0", x"80", x"F0", x"10", x"F0", -- 5
        x"F0", x"80", x"F0", x"90", x"F0", -- 6
        x"F0", x"10", x"20", x"40", x"40", -- 7
        x"F0", x"90", x"F0", x"90", x"F0", -- 8
        x"F0", x"90", x"F0", x"10", x"F0", -- 9
        x"F0", x"90", x"F0", x"90", x"90", -- A
        x"E0", x"90", x"E0", x"90", x"E0", -- B
        x"F0", x"80", x"80", x"80", x"F0", -- C
        x"E0", x"90", x"90", x"90", x"E0", -- D
        x"F0", x"80", x"F0", x"80", x"F0", -- E
        x"F0", x"80", x"F0", x"80", x"80"  -- F
   );
   
	constant program : rom_t(0 to 132) := (
		x"A2", x"5B", x"60", x"0B", x"61", x"03", x"62", x"07",
		x"D0", x"17", x"70", x"07", x"F2", x"1E", x"D0", x"17",
		x"70", x"07", x"F2", x"1E", x"D0", x"17", x"70", x"07",
		x"F2", x"1E", x"D0", x"17", x"70", x"07", x"F2", x"1E",
		x"D0", x"17", x"70", x"05", x"F2", x"1E", x"D0", x"17",
		x"F2", x"1E", x"A2", x"5A", x"C0", x"3F", x"C1", x"1F",
		x"62", x"01", x"63", x"01", x"D0", x"11", x"64", x"02",
		x"F4", x"15", x"F4", x"07", x"34", x"00", x"12", x"3A",
		x"D0", x"11", x"80", x"24", x"81", x"34", x"D0", x"11",
		x"41", x"00", x"63", x"01", x"41", x"1F", x"63", x"FF",
		x"40", x"00", x"62", x"01", x"40", x"3F", x"62", x"FF",
		x"12", x"36", x"80", x"78", x"CC", x"C0", x"C0", x"C0",
		x"CC", x"78", x"CC", x"CC", x"CC", x"FC", x"CC", x"CC",
		x"CC", x"FC", x"30", x"30", x"30", x"30", x"30", x"FC",
		x"F8", x"CC", x"CC", x"F8", x"C0", x"C0", x"C0", x"00",
		x"00", x"00", x"F0", x"00", x"00", x"00", x"78", x"CC",
		x"CC", x"78", x"CC", x"CC", x"78"
	);

   -- ROM data
   function init_rom return rom_t is
      variable output : rom_t(0 to 4095) := (others => (others => '0'));
   begin
      output(0 to 79) := font;
      output(512 to program'right+512) := program;
      return output;
   end init_rom;
   
   -- ROM signal
   signal ROM : rom_t(0 to 4095) := init_rom;
   
   -- internal ADDR
   signal ADDR : unsigned(12 downto 0);
   
   signal ADDR_RST : std_logic;
   signal ADDR_END : std_logic;
begin
   
   PROG_ADDR <= std_logic_vector(ADDR(11 downto 0));
   
   ADDR_END <= '1' when ADDR(12) = '1' else '0';

   -- Moore State Machine
   process(CURRENT_STATE, START, PROG_FLAG, ADDR_END)
   begin
      PROG_N <= '0';
      ADDR_RST <= '1';
      
      case CURRENT_STATE is
         when s_idle =>
            PROG_N <= '1';
            
            if START = '1' then
               STATE <= s_wait;
            else
               STATE <= s_idle;
            end if;
            
         when s_wait =>
            if PROG_FLAG = '1' then
               STATE <= s_program;
            else
               STATE <= s_wait;
            end if;
         
         when s_program =>
            STATE <= s_program;
            ADDR_RST <= '0';
            
            if ADDR_END = '1' then
               STATE <= s_end;
            end if;
            
         when s_end =>
            PROG_N <= '1';
            
            if START = '1' then
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
         else
            ADDR <= ADDR + 1;
         end if;
      end if;
   end process;

   process(CLK)
   begin
      if rising_edge(CLK) then
         CURRENT_STATE <= STATE;
         PROG_DATA <= ROM(to_integer(ADDR(11 downto 0)));
      end if;
   end process;
end rtl;   