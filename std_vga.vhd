--
-- Standard VGA Output Driver
-- Default: 640x480 @ 60 Hz
--
-- 640x480 @ 60 Hz generic map: (8,  96,40,8,640,8,2, 2,25,8,480,8) at 25 MHz
-- 800x600 @ 72 Hz generic map: (53,120,61,3,800,3,35,6,21,2,600,2) at 50 MHz
--

library IEEE;
use IEEE.std_logic_1164.all;

entity std_vga is
	generic(	HF_PORCH		: natural := 8;
				HH_SYNC		: natural := 96;
				HB_PORCH		: natural := 40;
				L_BORDER		: natural := 8;
				WIDTH			: natural := 640;
				R_BORDER		: natural := 8;
			
				VF_PORCH		: natural := 2;
				VV_SYNC		: natural := 2;
				VB_PORCH		: natural := 25;
				T_BORDER		: natural := 8;
				HEIGHT		: natural := 480;
				B_BORDER		: natural := 8);

	port(	CLOCK			: in std_logic;
			R				: in std_logic_vector(3 downto 0);
			G				: in std_logic_vector(3 downto 0);
			B				: in std_logic_vector(3 downto 0);
			X				: out natural range 0 to HF_PORCH+HH_SYNC+HB_PORCH+L_BORDER+WIDTH+R_BORDER-1;
			Y				: out natural range 0 to VF_PORCH+VV_SYNC+VB_PORCH+T_BORDER+HEIGHT+B_BORDER-1;
         X_EN        : out std_logic;
         Y_EN        : out std_logic;
         X_ZERO      : out std_logic;
         Y_ZERO      : out std_logic;
			VGA_HS		: out std_logic;
			VGA_VS		: out std_logic;
			VGA_R			: out std_logic_vector(3 downto 0);
			VGA_G			: out std_logic_vector(3 downto 0);
			VGA_B			: out std_logic_vector(3 downto 0));
end std_vga;

architecture logic of std_vga is
	constant H_LINES	: natural := HF_PORCH+HH_SYNC+HB_PORCH+L_BORDER+WIDTH+R_BORDER-1;
	constant V_LINES	: natural := VF_PORCH+VV_SYNC+VB_PORCH+T_BORDER+HEIGHT+B_BORDER-1;

	signal H_SYNC		: std_logic;
	signal V_SYNC		: std_logic;
	
	signal C_LOW		: std_logic;
	signal H_LOW		: std_logic;
	signal V_LOW		: std_logic;
   
	signal H_COUNT		: natural range 0 to H_LINES;
	signal V_COUNT		: natural range 0 to V_LINES;
   
   signal TOGGLE     : std_logic := '0';
   
   signal X_RST      : std_logic;
   signal X_RISE     : std_logic;
   
   signal Y_RST      : std_logic;
   signal Y_RISE     : std_logic;
   
   signal H_SYNC_L   : std_logic;
   signal V_SYNC_L   : std_logic;
begin
	with C_LOW select VGA_R <= x"0" when '1', R when others;
	with C_LOW select VGA_G <= x"0" when '1', G when others;
	with C_LOW select VGA_B <= x"0" when '1', B when others;
	
	VGA_HS <= H_SYNC;
	VGA_VS <= V_SYNC;
	
	X <= H_COUNT;
	Y <= V_COUNT;
   
   X_ZERO <= X_RST;-- OR C_LOW;
   Y_ZERO <= Y_RST;-- OR C_LOW;
   
   X_EN <= X_RISE AND NOT C_LOW;
   Y_EN <= Y_RISE AND NOT V_LOW;
	
	C_LOW <= H_LOW or V_LOW;
	
	V_LOW <= '0' when V_COUNT < HEIGHT else '1';
	H_LOW <= '0' when H_COUNT < WIDTH else '1';
	
	V_SYNC_L <= '0' when V_COUNT < HEIGHT+B_BORDER+VF_PORCH+VV_SYNC and V_COUNT >= HEIGHT+B_BORDER+VF_PORCH else '1';
   H_SYNC_L <= '0' when H_COUNT < WIDTH+HF_PORCH+R_BORDER+HH_SYNC and H_COUNT >= WIDTH+HF_PORCH+R_BORDER else '1';
   
   X_RST <= '1' when H_COUNT = H_LINES else '0';
   X_RISE <= TOGGLE;
   
   Y_RST <= '1' when V_COUNT = V_LINES else '0';
   Y_RISE <= '1' when H_SYNC = '0' and H_SYNC_L = '1' else '0';
   
	process(CLOCK)
	begin
		if rising_edge(CLOCK) then
         TOGGLE <= NOT TOGGLE;
         
         if X_RISE = '1' then
            H_COUNT <= H_COUNT + 1;
            
            if X_RST = '1' then
               H_COUNT <= 0;
            end if;
         end if;
         
         if Y_RISE = '1' then
            V_COUNT <= V_COUNT + 1;
            
            if Y_RST = '1' then
               V_COUNT <= 0;
            end if;
         end if;
		end if;
	end process;
	
	process(CLOCK)
	begin
		if rising_edge(CLOCK) then
         H_SYNC <= H_SYNC_L;
         V_SYNC <= V_SYNC_L;
		end if;
	end process;
end logic;