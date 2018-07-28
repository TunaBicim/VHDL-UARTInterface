--------------------------------------------------------------------------------
-- Project Name      : UART_TRANSMITTER                                       --
-- System/Block Name : Transmitter Buffer                                     --
-- Design Engineer   : Tuna Bicim                                             --  
-- Date              : 27.07.2017                                             --
-- Short Description : This module synchronizes the led signals to clock      --
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity UART_TX_BUFFER is
  port (														
    clk        : in STD_LOGIC;								-- Define clock input port
    rst        : in STD_LOGIC;								-- Define reset input port
	
	led_r  	   : in STD_LOGIC;								--Active Low LED input signals
	led_g1     : in STD_LOGIC;
	led_g2     : in STD_LOGIC;
	led_g3     : in STD_LOGIC;
	
	led_r_o      : out STD_LOGIC;							--Active Low LED output signals
	led_g1_o     : out STD_LOGIC;
	led_g2_o     : out STD_LOGIC;
	led_g3_o     : out STD_LOGIC);
	
end UART_TX_BUFFER;

architecture V1 of UART_TX_BUFFER is
  
  signal red_t      : STD_LOGIC;
  signal green1_t   : STD_LOGIC;
  signal green2_t   : STD_LOGIC;
  signal green3_t   : STD_LOGIC;
  
  signal led_temp  : STD_LOGIC_VECTOR(3 downto 0);
  signal led_temp2 : STD_LOGIC_VECTOR(3 downto 0);
  
 begin 
  process(clk, rst)
  begin
    if rst = '0' then   
	  red_t     <= '0';
	  green1_t  <= '0';
	  green2_t  <= '0';
	  green3_t  <= '0';
	  
	  led_temp  <= "0000";
	  led_temp2 <= "0000";
 	  
	  led_r_o   <= '0';     
	  led_g1_o  <= '0';   
      led_g2_o  <= '0';   
	  led_g3_o  <= '0';
	  
	elsif rising_edge(clk) then
	  led_temp(0)  <= led_r;
	  led_temp(1)  <= led_g1;
	  led_temp(2)  <= led_g2;
	  led_temp(3)  <= led_g3;
	  
	  led_temp2    <= led_temp;
	  
	  if (led_temp2 /= led_temp) then
		led_r_o   <= led_temp(0);     
		led_g1_o  <= led_temp(1);   
		led_g2_o  <= led_temp(2);   
		led_g3_o  <= led_temp(3);
  	  end if;    
	  
	end if;
  end process;
 end V1;