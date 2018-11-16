library IEEE;
use IEEE.std_logic_1164.all;

entity vreg is
   port( CLK      : in std_logic;
         RST      : in std_logic;
         EN       : in std_logic;
         ADDRX    : in natural range 0 to 15;
         ADDRY    : in natural range 0 to 15;
         L        : in std_logic_vector(7 downto 0);
         X        : out std_logic_vector(7 downto 0);
         Y        : out std_logic_vector(7 downto 0));
end vreg;

architecture rtl of vreg is
   type int_array is array (0 to 15) of std_logic_vector(7 downto 0);
   signal regs : int_array;
   
   signal REG_EN : std_logic_vector(15 downto 0);
begin
   X <= regs(ADDRX);
   Y <= regs(ADDRY);
   
   process(ADDRX)
   begin
      REG_EN <= (others => '0');
      REG_EN(ADDRX) <= '1';
   end process;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         for I in 0 to 15 loop
            if REG_EN(I) = '1' AND EN = '1' then
               regs(I) <= L;
            end if;
         end loop;
         
         if RST = '1' then
            regs <= (others => (others => '0'));
         end if;
      end if;
   end process;
end rtl;