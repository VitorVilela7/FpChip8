library IEEE;
use IEEE.std_logic_1164.all;

entity control_circuit is
   port( CLK                     : in std_logic;
         PROG_N                  : in std_logic;
         IR_VAL                  : in std_logic_vector(7 downto 0);
         MEM_VAL                 : in std_logic_vector(7 downto 0);
         ALU_ZERO                : in std_logic;
         COUNTER_END             : in std_logic;
         KEY_OUT                 : in std_logic;
         KEY_NEW                 : in std_logic;
         BCD_DONE                : in std_logic;
         BCD_STOP                : in std_logic;
         VIDEO_READY             : in std_logic;
         OP_HOLD                 : in std_logic;
         OP_TICK                 : out std_logic;
         STACK_EN                : out std_logic;
         STACK_PUSH              : out std_logic;
         IR_EN                   : out std_logic;
         I_SEL                   : out natural range 0 to 2;
         I_EN                    : out std_logic;
         PC_EN                   : out std_logic;
         PC_SEL                  : out natural range 0 to 3;
         VX_EN                   : out std_logic;
         VX_SEL                  : out natural range 0 to 3;
         VX_LOAD_SEL             : out natural range 0 to 7;
         BCD_EN                  : out std_logic;
         DT_EN                   : out std_logic;
         ST_EN                   : out std_logic;
         MEM_WE                  : out std_logic;
         MEM_ADDR_SEL            : out std_logic;
         COUNTER_RST             : out std_logic;
         ALU_B_SEL               : out std_logic;
         ALU_SEL                 : out natural range 0 to 7;
         PROG_FLAG               : out std_logic;
         ALU_FLG_EN              : out std_logic;
         RNG_EN                  : out std_logic;
         BCD_STORE_EN            : out std_logic;
         VIDEO_CLS               : out std_logic;
         VIDEO_SPR_EN            : out std_logic);
end control_circuit;

architecture rtl of control_circuit is
   type state_t is (
      op_fetch_1, op_fetch_2, op_exec, update_vf, op_skip,
      load_reg, save_reg, prog_mode, pull_stack, pull_stack_2, wait_key,
      bcd_wait, bcd_store, video_clear, video_wait, op_wait
   );

   signal STATE, CURR_STATE : state_t := prog_mode;
   
   -- which ALU opcode should be used for testing for zero?
   -- SUB, SUBN and XOR can be used. Pick one that optimizes best.
   constant ALU_OP_ZERO : natural range 0 to 7 := 7;
begin
   -- Control Circuit (reg)
   process(CLK)
   begin
      if rising_edge(CLK) then
         CURR_STATE <= STATE;
      end if;
   end process;
   
   -- Control Circuit (comb)
   -- Mealy State Machine.
   process(CURR_STATE, IR_VAL, MEM_VAL, ALU_ZERO, COUNTER_END, PROG_N, KEY_NEW, KEY_OUT, BCD_DONE, BCD_STOP, VIDEO_READY, OP_HOLD)
   begin
      -- Don't cares '-' or 'X' are used to optimize logic a bit more, but they should not be
      -- used on the enable registers (_EN, _RST ones) or registers may screw up.
      
      -- IR (optimized)
      IR_EN <= '0';
      
      -- I
      I_SEL <= 0;
      I_EN <= '0';
      
      -- PC
      PC_EN <= '0';
      PC_SEL <= 0;
      
      -- VX
      VX_EN <= '0';
      VX_SEL <= 0;
      VX_LOAD_SEL <= 0;
      
      -- MEM
      MEM_WE <= '0';
      MEM_ADDR_SEL <= '0';
      
      -- COUNTER (1 to RESET, 0 to TICK)
      COUNTER_RST <= '1';
      
      -- ALU
      ALU_B_SEL <= '-';
      ALU_SEL <= 0;
      ALU_FLG_EN <= '0';
      
      -- RNG
      RNG_EN <= '0';
      
      -- PROG mode status
      PROG_FLAG <= '0';
      
      -- Stack
      STACK_EN <= '0';
      STACK_PUSH <= '0';
      
      -- DT, ST store flags
      DT_EN <= '0';
      ST_EN <= '0';
      
      -- BCD
      BCD_EN <= '0';
      BCD_STORE_EN <= '0';
      
      -- Video
      VIDEO_CLS <= '0';
      VIDEO_SPR_EN <= '0';
      
      -- Speed controlling
      OP_TICK <= '0';
   
      case CURR_STATE is
         when op_fetch_1 =>
            -- This step, PC should NOW have the first requested address.
            STATE <= op_fetch_2;
            
            PC_EN <= '1';
                        
         when op_fetch_2 =>
            -- This step, PC should NOW have the second requested address.
            -- This step, MEM VAL should NOW have the first requested address.
            STATE <= op_exec;
            
            IR_EN <= '1'; -- save high byte
            PC_EN <= '1';
            
            -- This state is in particular special since it checks for IRQs,
            -- or more specifically, the PROG flag to enter programming mode.
            if PROG_N = '0' then
               STATE <= prog_mode;
            elsif OP_HOLD = '1' then
               PC_EN <= '0';
               STATE <= op_wait;
            end if;
            
         when op_exec =>
            -- This step, PC should NOW have the next requested opcode.
            -- If not, state MUST go to op_fetch_1 as the pipeline process has break.
            STATE <= op_fetch_2;
            
            -- Don't reset counter
            COUNTER_RST <= '0';
            
            PC_EN <= '1';
            
            -- One opcode executed.
            OP_TICK <= '1';
            
            case IR_VAL(7 downto 4) is
               when x"0" => -- many opcodes (can be 0NNN, 00E0, 00EE)
                  -- 0NNN opcode is ignored, though.
               
                  if IR_VAL = x"00" then
                     if MEM_VAL = x"E0" then -- 00E0 - CLS (done)
                        report "CLS";
                                          
                        PC_EN <= '0';                 -- Don't increase PC...
                        VIDEO_CLS <= '1';             -- Clear video...
                        STATE <= video_clear;         -- Wait video processing.
                     end if;
                     
                     if MEM_VAL = x"EE" then -- 00EE - RET (done)
                        report "RET";
                        
                        STACK_EN <= '1';
                        STACK_PUSH <= '0';
                        STATE <= pull_stack;
                     end if;
                  end if;
               
               when x"1" => -- JP addr (done)
                  report "JP addr";
                  
                  PC_EN <= '1';           -- Change program counter.
                  PC_SEL <= 1;            -- Load from NNN.
                  STATE <= op_fetch_1;    -- Wait until pipeline is fetched again.
                  
               when x"2" => -- CALL addr (done)
                  report "CALL addr";
                  
                  PC_EN <= '1';           -- Change program counter.
                  PC_SEL <= 1;            -- Load from NNN.
                  STATE <= op_fetch_1;    -- Wait until pipeline is fetched again.
                  
                  STACK_EN <= '1';        -- Activate Stack
                  STACK_PUSH <= '1';      -- Push current PC.
               
               when x"3" => -- SE Vx, byte (done)
                  report "SE Vx, byte";
                  
                  VX_SEL <= 0;            -- Vx from opcode.
                  
                  ALU_B_SEL <= '1';       -- Load kk
                  ALU_SEL <= ALU_OP_ZERO;           -- Sub opcode
                  
                  if ALU_ZERO = '1' then  -- If values are equal,
                     STATE <= op_skip;    -- skip next opcode.
                  end if;
               
               when x"4" => -- SNE Vx, byte (done)
                  report "SNE Vx, byte";
                  
                  VX_SEL <= 0;            -- Vx from opcode.
                  
                  ALU_B_SEL <= '1';       -- Load kk
                  ALU_SEL <= ALU_OP_ZERO;           -- Sub opcode
                  
                  if ALU_ZERO = '0' then  -- If values are not equal,
                     STATE <= op_skip;    -- skip next opcode.
                  end if;
               
               when x"5" => -- SE Vx, Vy (done)
                  report "SE Vx, Vy";
                  
                  VX_SEL <= 0;            -- Vx from opcode.
                  
                  ALU_B_SEL <= '0';       -- Load Vy
                  ALU_SEL <= ALU_OP_ZERO;           -- Sub opcode
                  
                  if ALU_ZERO = '1' then  -- If values are equal,
                     STATE <= op_skip;    -- skip next opcode.
                  end if;
               
               when x"6" => -- LD Vx, byte (done)
                  report "LD Vx, byte";
                  
                  VX_LOAD_SEL <= 0; -- Load from byte.
                  VX_SEL <= 0;      -- Vx from opcode.
                  VX_EN <= '1';     -- Write to register.
               
               when x"7" => -- ADD Vx, byte (done)
                  -- NOTE: carry is not affected.
                  report "ADD Vx, byte";
                  
                  ALU_B_SEL <= '1';    -- Load kk
                  ALU_SEL <= 4;        -- Add opcode
               
                  VX_LOAD_SEL <= 1;    -- Load from ALU.
                  VX_SEL <= 0;         -- Vx from opcode.
                  VX_EN <= '1';        -- Write to register.
               
               when x"8" => -- Aritmetic/load opcodes. All of them store to Vx.
                  VX_LOAD_SEL <= 1;          -- Load from ALU.
                  VX_SEL <= 0;               -- Vx from opcode.
                  VX_EN <= '1';              -- Write to register.
                  
                  ALU_B_SEL <= '0';          -- For ALU opcodes, use Vy.
                        
                  case MEM_VAL(3 downto 0) is
                     when x"0" => -- 8xy0 - LD Vx, Vy (done)
                        report "LD Vx, Vy";
                        VX_LOAD_SEL <= 5;    -- Load from Vy.
                        
                     when x"1" => -- 8xy1 - OR Vx, Vy (done)
                        report "OR Vx, Vy";
                        ALU_SEL <= 1;        -- OR opcode
                     
                     when x"2" => -- 8xy2 - AND Vx, Vy (done)
                        report "AND Vx, Vy";
                        ALU_SEL <= 2;        -- AND opcode
                     
                     when x"3" => -- 8xy3 - XOR Vx, Vy (done)
                        report "XOR Vx, Vy";
                        ALU_SEL <= 3;        -- XOR opcode
                     
                     when x"4" => -- 8xy4 - ADD Vx, Vy (done)
                        report "ADD Vx, Vy";
                        ALU_SEL <= 4;        -- ADD opcode
                        
                        ALU_FLG_EN <= '1';   -- Store FLG register.
                        STATE <= update_vf;  -- Next state, update VF register.
                        PC_EN <= '0';
                     
                     when x"5" => -- 8xy5 - SUB Vx, Vy (done)
                        report "SUB Vx, Vy";
                        ALU_SEL <= 5;        -- SUB opcode
                        
                        ALU_FLG_EN <= '1';   -- Store FLG register.
                        STATE <= update_vf;  -- Next state, update VF register.
                        PC_EN <= '0';
                     
                     when x"6" => -- 8xy6 - SHR Vx {, Vy} (done)
                        report "SHR Vx";
                        ALU_SEL <= 6;        -- SHR opcode
                        
                        ALU_FLG_EN <= '1';   -- Store FLG register.
                        STATE <= update_vf;  -- Next state, update VF register.
                        PC_EN <= '0';
                     
                     when x"7" => -- 8xy7 - SUBN Vx, Vy (done)
                        report "SUBN Vx, Vy";
                        ALU_SEL <= 7;        -- SUBN opcode
                        
                        ALU_FLG_EN <= '1';   -- Store FLG register.
                        STATE <= update_vf;  -- Next state, update VF register.
                        PC_EN <= '0';
                     
                     when x"E" => -- 8xyE - SHL Vx {, Vy} (done)
                        report "SHL Vx";
                        ALU_SEL <= 0;        -- SHL opcode
                        
                        ALU_FLG_EN <= '1';   -- Store FLG register.
                        STATE <= update_vf;  -- Next state, update VF register.
                        PC_EN <= '0';
                     
                     when others => -- Undefined
                  end case;
               
               when x"9" => -- 9xy0 - SNE Vx, Vy (done)
                  -- The "0" is ignored since there's no other 9NNN series opcode.
                  report "SNE Vx, Vy";
                  
                  VX_SEL <= 0;               -- Vx from opcode.
                  
                  ALU_B_SEL <= '0';          -- Load Vy
                  ALU_SEL <= ALU_OP_ZERO;    -- Sub opcode
                  
                  if ALU_ZERO = '0' then  -- If values are not equal,
                     STATE <= op_skip;    -- skip next opcode.
                  end if;
               
               when x"A" => -- Annn - LD I, addr (done)
                  report "LD I, NNN";
                  
                  I_SEL <= 0;             -- Load from NNN.
                  I_EN <= '1';            -- Write to I.
               
               when x"B" => -- Bnnn - JP V0, addr (done)
                  report "JP NNN+Vx";
                  
                  PC_EN <= '1';           -- Change program counter.
                  PC_SEL <= 2;            -- Load from NNN + VX.
                  VX_SEL <= 1;            -- Load VX = V0
                  
                  STATE <= op_fetch_1;    -- Wait until pipeline is fetched again.
               
               when x"C" => -- Cxkk - RND Vx, byte (done)
                  report "RND";
                  
                  ALU_B_SEL <= '1';      -- Load kk
                  ALU_SEL <= 2;        -- AND opcode
               
                  VX_LOAD_SEL <= 1;    -- Load from ALU.
                  VX_SEL <= 0;         -- Vx from opcode.
                  VX_EN <= '1';        -- Write to register.
                  
                  RNG_EN <= '1';       -- Output next random number...
               
               when x"D" => -- Dxyn - DRW Vx, Vy, nibble
                  report "DRW";
                  
                  MEM_ADDR_SEL <= '1';
                  VX_SEL <= 0;                  -- Vx from opcode.
                  PC_EN <= '0';                 -- Don't increase PC...
                  VIDEO_SPR_EN <= '1';          -- Enable video
                  STATE <= video_wait;          -- Wait video processing.
                                       
               when x"E" => -- SKP opcodes.
                  VX_SEL <= 0;                  -- Vx from opcode.
                  
                  case MEM_VAL is
                     when x"9E" => -- Ex9E - SKP Vx (done)
                        report "SKP Vx";
                        
                        if KEY_OUT = '1' then   -- If key is pressed,
                           STATE <= op_skip;    -- skip next opcode.
                        end if;
                  
                     when x"A1" => -- ExA1 - SKNP Vx (done)
                        report "SKNP Vx";
                        
                        if KEY_OUT = '0' then   -- If key is not pressed,
                           STATE <= op_skip;    -- skip next opcode.
                        end if;
               
                     when others =>
                  end case;
                  
               when x"F" => -- many opcodes                 
                  case MEM_VAL is
                     when x"1E" => -- Fx1E - ADD I, Vx (done)
                        report "ADD I, Vx";
                        
                        VX_SEL <= 0;         -- Vx from opcode.
                        I_SEL <= 1;          -- Set I to I + VX
                        I_EN <= '1';         -- Write to I.
                        
                     when x"07" => -- Fx07 - LD Vx, DT (done)
                        report "LD Vx, DT";
                        
                        VX_LOAD_SEL <= 2;    -- Load from DT.
                        VX_SEL <= 0;         -- Vx from opcode.
                        VX_EN <= '1';        -- Write to register.
                  
                     when x"0A" => -- Fx0A - LD Vx, K (done)
                        report "LD Vx, K";
                        
                        PC_EN <= '0';
                        STATE <= wait_key;   -- Lock processor until a key is pressed.
                        
                     when x"15" => -- Fx15 - LD DT, Vx (done)
                        report "LD DT, Vx";
                        
                        VX_SEL <= 0;         -- Vx from opcode.
                        DT_EN <= '1';        -- Write delay timer value.
                        
                     when x"18" => -- Fx18 - LD ST, Vx (done)
                        report "LD ST, Vx";
                        
                        VX_SEL <= 0;         -- Vx from opcode.
                        ST_EN <= '1';        -- Write sound delay timer value.
                     
                     when x"29" => -- Fx29 - LD F, Vx (done)
                        report "LD I, 5*Vx";
                        
                        VX_SEL <= 0;         -- Vx from opcode.
                        I_SEL <= 2;          -- Set I to 5*VX
                        I_EN <= '1';         -- Write to I
                        
                     when x"33" => -- Fx33 - LD B, Vx (done)
                        report "BCD [I], Vx";
                        
                        VX_SEL <= 0;         -- Vx from opcode.
                        BCD_EN <= '1';       -- Store VX value to BCD generator and start circuit.
                        PC_EN <= '0';
                        STATE <= bcd_wait;   -- Wait until BCD circuit is done...
                     
                     when x"55" => -- Fx55 - LD [I], Vx (done)
                        report "LD [I], Vx";
                        
                        PC_EN <= '0';
                        STATE <= save_reg;   -- Go to save registers state.
                        
                        MEM_ADDR_SEL <= '1'; -- Select memory address from I + counter reg.
                     
                     when x"65" => -- Fx65 - LD Vx, [I] (done)
                        report "LD Vx, [I]";
                        
                        PC_EN <= '0';
                        STATE <= load_reg;   -- Go to load registers state.
                        
                        MEM_ADDR_SEL <= '1'; -- Select memory address from I + counter reg.
                        
                     when others =>
                  end case;
                              
               when others =>
            end case;
            
         when op_wait =>
            if OP_HOLD = '1' then
               STATE <= op_wait;
            else
               PC_EN <= '1';
               STATE <= op_exec;
            end if;
            
         when video_clear =>            
            if VIDEO_READY = '1' then
               STATE <= op_fetch_1;
            else
               STATE <= CURR_STATE;
            end if;
            
         when video_wait =>
            MEM_ADDR_SEL <= '1';
            COUNTER_RST <= '0';
            VX_LOAD_SEL <= 6;                -- Load from VIDEO_COLLIDE
            VX_SEL <= 2;                     -- Force VF register.
            VX_EN <= '1';                    -- Write to register.
            
            if VIDEO_READY = '1' then
               STATE <= op_fetch_1;
            else
               STATE <= CURR_STATE;
            end if;
            
         when bcd_wait =>
            MEM_ADDR_SEL <= '1';
            
            if BCD_DONE = '1' then
               STATE <= bcd_store;
            else
               STATE <= bcd_wait;
            end if;
            
         when bcd_store =>
            COUNTER_RST <= '0';
            BCD_STORE_EN <= '1';
            MEM_WE <= '1';
            MEM_ADDR_SEL <= '1';
            
            if BCD_STOP = '1' then
               STATE <= op_fetch_1;
            else
               STATE <= bcd_store;               
            end if;
            
         when update_vf =>
            VX_LOAD_SEL <= 4;                -- Load from ALU_FLG
            VX_SEL <= 2;                     -- Force VF register.
            VX_EN <= '1';                    -- Write to register.
            
            STATE <= op_fetch_1;
            
         when op_skip =>
            -- This state, PC should NOW have the second requested (and ignored) opcode.
            PC_EN <= '1';
            PC_SEL <= 0;
         
            STATE <= op_fetch_1;
            
         when load_reg =>
            MEM_ADDR_SEL <= '1';             -- Select memory address from I + counter reg.
            
            COUNTER_RST <= '0';              -- Tick counter
            
            VX_LOAD_SEL <= 0;                -- Load VX from memory.
            VX_SEL <= 3;                     -- Load X from counter (delayed).
            VX_EN <= '1';                    -- Store VX...
            
            if COUNTER_END = '1' then
               STATE <= op_fetch_1;          -- Fetch first byte.
            else
               STATE <= load_reg;            -- Otherwise keep feeding VX...
            end if;
            
         when save_reg =>
            MEM_ADDR_SEL <= '1';             -- Select memory address from I + counter reg.
            MEM_WE <= '1';                   -- Write enable.
            
            COUNTER_RST <= '0';              -- Tick counter
            
            VX_SEL <= 3;                     -- Load X from counter.
            
            if COUNTER_END = '1' then
               STATE <= op_fetch_1;          -- Fetch first byte.
            else
               STATE <= save_reg;            -- Otherwise keep feeding [I]...
            end if;
            
         when pull_stack =>                  -- Idle cycle...
            STATE <= pull_stack_2;
            
         when pull_stack_2 =>
            PC_EN <= '1';                    -- Store stack value to
            PC_SEL <= 3;                     -- program counter.
            
            STATE <= op_fetch_1;             -- PC just changed, wait till...
            
         when wait_key =>
            VX_LOAD_SEL <= 3;                -- Load from K.
            VX_SEL <= 0;                     -- Vx from opcode.
            VX_EN <= '1';                    -- Write to register.
            
            if KEY_NEW = '1' then
               STATE <= op_fetch_1;
            else
               STATE <= wait_key;
            end if;
            
            if PROG_N = '0' then             -- Since program is locked, check for IRQs...
               STATE <= prog_mode;
            end if;
         
         when prog_mode =>
            PROG_FLAG <= '1';
            
            PC_EN <= '1';                    -- Set PC to RESET vector...
            I_EN <= '1';
            
            -- V0-VF is cleared.
            -- I is cleared.
            -- IR is not cleared (not needed).
            -- Counter is always cleared at opcode fetching/decoding.
            
            -- Force video clear.
            VIDEO_CLS <= '1';
            
            if PROG_N = '0' then
               STATE <= prog_mode;
            else
               STATE <= video_clear;
            end if;
      end case;
   end process;
end rtl;