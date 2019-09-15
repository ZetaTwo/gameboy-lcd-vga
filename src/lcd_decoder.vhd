library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity lcd_decoder is

   port( signal Clock_100Mhz : in std_logic;
		   signal gb_hsync, gb_vsync, gb_clock, gb_d0, gb_d1: in std_logic;
		   signal ram_write_en : out std_logic;
		  	signal ram_data : out std_logic_vector(1 downto 0);
		   signal ram_write_address : out std_logic_vector(14 downto 0));
       		
end lcd_decoder;

architecture behavior of lcd_decoder is

signal gb_xpos, gb_ypos : std_logic_vector(7 downto 0);
signal gb_vsync_int : std_logic;
signal write_enable_counter, vsync_counter : std_logic_vector(3 downto 0);

begin

ram_data <= gb_d1 & gb_d0;

-- I could not get multipliation nor left shift to work properly...
-- read_address <= vpix*160 + hpix
-- 160 == 1<<7 + 1<<5
ram_write_address <= (gb_ypos&"0000000") + ("00"&gb_ypos&"00000") + ("0000000" & gb_xpos);

horizontal : process(gb_clock, gb_hsync)
begin
	if gb_hsync = '1' then
		gb_xpos <=  "00000000";
	elsif gb_clock'event and gb_clock = '1' then
		if gb_xpos < 160 then
			gb_xpos <= gb_xpos + 1;
		end if;
	end if;
end process;

vertical : process(gb_hsync, gb_vsync_int)
begin
	if gb_vsync_int = '1' then
		gb_ypos <=  "00000000";
	elsif gb_hsync'event and gb_hsync = '1' then
		if gb_ypos < 144 then
			gb_ypos <= gb_ypos + 1;
		end if;
	end if;
end process;

writeEn : process(gb_clock, Clock_100Mhz)
begin
	if gb_clock = '1' then
		write_enable_counter <=  "0000";
		ram_write_en <= '0';
	elsif Clock_100Mhz'event and Clock_100Mhz = '1' then
		if write_enable_counter < 4 then
			ram_write_en <= '1';
			write_enable_counter <= write_enable_counter + 1;
		else
			ram_write_en <= '0';
		end if;
	end if;
end process;

vsyncHyst : process(gb_vsync, Clock_100Mhz)
begin
	if Clock_100Mhz'event and Clock_100Mhz = '1' then
		if gb_vsync_int = gb_vsync then
			vsync_counter <=  "0000";
		else
			if vsync_counter < 10 then
				vsync_counter <= vsync_counter + 1;
			else
				-- counter has reached target value
				gb_vsync_int <= gb_vsync;
				vsync_counter <=  "0000";
			end if;
		end if;
	end if;
end process;

end behavior;

