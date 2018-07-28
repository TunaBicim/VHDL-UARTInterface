entity Top_TB is 
end Top_TB;

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL; 

architecture BENCH OF Top_TB is 
  
  component Top is   
    port( 
        clk_per_bit         : in STD_LOGIC_VECTOR(31 downto 0); --Number of clocks edges for 1 bit to arrive
        parity_bit          : in STD_LOGIC_VECTOR(2  downto 0); --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
        stop_bits           : in STD_LOGIC_VECTOR(1  downto 0); --Stopbit case input. Cases(1,1.5,2) are indexed as (00,01,10)
        data_length         : in STD_LOGIC;                     --Number of bits being sent. Selections (7,8) are indexed as (0,1)
        clk                 : in STD_LOGIC;                     --Input clock usually 10MHz
        rst                 : in STD_LOGIC;                     --Active low reset
        option_change       : in STD_LOGIC;                     --Option change input to indicate one the the setup signals has changed thus the system should go on setup state
        serial_in           : in STD_LOGIC;
        parity_error        : out STD_LOGIC;                    --Parity error output signal
        option_done_tx      : out STD_LOGIC;
        option_done_rx      : out STD_LOGIC;                   --Output signal to indicate the setup has been done and system can be turned back to the idle state
        tx_serial           : out STD_LOGIC;
        tx_active           : out STD_LOGIC;
        led_r               : out STD_LOGIC;                    --Output signal to light red led up
        led_g1              : out STD_LOGIC;                    --Output signal to light green 1 led up
        led_g2              : out STD_LOGIC;                    --Output signal to light green 2 led up
        led_g3              : out STD_LOGIC);
    end component Top;
    
    signal clk_per_bit         : STD_LOGIC_VECTOR(31 downto 0); --Number of clocks edges for 1 bit to arrive
    signal parity_bit          : STD_LOGIC_VECTOR(2  downto 0); --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
    signal stop_bits           : STD_LOGIC_VECTOR(1  downto 0); --Stopbit case input. Cases(1,1.5,2) are indexed as (00,01,10)
    signal data_length         : STD_LOGIC;                     --Number of bits being sent. Selections (7,8) are indexed as (0,1)
    signal clk                 : STD_LOGIC;                     --Input clock usually 10MHz
    signal rst                 : STD_LOGIC;                     --Active low reset
    signal option_change       : STD_LOGIC;                     --Option change input to indicate one the the setup signals has changed thus the system should go on setup state
    signal serial_in           : STD_LOGIC;
    signal parity_error        : STD_LOGIC;                     --Parity error output signal
    signal option_done_tx      : STD_LOGIC;
    signal option_done_rx      : STD_LOGIC;                   --Output signal to indicate the setup has been done and system can be turned back to the idle state
    signal tx_serial           : STD_LOGIC;						-- Define tx_dv input port for the data come or not
    signal tx_active           : STD_LOGIC;    -- Define input 8 byte data port 
    signal led_r               : STD_LOGIC;                    --Output signal to light red led up
    signal led_g1              : STD_LOGIC;                    --Output signal to light green 1 led up
    signal led_g2              : STD_LOGIC;                    --Output signal to light green 2 led up
    signal led_g3              : STD_LOGIC;
    constant bit_period        : time:= 8700 NS;

begin

    clk_per_bit <= conv_std_logic_vector(87,32);
    parity_bit      <= "010";
    stop_bits       <= "00";
    data_length     <= '1';
    option_change   <= '0';
    rst             <= '0', 
                       '1' after 0.5*bit_period;
                       --'0' after 35*bit_period, 
                       --'1' after 36*bit_period;
     
    serial_in   <=  '1', 
					'0' after bit_period,    	--start bit
					'0' after 2*bit_period,  	--bit0
					'1' after 3*bit_period,  	--bit1
					'0' after 4*bit_period,  	--bit2
					'0' after 5*bit_period,  	--bit3
					'1' after 6*bit_period,  	--bit4
					'0' after 7*bit_period,  	--bit5
					'1' after 8*bit_period,  	--bit6
					'0' after 9*bit_period,     --bit7
					'1' after 10*bit_period,  	--stop bit
					'0' after 11*bit_period, 	--start bit    01000111
					'1' after 12*bit_period, 	--bit0
					'1' after 13*bit_period, 	--bit1
					'1' after 14*bit_period, 	--bit2
					'0' after 15*bit_period, 	--bit3
					'0' after 16*bit_period, 	--bit4
					'0' after 17*bit_period, 	--bit5
					'1' after 18*bit_period, 	--bit6
					'0' after 19*bit_period,    --bit7 
					'1' after 20*bit_period, 	--stop bit
					'0' after 21*bit_period, 	--start bit  01010010
					'0' after 22*bit_period, 	--bit0
					'1' after 23*bit_period, 	--bit1
					'0' after 24*bit_period, 	--bit2
					'0' after 25*bit_period, 	--bit3
					'1' after 26*bit_period, 	--bit4
					'0' after 27*bit_period, 	--bit5
					'1' after 28*bit_period, 	--bit6
					'0' after 29*bit_period,    --bit7 
					'1' after 30*bit_period; 	--stop bit
		
    
    ClockGen: process
        begin 
            for I in 1 to 1000000000 loop
            CLK<= '1';
            wait for 50 NS;
            CLK<= '0';
            wait for 50 NS;
            end loop;
        wait;
        end process;
   
   System: Top port map(clk_per_bit  => clk_per_bit,
						parity_bit    => parity_bit,
						stop_bits     => stop_bits,
						data_length   => data_length,
						clk => clk,
						rst => rst,
						option_change  => option_change,
						serial_in      => serial_in,
						parity_error   => parity_error,
						option_done_tx => option_done_tx,
						option_done_rx => option_done_rx,
						tx_serial      => tx_serial,
						tx_active      => tx_active,
						led_r  => led_r,
						led_g1 => led_g1,
						led_g2 => led_g2,
						led_g3 => led_g3 );
    
end BENCH;

use work.all;
configuration CFG_Top_TB of Top_TB is
    for BENCH
    end for;
end;

