------------------------------------------------------------
-- CHIP-8 Video Data Path
-- By Vitor Vilela (2018-11-03)
--
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_flow is
   port( CLK            : in std_logic;
         CLS            : in std_logic;
         EN             : in std_logic;
         X_LOAD         : in std_logic_vector(5 downto 0);
         Y_LOAD         : in std_logic_vector(4 downto 0);
         LINES          : in std_logic_vector(3 downto 0);
         MEM_LOAD       : in std_logic_vector(7 downto 0);
         LINE_EN        : in std_logic;
         COL_EN         : in std_logic;
         MEM_EN         : in std_logic;
         COL_TILE_RST   : in std_logic;
         COLLIDE        : in std_logic;
         X_END          : out std_logic;
         Y_END          : out std_logic;
         LINE_END       : out std_logic;
         TILE_END       : out std_logic;
         MEM_SEL        : out std_logic;
         HIT            : out std_logic;
         X              : out std_logic_vector(5 downto 0);
         Y              : out std_logic_vector(4 downto 0));
end video_flow;

architecture rtl of video_flow is
   signal LINE_RST, COL_RST : std_logic;
   signal LINE_MAX : std_logic_vector(3 downto 0);
   signal X_OUT : unsigned(5 downto 0);
   signal Y_OUT : unsigned(4 downto 0);
   signal COL_CNT, X_LOAD_F : std_logic_vector(5 downto 0);
   signal LINE_CNT, Y_LOAD_F : std_logic_vector(4 downto 0);
   signal Y_TMP : unsigned(5 downto 0);
   signal X_RST, Y_RST : std_logic;
   signal MEM_COPY : std_logic_vector(7 downto 0);
   signal COLLISION : std_logic;
begin
   HIT <= COLLISION;
   
   MEM_SEL <= MEM_COPY(to_integer(unsigned(COL_CNT(2 downto 0)) XOR "111"));
   
   LINE_END <= '1' when LINE_CNT(3 downto 0) = LINE_MAX OR Y_TMP(5) = '1' else '0';
   TILE_END <= '1' when COL_CNT(2 downto 0) = "111" else '0';
   
   X_END <= '1' when COL_CNT = "111111" else '0';
   Y_END <= '1' when LINE_CNT = "11111" else '0';
   
   X <= std_logic_vector(X_OUT);
   Y <= std_logic_vector(Y_OUT);
   
   X_OUT <= unsigned(X_LOAD_F) + unsigned(COL_CNT);
   
   Y_TMP <= resize(unsigned(Y_LOAD_F), 6) + resize(unsigned(LINE_CNT), 6);
   Y_OUT <= Y_TMP(4 downto 0);
   
   X_RST <= CLS;
   Y_RST <= CLS;
   
   COL_RST <= CLS OR EN OR COL_TILE_RST;
   LINE_RST <= CLS OR EN;
   
   v_counter : entity work.counter generic map(5) port map(CLK, LINE_EN, LINE_RST, LINE_CNT);
   h_counter : entity work.counter generic map(6) port map(CLK, COL_EN, COL_RST, COL_CNT);
   
   v_max : entity work.regn generic map(4) port map(CLK, '0', EN, LINES, LINE_MAX);
   
   x_pos : entity work.regn generic map(6) port map(CLK, X_RST, EN, X_LOAD, X_LOAD_F);
   y_pos : entity work.regn generic map(5) port map(CLK, Y_RST, EN, Y_LOAD, Y_LOAD_F);
   
   mem : entity work.regn generic map(8) port map(CLK, '0', MEM_EN, MEM_LOAD, MEM_COPY);
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if EN = '1' then
            COLLISION <= '0';
         else
            COLLISION <= COLLISION OR COLLIDE;
         end if;
      end if;
   end process;
end rtl;