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

constant SCALE : integer := 3;
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
--constant H_SIZE : integer := 800;
--constant H_FRONT : integer := 56;
--constant H_SYNC : integer := 120;
--constant H_BACK : integer := 64;
--constant H_POL : std_logic := '1';
--constant V_SIZE : integer := 600;
--constant V_FRONT : integer := 37;
--constant V_SYNC: integer := 6;
--constant V_BACK : integer := 23;
--constant V_POL : std_logic := '1';

-- 1280x960
constant H_SIZE : integer := 1280;
constant H_FRONT : integer := 80;
constant H_SYNC : integer := 136;
constant H_BACK : integer := 216;
constant H_POL : std_logic := '0';
constant V_SIZE : integer := 960;
constant V_FRONT : integer := 1;
constant V_SYNC: integer := 3;
constant V_BACK : integer := 30;
constant V_POL : std_logic := '1';

-- Video Display Signals   
signal H_count, V_count: natural range 0 to 2000;
signal Red_Data, Green_Data, Blue_Data : std_logic;


signal Horiz_Sync_int, Vert_Sync_int : boolean;
signal vpixCount, hpixCount : natural range 0 to SCALE;
signal Color_map : std_logic_vector(2 DOWNTO 0);
signal hpix, vpix : std_logic_vector(7 DOWNTO 0);
signal Clock_50Mhz : std_logic;
signal Clock_25Mhz : std_logic;

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

Red_Data <= Color_map(2);
Green_Data <= Color_map(1);
Blue_Data <= Color_map(0);

video_on_H <= H_count < H_SIZE;
video_on_V <= V_count < V_SIZE;
video_on <= video_on_H and video_on_V;

Horiz_Sync_int <= (H_count >= (H_SIZE+H_BACK)) and (H_count < (H_SIZE+H_BACK+H_SYNC));
Vert_Sync_int <= (V_count >= (V_SIZE+V_BACK)) and (V_count < (V_SIZE+V_BACK+V_SYNC));

with video_on select Red <= Red_Data when true, '0' when false;
with video_on select Green <= Green_Data when true, '0' when false;
with video_on select Blue <= Blue_Data when true, '0' when false;

with Horiz_Sync_int select Horiz_Sync <= H_POL when true, not H_POL when false;
with Vert_Sync_int select Vert_Sync <= V_POL when true, not V_POL when false;

with hinrange and vinrange select
    Color_map <= Color_palette(conv_integer(ram_data)) when true,
	              Color_palette((conv_integer(H_Count)/2 + (conv_integer(V_count)/2)) mod 4) when false;

-- I could not get multipliation nor left shift to work properly...
-- read_address <= vpix*160 + hpix
-- 160 == 1<<7 + 1<<5
read_address <= (vpix&"0000000") + ("00"&vpix&"00000") + ("0000000" & hpix);


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


--Generate Horizontal and Vertical Timing Signals for Video Signal
--For details see Rapid Prototyping of Digital Systems Chapter 9
VIDEO_DISPLAY: Process(Clock_100Mhz)
Begin
 IF (Clock_100Mhz'event) and (Clock_100Mhz='1') Then

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

end if; -- clock event
end process VIDEO_DISPLAY;

end behavior;

