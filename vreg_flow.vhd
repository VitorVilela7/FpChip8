library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vreg_flow is
   port( CLK                  : in std_logic;
         ALU_FLG_EN           : in std_logic;
         ALU_FLG_LOAD         : in std_logic;
         VIDEO_SPR_COLLIDE    : in std_logic;
         VX_SEL               : in natural range 0 to 3;
         VX_LOAD_SEL          : in natural range 0 to 7;
         IR_VAL               : in std_logic_vector(7 downto 0);
         MEM_VAL              : in std_logic_vector(7 downto 0);
         ALU_VAL              : in std_logic_vector(7 downto 0);
         DT_VAL               : in std_logic_vector(7 downto 0);
         VY_VAL               : in std_logic_vector(7 downto 0);
         COUNTER_DELAY        : in std_logic_vector(3 downto 0);
         KEY_NUM              : in std_logic_vector(3 downto 0);
         VX_LOAD              : out std_logic_vector(7 downto 0);
         VX_ADDR              : out natural range 0 to 15;
         VY_ADDR              : out natural range 0 to 15);
end vreg_flow;

architecture rtl of vreg_flow is
   signal ALU_FLG : std_logic;
begin
   process(CLK)
   begin
      if rising_edge(CLK) then
         if ALU_FLG_EN = '1' then
            ALU_FLG <= ALU_FLG_LOAD;
         end if;
      end if;
   end process;
   
   VY_ADDR <= to_integer(unsigned(MEM_VAL(7 downto 4)));
   
   with VX_SEL select
      VX_ADDR <= to_integer(unsigned(IR_VAL(3 downto 0))) when 0,
      0 when 1,
      15 when 2,
      to_integer(unsigned(COUNTER_DELAY)) when 3;
      
   with VX_LOAD_SEL select
      VX_LOAD <=  MEM_VAL when 0,
                  ALU_VAL when 1,
                  DT_VAL when 2, -- DT
                  x"0" & KEY_NUM when 3, -- K (KEY)
                  x"0" & "000" & ALU_FLG when 4, -- ALU FLG
                  VY_VAL when 5, -- Vy
                  x"0" & "000" & VIDEO_SPR_COLLIDE when 6, -- VIDEO COLLIDE
                  (others => '-') when others;
end rtl;