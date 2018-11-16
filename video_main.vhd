library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_main is
   port( CLK         : in std_logic;
         SCREEN_CLS  : in std_logic;
         SPR_EN      : in std_logic;
         SPR_X       : in std_logic_vector(5 downto 0);
         SPR_Y       : in std_logic_vector(4 downto 0);
         SPR_SIZE    : in std_logic_vector(3 downto 0);
         SPR_DATA    : in std_logic_vector(7 downto 0);
         OUT_X       : in std_logic_vector(5 downto 0);
         OUT_Y       : in std_logic_vector(4 downto 0);
         OUT_PIXEL   : out std_logic;
         SPR_COLLIDE : out std_logic;
         DATA_READY  : out std_logic);
end video_main;

architecture rtl of video_main is
   signal LINE_EN, COL_EN : std_logic;
   signal X_END, Y_END, LINE_END, TILE_END : std_logic;
   signal MEM_EN, MEM_SEL : std_logic;
   signal COLLIDE, COL_TILE_RST : std_logic;
   signal P_IN, P_OUT, WE : std_logic;
   signal X : std_logic_vector(5 downto 0);
   signal Y : std_logic_vector(4 downto 0);
begin
   memory : entity work.video_ram port map(
      CLK => CLK,
      X_IN => X,
      Y_IN => Y,
      DATA_IN => P_OUT,
      DATA_EN => WE,
      X_OUT => OUT_X,
      Y_OUT => OUT_Y,
      PREV_DATA => P_IN,
      DATA_OUT => OUT_PIXEL
   );

   data_path : entity work.video_flow port map(
         CLK => CLK,
         CLS => SCREEN_CLS,
         EN => SPR_EN,
         X_LOAD => SPR_X,
         Y_LOAD => SPR_Y,
         LINES => SPR_SIZE,
         MEM_LOAD => SPR_DATA,
         LINE_EN => LINE_EN,
         COL_EN => COL_EN,
         MEM_EN => MEM_EN,
         COL_TILE_RST => COL_TILE_RST,
         COLLIDE => COLLIDE,
         X_END => X_END,
         Y_END => Y_END,
         LINE_END => LINE_END,
         TILE_END => TILE_END,
         MEM_SEL => MEM_SEL,
         HIT => SPR_COLLIDE,
         X => X,
         Y => Y
   );
   
   controller : entity work.video_ctrl port map(
      CLK => CLK,
      CLS => SCREEN_CLS,
      EN => SPR_EN,
      P_IN => P_IN,
      MEM_SEL => MEM_SEL,
      TILE_END => TILE_END,
      LINE_END => LINE_END,
      X_END => X_END,
      Y_END => Y_END,
      LINE_EN => LINE_EN,
      COL_TILE_RST => COL_TILE_RST,
      COL_EN => COL_EN,
      MEM_EN => MEM_EN,
      P_OUT => P_OUT,
      WE => WE,
      COLLIDE => COLLIDE,
      DONE => DATA_READY
   );
end rtl;