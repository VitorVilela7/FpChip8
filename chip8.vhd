------------------------------------------------------------
-- CHIP-8 Main Module.
-- By Vitor Vilela (2018-10-31)
--
-- Main CHIP-8 module responsible for connecting all
-- required components to run CHIP-8.
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity chip8 is
   port( CLK         : in std_logic;
         KEY         : in std_logic_vector(15 downto 0);
         PROG_N      : in std_logic;
         PROG_ADDR   : in std_logic_vector(11 downto 0);
         PROG_DATA   : in std_logic_vector(7 downto 0);
         VIDEO_X     : in std_logic_vector(5 downto 0);
         VIDEO_Y     : in std_logic_vector(4 downto 0);
         VIDEO_OUT   : out std_logic;
         BEEP_OUT    : out std_logic;
         PROG_FLAG   : out std_logic);
end chip8;

architecture rtl of chip8 is
   -- How many opcodes can be executed per frame.
   constant OPCODES_PER_FRAME : std_logic_vector(7 downto 0) := X"0C";

   --- Vregs signals
   signal VX_LOAD, VX_VAL, VY_VAL : std_logic_vector(7 downto 0);
   signal VX_ADDR, VY_ADDR : natural range 0 to 15;
   signal VX_SEL : natural range 0 to 3;
   signal VX_LOAD_SEL : natural range 0 to 7;
   signal VX_EN : std_logic;
   
   -- IR (holds first instruction register) signals
   signal IR_VAL : std_logic_vector(7 downto 0);
   signal IR_EN : std_logic;
   
   -- I signals
   signal I_LOAD, I_VAL : std_logic_vector(11 downto 0);
   signal I_SEL : natural range 0 to 2;
   signal I_EN : std_logic;
   
   -- Counter signals
   signal COUNTER, COUNTER_DELAY : std_logic_vector(3 downto 0);
   signal COUNTER_RST, COUNTER_END : std_logic;
   
   -- PROG MODE signals
   signal PROG_FLAG_Q : std_logic;
   
   -- PC signals
   signal PC_VAL, PC_LOAD, NNN : std_logic_vector(11 downto 0);
   signal PC_SEL : natural range 0 to 3;   
   signal PC_EN : std_logic;
   
   -- MEM signals
   signal MEM_ADDR : unsigned(11 downto 0);
   signal MEM_ADDR_SEL, MEM_WE, WRITE_EN : std_logic;
   signal MEM_LOAD, MEM_VAL : std_logic_vector(7 downto 0);
   
   -- ALU signals
   signal ALU_A, ALU_B, ALU_VAL : std_logic_vector(7 downto 0);
   signal ALU_SEL : natural range 0 to 7;
   signal ALU_B_SEL, ALU_FLG_LOAD, ALU_FLG_EN, ALU_ZERO : std_logic;
   
   -- Stack signals
   signal STACK_EN, STACK_PUSH : std_logic;
   signal STACK_PULL : std_logic_vector(11 downto 0);
   
   -- Key related
   signal KEY_SEL, KEY_NUM : std_logic_vector(3 downto 0);
   signal KEY_NEW, KEY_OUT : std_logic; -- sets to 1 when a new key press is detected.
   
   -- PRNG
   signal RNG_OUT : std_logic_vector(7 downto 0);
   signal RNG_EN : std_logic;
   
   -- BCD circuit
   signal BCD_EN, BCD_DONE, BCD_STORE, BCD_STOP : std_logic;
   signal BCD_IN : std_logic_vector(7 downto 0);
   signal BCD_OUT : std_logic_vector(9 downto 0);
   
   -- Timers
   signal ST_ZERO, OP_HOLD, OP_TICK, TICK, DT_EN, ST_EN : std_logic;
   signal DT_VAL : std_logic_vector(7 downto 0);
   
   -- Video
   signal VIDEO_CLS, VIDEO_SPR_EN, VIDEO_SPR_COLLIDE, VIDEO_DATA_READY : std_logic;
   signal VIDEO_SPR_X : std_logic_vector(5 downto 0);
   signal VIDEO_SPR_Y : std_logic_vector(4 downto 0);
   signal VIDEO_SPR_SIZE : std_logic_vector(3 downto 0);
begin
   -- Others   
   PROG_FLAG <= PROG_FLAG_Q;
   NNN <= IR_VAL(3 downto 0) & MEM_VAL;
   
   -- BCD
   BCD_IN <= VX_VAL;
   BCD_STOP <= '1' when COUNTER_DELAY = X"2" else '0';
   bcd : entity work.bcd_gen port map(CLK, BCD_EN, BCD_IN, BCD_DONE, BCD_OUT);   
   
   -- PRNG
   rng : entity work.prng port map(CLK, RNG_EN, RNG_OUT);
   
   -- Pad System
   KEY_SEL <= VX_VAL(3 downto 0);
   pad : entity work.key_sel port map(CLK, KEY, KEY_SEL, KEY_OUT, KEY_NEW, KEY_NUM);
   
   -- Timers
   BEEP_OUT <= NOT ST_ZERO;
   
   base_timer : entity work.c8_60hz port map(CLK, TICK);
   delay_timer : entity work.reg_timer port map(CLK, PROG_FLAG_Q, DT_EN, TICK, VX_VAL, DT_VAL, open);
   sound_timer : entity work.reg_timer port map(CLK, PROG_FLAG_Q, ST_EN, TICK, VX_VAL, open, ST_ZERO);
   speed_timer : entity work.reg_timer port map(CLK, '0', TICK, OP_TICK, OPCODES_PER_FRAME, open, OP_HOLD);   

   -- Counter
   cnt_core : entity work.counter generic map(4) port map(CLK, '1', COUNTER_RST, COUNTER);
   cnt_delay : entity work.regn generic map(4) port map(CLK, '0', '1', COUNTER, COUNTER_DELAY);
   COUNTER_END <= '1' when COUNTER_DELAY = IR_VAL(3 downto 0) else '0';
   
   -- ALU
   ALU_A <= VX_VAL when RNG_EN = '0' else RNG_OUT; -- ALU input is RNG when RNG module is activated.
   ALU_B <= VY_VAL when ALU_B_SEL = '0' else MEM_VAL;
   alu_core : entity work.alu port map(ALU_A, ALU_B, ALU_SEL, ALU_VAL, ALU_ZERO, ALU_FLG_LOAD);
   
   -- I Register
   i_flow_path : entity work.i_flow port map(I_SEL, VX_VAL, NNN, I_VAL, I_LOAD);
   reg_i : entity work.regn generic map(12) port map(CLK, PROG_FLAG_Q, I_EN, I_LOAD, I_VAL);
   
   -- VX/VY Register
   vreg_flow_path : entity work.vreg_flow port map(CLK, ALU_FLG_EN, ALU_FLG_LOAD, VIDEO_SPR_COLLIDE,
      VX_SEL, VX_LOAD_SEL, IR_VAL, MEM_VAL, ALU_VAL, DT_VAL, VY_VAL, COUNTER_DELAY, KEY_NUM,
      VX_LOAD, VX_ADDR, VY_ADDR);
      
   vregi : entity work.vreg port map(CLK, PROG_FLAG_Q, VX_EN, VX_ADDR, VY_ADDR, VX_LOAD, VX_VAL, VY_VAL);
   
   -- IR Register
   regir : entity work.regn generic map(8) port map(CLK, '0', IR_EN, MEM_VAL, IR_VAL);
   
   -- Stack, responsible for pushing and pulling PC...
   sp : entity work.stack port map(CLK, STACK_EN, STACK_PUSH, PC_VAL, STACK_PULL);
   
   -- PC Register                  
   pc_path_flow : entity work.pc_flow port map(PROG_FLAG_Q, PC_SEL, VX_VAL, PC_VAL, NNN, STACK_PULL, PC_LOAD);
   
   reg_pc : entity work.regn generic map(12) port map(CLK, '0', PC_EN, PC_LOAD, PC_VAL);
   
   -- CHIP-8 Memory
   mem_flow_path : entity work.mem_flow port map(PROG_N, WRITE_EN, MEM_ADDR_SEL, BCD_STORE, BCD_OUT,
      VX_VAL, PROG_DATA, PROG_ADDR, I_VAL, PC_VAL, COUNTER, COUNTER_DELAY, MEM_WE, MEM_ADDR, MEM_LOAD);
   
   work_memory : entity work.main_ram port map(CLK, MEM_WE, MEM_ADDR, MEM_LOAD, MEM_VAL);
   
   -- Video Module
   VIDEO_SPR_SIZE <= MEM_VAL(3 downto 0);
   VIDEO_SPR_X <= VX_VAL(5 downto 0);
   VIDEO_SPR_Y <= VY_VAL(4 downto 0);
   
   video : entity work.video_main port map(
         CLK => CLK,
         SCREEN_CLS => VIDEO_CLS,
         SPR_EN => VIDEO_SPR_EN,
         SPR_X => VIDEO_SPR_X,
         SPR_Y => VIDEO_SPR_Y,
         SPR_SIZE => VIDEO_SPR_SIZE,
         SPR_DATA => MEM_VAL,
         OUT_X => VIDEO_X,
         OUT_Y => VIDEO_Y,
         OUT_PIXEL => VIDEO_OUT,
         SPR_COLLIDE => VIDEO_SPR_COLLIDE,
         DATA_READY => VIDEO_DATA_READY
   );
         
   -- Control Circuit
   control : entity work.control_circuit port map(
         CLK => CLK,
         PROG_N => PROG_N,
         IR_VAL => IR_VAL,
         MEM_VAL => MEM_VAL,
         ALU_ZERO => ALU_ZERO,
         COUNTER_END => COUNTER_END,
         KEY_NEW => KEY_NEW,
         KEY_OUT => KEY_OUT,
         STACK_EN => STACK_EN,
         STACK_PUSH => STACK_PUSH,
         BCD_DONE => BCD_DONE,
         BCD_STOP => BCD_STOP,
         VIDEO_READY => VIDEO_DATA_READY,
         OP_HOLD => OP_HOLD,
         OP_TICK => OP_TICK,
         IR_EN => IR_EN,
         I_SEL => I_SEL,
         I_EN => I_EN,
         PC_EN => PC_EN,
         PC_SEL => PC_SEL,
         VX_EN => VX_EN,
         VX_SEL => VX_SEL,
         VX_LOAD_SEL => VX_LOAD_SEL,
         BCD_EN => BCD_EN,
         DT_EN => DT_EN,
         ST_EN => ST_EN,
         MEM_WE => WRITE_EN,
         MEM_ADDR_SEL => MEM_ADDR_SEL,
         COUNTER_RST => COUNTER_RST,
         ALU_B_SEL => ALU_B_SEL,
         ALU_SEL => ALU_SEL,
         PROG_FLAG => PROG_FLAG_Q,
         ALU_FLG_EN => ALU_FLG_EN,
         RNG_EN => RNG_EN,
         BCD_STORE_EN => BCD_STORE,
         VIDEO_CLS => VIDEO_CLS,
         VIDEO_SPR_EN => VIDEO_SPR_EN
   );
end rtl;
