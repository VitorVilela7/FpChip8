library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity c8video_to_vga is
   port( CLK         : in std_logic;
         X_EN        : in std_logic;
         Y_EN        : in std_logic;
         X_ZERO      : in std_logic;
         Y_ZERO      : in std_logic;
         COLOR       : in std_logic_vector(1 downto 0);
         VIDEO_OUT   : in std_logic;
         VIDEO_X     : out std_logic_vector(5 downto 0);
         VIDEO_Y     : out std_logic_vector(4 downto 0);
         R           : out std_logic_vector(3 downto 0);
         G           : out std_logic_vector(3 downto 0);
         B           : out std_logic_vector(3 downto 0));
end c8video_to_vga;

architecture rtl of c8video_to_vga is
   signal C8_X : unsigned(5 downto 0);
   signal C8_Y : unsigned(5 downto 0);
   signal CNT : natural range 0 to 9;
   signal CNT_Y : natural range 0 to 9;
   signal OUTPUT : std_logic;
   signal RGB : std_logic_vector(11 downto 0);
begin
   R <= RGB(11 downto 8);
   G <= RGB(7 downto 4);
   B <= RGB(3 downto 0);
   
   VIDEO_X <= std_logic_vector(C8_X(5 downto 0));
   VIDEO_Y <= std_logic_vector(resize(C8_Y(5 downto 0) - 8, 5));
   
   OUTPUT <= '1' when C8_Y >= 8 and C8_Y <= 32+8-1 else '0';
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if X_EN = '1' then
            CNT <= CNT + 1;
            
            if CNT = 9 then
               CNT <= 0;
               C8_X <= C8_X + 1;
            end if;
         end if;
         
         if Y_EN = '1' then
            CNT_Y <= CNT_Y + 1;
                  
            if CNT_Y = 9 then
               CNT_Y <= 0;
               C8_Y <= C8_Y + 1;
               
               if C8_Y = 47 then
                  C8_Y <= (others => '0');
               end if;
            end if;
         end if;
      end if;
   end process;
   
   process(VIDEO_OUT, OUTPUT, COLOR)
   begin
      if OUTPUT = '0' then
         RGB <= x"234";
      elsif VIDEO_OUT = '1' then
         case COLOR is
            when "00" => RGB <= x"182"; -- Green
            when "01" => RGB <= x"14B"; -- Blue
            when "10" => RGB <= x"700"; -- Red
            when "11" => RGB <= x"888"; -- Gray
            
            when others => RGB <= (others => '-'); -- null
         end case;
      else
         RGB <= x"000";
      end if;
   end process;
end rtl;