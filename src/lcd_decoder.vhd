library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity lcd_decoder is

   port( signal Clock_48Mhz : in std_logic;
		   signal gb_hsync, gb_vsync, gb_clock, gb_d0, gb_d1: in std_logic;
		   signal ram_write_en : out std_logic;
		  	signal ram_data : out std_logic_vector(1 downto 0);
		   signal ram_write_address : out std_logic_vector(14 downto 0));
       		
end lcd_decoder;

architecture behavior of lcd_decoder is

signal gb_xpos, gb_ypos : std_logic_vector(7 downto 0);
signal gb_hsync_prev, gb_clock_prev: std_logic;

begin

ram_data <= gb_d1 & gb_d0;

-- I could not get multipliation nor left shift to work properly...
-- read_address <= vpix*160 + hpix
-- 160 == 1<<7 + 1<<5
ram_write_address <= (gb_ypos&"0000000") + ("00"&gb_ypos&"00000") + ("0000000" & gb_xpos);

GB_input: Process (clock_48Mhz)
Begin
 IF (clock_48Mhz'event) and (clock_48Mhz='1') Then
 
 if gb_vsync = '1' then
	gb_xpos <= "00000000";
	gb_ypos <= "00000000";
	ram_write_en <= '0';
 else
	-- no vsync
	if gb_hsync = '1' then
	   gb_xpos <= "00000000";
		ram_write_en <= '0';
		if gb_hsync_prev = '0' then
			if gb_ypos < 144 then
				gb_ypos <= gb_ypos + 1;
			end if;
			gb_hsync_prev <= '1';
		end if;
	else
	   gb_hsync_prev <= '0';
		if gb_clock = '0' then
			if gb_clock_prev = '1' then
				-- falling edge
				if gb_xpos < 160 then
					gb_xpos <= gb_xpos + 1;
					ram_write_en <= '1';
				else
					ram_write_en <= '0';
				end if;
				gb_clock_prev <= '0';
			else
				ram_write_en <= '0';
			end if; -- gbclockprev
		else
			ram_write_en <= '0';
			gb_clock_prev <= '1';
		end if; -- gbclock
	end if; -- gbhsync
end if; -- vsync

END IF;
end process GB_input;

end behavior;

