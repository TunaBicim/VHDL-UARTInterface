--------------------------------------------------------------------------------
-- Project Name      : UART_TRANSMITTER                                       --
-- System/Block Name : Testbench		                                      --
-- Design Engineer   : Tuna Bicim                                             --  
-- Date              : 27.07.2017                                             --
-- Short Description : This module tests functionality of UART transmitter    --
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity Transmitter_tb is 
end Transmitter_tb ;

architecture BENCH of Transmitter_tb  is
  component UART_TX is
    port (
    clk             : in STD_LOGIC;													-- Define clock input port
    rst             : in STD_LOGIC;													-- Define reset input port
	
   	data_length     : in STD_LOGIC := '0';  								 
    parity          : in STD_LOGIC_VECTOR(2 downto 0) := "000";   								 
    stop_bit_length : in STD_LOGIC_VECTOR(1 downto 0) := "00";    									
    baud_rate       : in STD_LOGIC_VECTOR(31 downto 0):= conv_std_logic_vector(10000000/115200,32);
	option_change   : in STD_LOGIC;
	option_done     : out STD_LOGIC;
	
    tx_dv           : in STD_LOGIC;						 							-- Define tx_dv input port for the data come or not
    tx_byte         : in STD_LOGIC_VECTOR(7 downto 0);	-- Define input 8 byte data port 
    tx_active       : out STD_LOGIC;												-- Define the output port which determine the data sending or not
    tx_serial       : out STD_LOGIC;												-- Define the output port for the send 1 bit data 
    tx_done         : out STD_LOGIC);		
  end component UART_TX;

  component UART_TX_CONT is
	port (														-- Define port
		clk         : in STD_LOGIC;								-- Define clock input port
		rst         : in STD_LOGIC;								-- Define reset input port
		tx_done     : in STD_LOGIC;								-- Define the output port which determine that the data sending finished or not		
	  
		led_r  		: in STD_LOGIC;
		led_g1 		: in STD_LOGIC;
		led_g2 		: in STD_LOGIC;
		led_g3 		: in STD_LOGIC;
		
		tx_dv       : out STD_LOGIC;								-- Define tx_dv input port for the data come or not
		tx_byte     : out STD_LOGIC_VECTOR(7 downto 0) 	);  
	end component UART_TX_CONT;

  component UART_TX_BUFFER is
    port (														-- Define port
		clk        : in STD_LOGIC;								-- Define clock input port
		rst        : in STD_LOGIC;								-- Define reset input port
		
		led_r  	   : in STD_LOGIC;
		led_g1     : in STD_LOGIC;
		led_g2     : in STD_LOGIC;
		led_g3     : in STD_LOGIC;
		
		led_r_o      : out STD_LOGIC;
		led_g1_o     : out STD_LOGIC;
		led_g2_o     : out STD_LOGIC;
		led_g3_o     : out STD_LOGIC);
		
	end component UART_TX_BUFFER;

  signal clk_tb          : STD_LOGIC ;
  signal rst_tb          : STD_LOGIC ;
  
  signal tx_dv_tb        :  STD_LOGIC;
  signal tx_byte_tb      :  STD_LOGIC_VECTOR(7 downto 0);
  signal tx_active_tb    :  STD_LOGIC;
  signal tx_serial_tb    :  STD_LOGIC;
  signal tx_done_tb      :  STD_LOGIC;
  
  signal option_c_tb     : STD_LOGIC := '0';
  signal option_done_tb 	  : STD_LOGIC ;
  
  signal data_length_t_tb     : STD_LOGIC := '0';  								 
  signal parity_t_tb          : STD_LOGIC_VECTOR(2 downto 0) := "000";   								 
  signal stop_bit_length_t_tb : STD_LOGIC_VECTOR(1 downto 0) := "00";    									
  signal baud_rate_t_tb       : STD_LOGIC_VECTOR(31 downto 0):= conv_std_logic_vector(10000000/115200,32);
  
  signal red_t      : STD_LOGIC;
  signal green1_t   : STD_LOGIC;
  signal green2_t   : STD_LOGIC;
  signal green3_t   : STD_LOGIC;

  signal red_buffer_to_cont      : STD_LOGIC;
  signal green1_buffer_to_cont   : STD_LOGIC;
  signal green2_buffer_to_cont   : STD_LOGIC;
  signal green3_buffer_to_cont   : STD_LOGIC;

begin

 ClockGen: process
  begin 
    for I in 1 to 10000000 loop
      clk_tb <= '0';
      wait for 50 NS;
      clk_tb <= '1';
      wait for 50 NS;
    end loop;
    wait;
  end process;
      
	rst_tb 				  <= '0' ,'1' after 20 NS; 
	option_c_tb  	      <= '0';                                        --, '1' after 187 US, '0' after 197 US;  --, '1' after 25 NS, '0' after 250 NS
	data_length_t_tb      <= '0';                                        --, '0' after 188 US;
	parity_t_tb           <= "000";                                      --, "001" after 188 US;
	stop_bit_length_t_tb  <= "00";    								   --, "10" after 188 US;
	baud_rate_t_tb   	  <= conv_std_logic_vector(10000000/115200,32);  --, conv_std_logic_vector(10000000/57600,32) after 188 US; 
																		  --tx_byte_tb 			<= "10101010", "01010101" after 188 US; 
																		 -- tx_dv_tb   			<= '0', 
																			--					'1' after 300 NS,'0' after 400 NS,
																			--					'1' after 200 US,'0' after 201 US;
	red_t      <= '0','1' after 50 NS, '0' after 550 US;
	green1_t   <= '0','1' after 100 NS;
    green2_t   <= '0';
    green3_t   <= '0';
  																		
  
  
  Transmitter: UART_TX 
    port map(clk_tb, rst_tb, data_length_t_tb ,parity_t_tb ,stop_bit_length_t_tb ,baud_rate_t_tb,option_c_tb,  option_done_tb ,tx_dv_tb, tx_byte_tb, tx_active_tb, tx_serial_tb, tx_done_tb);     

  Transmitter_Cont: UART_TX_CONT 
	port map(clk_tb, rst_tb, tx_done_tb,red_buffer_to_cont,green1_buffer_to_cont,green2_buffer_to_cont,green3_buffer_to_cont,tx_dv_tb, tx_byte_tb);
	 
  Transmitter_Buffer: UART_TX_BUFFER 
	port map(clk_tb, rst_tb, red_t, green1_t, green2_t, green3_t,red_buffer_to_cont,green1_buffer_to_cont,green2_buffer_to_cont,green3_buffer_to_cont);
  
 
end BENCH; 

use work.all;
configuration CFG_Transmitter_tb   of Transmitter_tb  is
  for BENCH
  end for;
end;