library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity video_ctrl is
   port( CLK            : in std_logic;
         CLS            : in std_logic;
         EN             : in std_logic;
         P_IN           : in std_logic;
         MEM_SEL        : in std_logic;
         TILE_END       : in std_logic;
         LINE_END       : in std_logic;
         X_END          : in std_logic;
         Y_END          : in std_logic;
         LINE_EN        : out std_logic;
         COL_TILE_RST   : out std_logic;
         COL_EN         : out std_logic;
         MEM_EN         : out std_logic;
         P_OUT          : out std_logic;
         WE             : out std_logic;
         COLLIDE        : out std_logic;
         DONE           : out std_logic);
end video_ctrl;

architecture rtl of video_ctrl is
   type state_t is ( s_idle, s_col_init, s_col_read, s_col_write, s_clear );
   
   signal STATE, CURRENT_STATE : state_t;
begin
   P_OUT <= (P_IN XOR MEM_SEL) when CURRENT_STATE = s_col_write else '0';
   
   COLLIDE <= P_IN AND NOT (P_IN XOR MEM_SEL) when CURRENT_STATE = s_col_write else '0';
   
   COL_TILE_RST <= '1' when CURRENT_STATE = s_col_write AND TILE_END = '1' else '0';
   
   LINE_EN <= TILE_END when CURRENT_STATE = s_col_write else X_END when CURRENT_STATE = s_clear else '0';
   
   process(CURRENT_STATE, EN, CLS, TILE_END, LINE_END, X_END, Y_END)
   begin
      DONE <= '0';
      COL_EN <= '0';
      WE <= '0';
      MEM_EN <= '0';
      
      case CURRENT_STATE is
         when s_idle =>
            DONE <= '1';
            
            if EN = '1' then
               STATE <= s_col_init;
            elsif CLS = '1' then
               STATE <= s_clear;
            else
               STATE <= s_idle;
            end if;
            
         when s_col_init =>
            MEM_EN <= '1';
            STATE <= s_col_read;
            
            if LINE_END = '1' then
              STATE <= s_idle;
            end if;
            
         when s_col_read =>
            STATE <= s_col_write;
            
         when s_col_write =>
            WE <= '1';
            COL_EN <= '1';
            
            if TILE_END = '1' then               
              STATE <= s_col_init;
            else
              STATE <= s_col_read;
            end if;
            
         when s_clear =>
            STATE <= s_clear;
            
            COL_EN <= '1';
            WE <= '1';
            
            if X_END = '1' then               
               if Y_END = '1' then
                  STATE <= s_idle;
               end if;
            end if;
      end case;
   end process;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         CURRENT_STATE <= STATE;
      end if;
   end process;
end rtl;
