library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mem_flow is
   port( PROG_N         : in std_logic;
         WRITE_EN       : in std_logic;
         MEM_ADDR_SEL   : in std_logic;
         BCD_STORE      : in std_logic;
         BCD            : in std_logic_vector(9 downto 0);
         VX_VAL         : in std_logic_vector(7 downto 0);
         PROG_DATA      : in std_logic_vector(7 downto 0);
         PROG_ADDR      : in std_logic_vector(11 downto 0);
         I_VAL          : in std_logic_vector(11 downto 0);
         PC_VAL         : in std_logic_vector(11 downto 0);
         COUNTER        : in std_logic_vector(3 downto 0);
         COUNTER_DELAY  : in std_logic_vector(3 downto 0);
         MEM_WE         : out std_logic;
         MEM_ADDR       : out unsigned(11 downto 0);
         MEM_LOAD       : out std_logic_vector(7 downto 0));
end mem_flow;

architecture rtl of mem_flow is
   -- Type declarations
   type nibble_t is array (natural range <>) of std_logic_vector(3 downto 0);
     
   -- BCD signals
   signal BCD_MUX : nibble_t(0 to 3);
begin
   BCD_MUX(0) <= "00" & BCD(9 downto 8);
   BCD_MUX(1) <= BCD(7 downto 4);
   BCD_MUX(2) <= BCD(3 downto 0);
   BCD_MUX(3) <= (others => '-'); -- This may be loaded during simulation but no store is made.
   
   MEM_LOAD <= PROG_DATA when PROG_N = '0' else VX_VAL when BCD_STORE = '0' else x"0" & BCD_MUX(to_integer(unsigned(COUNTER_DELAY)));
   
   MEM_ADDR <= unsigned(PROG_ADDR) when PROG_N = '0' else
      unsigned(PC_VAL) when MEM_ADDR_SEL = '0' else unsigned(I_VAL) + unsigned(COUNTER);
   
   MEM_WE <= WRITE_EN OR (NOT PROG_N);
   
end rtl;