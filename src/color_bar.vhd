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

entity Color_Bar is

   port( signal Clock_48Mhz : in std_logic;
        signal Red,Green,Blue : out std_logic;
        signal Horiz_sync,Vert_sync : out std_logic);
       		
end Color_Bar;

architecture behavior of Color_Bar is

TYPE color IS ARRAY ( 0 TO 3 ) OF STD_LOGIC_VECTOR( 2 DOWNTO 0 );
SIGNAL color_palette			: color;

-- Video Display Signals   
signal H_count,V_count: std_logic_vector(10 Downto 0);
signal Red_Data, Green_Data, Blue_Data, video_on : std_logic;
signal video_on_H, video_on_V : std_logic;
signal Horiz_Sync_int, Vert_Sync_int : std_logic;
signal Bar_col_count : std_logic_vector(5 DOWNTO 0);
signal Color_map : std_logic_vector(2 DOWNTO 0);

signal Bar_num :std_logic_vector(4 DOWNTO 0);
signal Clock_24Mhz : std_logic;

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
Color_palette(0) <= "000"; -- black
Color_palette(1) <= "001"; -- blue
Color_palette(2) <= "011"; -- cyan
Color_palette(3) <= "111"; -- white

-- video_on turns off pixel color data when not in the pixel view area
video_on <= video_on_H and video_on_V;

-- This process computes a color to each pixel as the image is scanned by the monitor
-- no pixel memory is used.

Color_COMPUTE: Process (clock_48Mhz)
Begin
 IF (clock_48Mhz'event) and (clock_48Mhz='1') Then
-- This code uses col counters to count off 27 color bars across the screen
 IF  H_Count=799 THEN Bar_Col_count <= "000000"; Bar_num <="00000"; 
 ELSIF Bar_col_count <46 THEN Bar_col_count <= Bar_col_count + 1;
 ELSE
   Bar_col_count <= "000000";
   IF Bar_num < 26 THEN Bar_num <= Bar_num + 1;
   ELSE Bar_num <="00000"; END IF;
 END IF;

-- Gameboy display is 160 x 144 pixels
---one logical pixel is 3x3 VGA pixels, so screen size is 480x432
--- total VGA size is 640x480
IF H_Count < 480 and V_Count < 432 THEN
Color_map <= Color_palette((conv_integer(H_Count)/8 + (conv_integer(V_count)/4)) mod 4);
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
 Red <=   Red_Data and video_on;
 Green <= Green_Data and video_on;
 Blue <=  Blue_Data and video_on;

 Horiz_Sync <= Horiz_Sync_int;
 Vert_Sync <= Vert_Sync_int;

END IF;
end process Color_COMPUTE;


--Generate Horizontal and Vertical Timing Signals for Video Signal
--For details see Rapid Prototyping of Digital Systems Chapter 9
VIDEO_DISPLAY: Process
Begin
Wait until(Clock_48Mhz'Event) and (Clock_48Mhz='1');
-- Clock enable used for a 24Mhz video clock rate
-- 640 by 480 display mode needs close to a 25Mhz pixel clock
-- 24Mhz should work on most new monitors
Clock_24Mhz <= NOT Clock_24Mhz;
-- H_count counts pixels (640 + extra time for sync signals)
--
--   <-Clock out RGB Pixel Row Data ->   <-H Sync->
--   ------------------------------------__________--------
--   0                           640   659       755    799
--
If Clock_24Mhz = '1' then
If (H_count >= 799) then
   H_count <= B"00000000000";
Else
   H_count <= H_count + 1;
End if;

--Generate Horizontal Sync Signal
If (H_count <= 755) and (H_count >= 659) Then
   Horiz_Sync_int <= '0';
ELSE
   Horiz_Sync_int <= '1';
End if;

--V_count counts rows of pixels (480 + extra time for sync signals)
--
--  <---- 480 Horizontal Syncs (pixel rows) -->  ->V Sync<-
--  -----------------------------------------------_______------------
--  0                                       480    493-494          524
--
If (V_count >= 524) and (H_count >= 699) then
   V_count <= B"00000000000";
Else If (H_count = 699) Then
   V_count <= V_count + 1;
End if;
End if;

-- Generate Vertical Sync Signal
If (V_count <= 494) and (V_count >= 493) Then
   Vert_Sync_int <= '0';
ELSE
   Vert_Sync_int <= '1';
End if;

-- Generate Video on Screen Signals for Pixel Data
If (H_count <= 639) Then
   video_on_H <= '1';
ELSE
   video_on_H <= '0';
End if;

If (V_count <= 479) Then
   video_on_V <= '1';
ELSE
   video_on_V <= '0';
End if;

End if;
end process VIDEO_DISPLAY;

end behavior;

