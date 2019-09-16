--
-- Color Bar Demos using a 2X Pixel Clock to Produce 27 Color Bars
-- First Bar is black so image may appear a bit smaller on monitor
--
-- Jim Hamblen, Georgia Tech School of ECE
--
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.numeric_std.all;

entity vga_controller is

   port( signal Clock_100Mhz : in std_logic;
        signal Red,Green,Blue : out std_logic;
		  signal read_address : out std_logic_vector (14 DOWNTO 0);
		  signal ram_data : in std_logic_vector(1 downto 0);
        signal Horiz_sync, Vert_sync : out std_logic);
       		
end vga_controller;

architecture behavior of vga_controller is

TYPE color IS ARRAY ( 0 TO 3 ) OF STD_LOGIC_VECTOR( 2 DOWNTO 0 );

SIGNAL color_palette			: color;

constant SCALE : integer := 4;
constant GB_WIDTH : integer := 160;
constant GB_HEIGHT : integer := 144;

-- 640x480
--constant H_SIZE : integer := 640;
--constant H_FRONT : integer := 16;
--constant H_SYNC : integer := 96;
--constant H_BACK : integer := 48;
--constant H_POL : std_logic := '0';
--constant V_SIZE : integer := 480;
--constant V_FRONT : integer := 10;
--constant V_SYNC: integer := 2;
--constant V_BACK : integer := 33;
--constant V_POL : std_logic := '0';

-- 800x600
constant H_SIZE : integer := 800;
constant H_FRONT : integer := 56;
constant H_SYNC : integer := 120;
constant H_BACK : integer := 64;
constant H_POL : std_logic := '1';
constant V_SIZE : integer := 600;
constant V_FRONT : integer := 37;
constant V_SYNC: integer := 6;
constant V_BACK : integer := 23;
constant V_POL : std_logic := '1';

-- 1280x960
--constant H_SIZE : integer := 1280;
--constant H_FRONT : integer := 80;
--constant H_SYNC : integer := 136;
--constant H_BACK : integer := 216;
--constant H_POL : std_logic := '0';
--constant V_SIZE : integer := 960;
--constant V_FRONT : integer := 1;
--constant V_SYNC: integer := 3;
--constant V_BACK : integer := 30;
--constant V_POL : std_logic := '1';

-- Video Display Signals   
signal H_count, V_count: natural range 0 to 2000;
signal Red_Data, Green_Data, Blue_Data : std_logic;


signal Horiz_Sync_int, Vert_Sync_int : std_logic;
signal vpixCount, hpixCount : natural range 0 to SCALE;
signal Color_map : std_logic_vector(2 DOWNTO 0);
signal hpix, vpix : std_logic_vector(7 DOWNTO 0);
signal Clock_50Mhz : std_logic;
signal Clock_25Mhz : std_logic;

signal div_clk : natural range 0 to 4;
signal Clock_20MHz : std_logic;
signal Clock_40MHz : std_logic;
signal Clock_20MHz_d1 : std_logic;
signal Clock_20MHz_d15 : std_logic;

signal vinrange, hinrange : boolean;
signal video_on_H, video_on_V, video_on : boolean;


begin           


-- A 2X pixel clock is used to produce more colors by turning color signals on and off
-- in a single pixel. This makes 50% color signals possible in a pixel in addition to just on and off. 
-- Three colors are possible on each RGB color signal, so 27 colors are produced instead of 
-- the eight directly supported in hardware.

-- Color Control Bits
-- Bit 0 Blue
-- Bit 1 Green
-- Bit 2 Red

-- Table of 4 Possible Colors
Color_palette(0) <= "111"; -- black
Color_palette(1) <= "011"; -- blue
Color_palette(2) <= "001"; -- cyan
Color_palette(3) <= "000"; -- white

video_on_H <= (H_count >= 0) and (H_count < H_SIZE);
video_on_V <= (V_count >= 0) and (V_count < V_SIZE);
video_on <= video_on_H and video_on_V;


-- video_on turns off pixel color data when not in the pixel view area
--video_on <= video_on_H and video_on_V;

-- This process computes a color to each pixel as the image is scanned by the monitor
-- no pixel memory is used.

CLOCK_DIVIDE: Process
Begin
Wait until(Clock_100Mhz'Event) and (Clock_100Mhz='1');
	Clock_50Mhz <= NOT Clock_50Mhz;
end process CLOCK_DIVIDE;

CLOCK_DIVIDE2: Process
Begin
Wait until(Clock_50Mhz'Event) and (Clock_50Mhz='1');
	Clock_25Mhz <= NOT Clock_25Mhz;
end process CLOCK_DIVIDE2;

CLOCK_DIVIDE3: Process
Begin
Wait until(Clock_100Mhz'Event) and (Clock_100Mhz='1');
	if div_clk = 4 then
	  div_clk <= 0;
	  Clock_20MHz <= '1';
	else
	  div_clk <= div_clk + 1;
	  Clock_20MHz <= '0';
	end if;
	Clock_20MHz_d1 <= Clock_20MHz;
end process CLOCK_DIVIDE3;

CLOCK_DIVIDE4: Process
Begin
Wait until(Clock_100Mhz'Event) and (Clock_100Mhz='0');
	Clock_20MHz_d15 <= Clock_20MHz_d1;
end process CLOCK_DIVIDE4;

Clock_40MHz <= Clock_20MHz or Clock_20MHz_d15;

-- I could not get multipliation nor left shift to work properly...
-- read_address <= vpix*160 + hpix
-- 160 == 1<<7 + 1<<5
read_address <= (vpix&"0000000") + ("00"&vpix&"00000") + ("0000000" & hpix);

Color_COMPUTE: Process (Clock_100Mhz)
Begin
 IF (Clock_100Mhz'event) and (Clock_100Mhz='1') Then
 
IF hinrange and vinrange THEN
	Color_map <= Color_palette(conv_integer(ram_data));
ELSE
-- Fill up the background
	Color_map <= Color_palette((conv_integer(H_Count)/2 + (conv_integer(V_count)/2)) mod 4);
END IF;

-- Set each RGB color signal to 100%(on), 50%(1-0 with 2X clock), or 0%(off)
-- A 0-1 pixel color is reversed to 1-0 on alternate rows and
-- alternate scans to reduce flicker.

	Red_Data <= Color_map(2);
	Green_Data <= Color_map(1);
	Blue_Data <= Color_map(0);

-- turn off color (black) at screen edges and during retrace with video_on
-- feed final outputs through registers to adjust for any timing delays
if video_on then
 Red   <= Red_Data;
 Green <= Green_Data;
 Blue  <= Blue_Data;
else
 Red   <= '0';
 Green <= '0';
 Blue  <= '0';
end if;
 
 Horiz_Sync <= Horiz_Sync_int;
 Vert_Sync <= Vert_Sync_int;

END IF;
end process Color_COMPUTE;


--Generate Horizontal and Vertical Timing Signals for Video Signal
--For details see Rapid Prototyping of Digital Systems Chapter 9
VIDEO_DISPLAY: Process(Clock_50Mhz)
Begin
 IF (Clock_50Mhz'event) and (Clock_50Mhz='1') Then

If (H_count < (H_SIZE+H_FRONT+H_SYNC+H_BACK)) then
	H_count <= H_count + 1;
	
	IF H_Count = ((H_SIZE - (GB_WIDTH*SCALE))/2) THEN
		-- start of logical screen reached
		hpixcount <= 0;
		hpix <="00000000";
		hinrange <= true;
	ELSIF hpixcount = (SCALE-1) THEN
		-- divide by three counter reached tick
		hpixcount <= 0;
		IF hpix < (GB_WIDTH-1) THEN
			hpix <= hpix + 1;
		ELSE
			hinrange <= false;
		END IF;
	ELSE
		hpixcount <= hpixcount + 1;
	END IF;
	
Else
   H_count <= 0;
End if;

If (V_count >= V_SIZE+V_FRONT+V_SYNC+V_BACK) then
   V_count <= 0;
ELSIF (H_count = 0) Then
	V_count <= V_count + 1;
	
	IF V_Count = ((V_SIZE - (GB_HEIGHT*SCALE))/2) THEN
		-- start of logical screen reached
		vpixcount <= 0;
		vpix <="00000000";
		vinrange <= true;
	ELSIF vpixcount = (SCALE-1) THEN
		-- divide by three counter reached tick
		vpixcount <= 0;
		IF vpix < (GB_HEIGHT-1) THEN
			vpix <= vpix + 1;
		ELSE
			vinrange <= false;
		END IF;
	ELSE
		vpixcount <= vpixcount + 1;
	END IF;
End if;

--Generate Horizontal Sync Signal
If (H_count >= (H_SIZE+H_BACK)) and (H_count < (H_SIZE+H_BACK+H_SYNC)) Then
   Horiz_Sync_int <= H_POL;
ELSE
   Horiz_Sync_int <= not H_POL;
End if;

-- Generate Vertical Sync Signal
If (V_count >= (V_SIZE+V_BACK)) and (V_count < (V_SIZE+V_BACK+V_SYNC)) Then
   Vert_Sync_int <= V_POL;
ELSE
   Vert_Sync_int <= not V_POL;
End if;


end if; -- clock event
end process VIDEO_DISPLAY;


end behavior;

