--------------------------------------------------------------------------------
-- Project Name      : UART_TRANSMITTER                                       --
-- System/Block Name : Transmitter Controller                                 --
-- Design Engineer   : Tuna Bicim                                             --  
-- Date              : 27.07.2017                                             --
-- Short Description : This is the controller for transmitter which 		  --
-- 					   sends couple of ASCII characters when a key is         --
--					   pressed to indicate which LED will be turned on        --
--					   while also turning that LED on. 						  --
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity UART_TX_CONT is
  port (														
    clk         : in STD_LOGIC;								-- Define clock input port
    rst         : in STD_LOGIC;								-- Define reset input port
	tx_done     : in STD_LOGIC;								-- Define the output port which determine that the data sending finished or not		
  
	led_r  		: in STD_LOGIC;								-- LED signals
	led_g1 		: in STD_LOGIC;
	led_g2 		: in STD_LOGIC;
	led_g3 		: in STD_LOGIC;
	
    tx_dv       : out STD_LOGIC;								-- Define tx_dv input port for the data
    tx_byte     : out STD_LOGIC_VECTOR(7 downto 0) 	);  
end UART_TX_CONT;

architecture V1 of UART_TX_CONT is
  
  type SM_Main is (IDLE, RED, TX_RED, GREEN, TX_GREEN);		  	-- Define the main state
  signal tc_state     : Sm_Main; 					      	    -- Define the signal which refer to the main state 
  
  signal word_count     : STD_LOGIC_VECTOR(3 downto 0);
  signal tx_byte_t      : STD_LOGIC_VECTOR(7 downto 0); 			    -- Define the 8 bit data signal
  signal tx_dv_t	    : STD_LOGIC ;  
  
  signal red_t      : STD_LOGIC;
  signal green1_t   : STD_LOGIC;
  signal green2_t   : STD_LOGIC;
  signal green3_t   : STD_LOGIC;
  signal green_index : STD_LOGIC_VECTOR(1 downto 0);
  
  constant G     : STD_LOGIC_VECTOR(7 downto 0):= "01000111";  -- Define ASCII values
  constant R     : STD_LOGIC_VECTOR(7 downto 0):= "01010010";  
  constant E     : STD_LOGIC_VECTOR(7 downto 0):= "01000101";  
  constant N     : STD_LOGIC_VECTOR(7 downto 0):= "01001110";  
  constant O     : STD_LOGIC_VECTOR(7 downto 0):= "01001111";  
  constant D     : STD_LOGIC_VECTOR(7 downto 0):= "01000100";  
  constant F     : STD_LOGIC_VECTOR(7 downto 0):= "01000110";  
  constant G1    : STD_LOGIC_VECTOR(7 downto 0):= "00110001";  
  constant G2    : STD_LOGIC_VECTOR(7 downto 0):= "00110010";  
  constant G3    : STD_LOGIC_VECTOR(7 downto 0):= "00110011";  
  constant SPACE : STD_LOGIC_VECTOR(7 downto 0):= "00100000";  

 begin 
  process(clk, rst)
  begin
    if rst = '0' then -- Asynchronous reset
	  tc_state		 <= IDLE;
	       
      word_count    <= (others => '0');
	  tx_byte_t     <= (others => '0');
	  
	  red_t     <= '0';
	  green1_t  <= '0';
	  green2_t  <= '0';
	  green3_t  <= '0';
	  
	elsif rising_edge(clk) then	-- Synchronous process
		case tc_state is
		when IDLE =>
			red_t     <= led_r;
			green1_t  <= led_g1;
			green2_t  <= led_g2;
			green3_t  <= led_g3;
			word_count <= (others => '0');
			
			if (led_r /= red_t) then -- If the buffered signal is not equal to current then a change has occurred
				tc_state <= RED;
			elsif (led_g1 /= green1_t) then
				tc_state <= GREEN;
				green_index <= "01";
			elsif (led_g2 /= green2_t) then
				tc_state <= GREEN;
				green_index <= "10";
			elsif (led_g3 /= green3_t) then
				tc_state <= GREEN;
				green_index <= "11";
			else
				tc_state <= IDLE;
			end if;
		
		when RED => -- Spell out Red On or Off to be sent
			tx_dv_t <= '0';
			if (word_count = "0000") then
				tx_byte_t <= R;	
				tc_state <= TX_RED ;
			elsif tx_done = '1' then
				case word_count is
				when "0001" =>
					tx_byte_t <= E;	
					tc_state <= TX_RED ;
				when "0010" =>
					tx_byte_t <= D;	
					tc_state <= TX_RED ;
				when "0011" =>
					tx_byte_t <= SPACE;	
					tc_state <= TX_RED;
				when "0100" =>
					tx_byte_t <= O;	
					tc_state <= TX_RED;
				when "0101" =>
					if (red_t = '1') then
						tx_byte_t <= N;	
						tc_state <= TX_RED ;	
					else 
						tx_byte_t <= F;	
						tc_state <= TX_RED ;
					end if;
				when "0110" =>
					if (red_t = '1') then	
						tc_state <= IDLE;	
					else 
						tx_byte_t <= F;	
						tc_state <= TX_RED ;
					end if;
				when others =>
					tc_state <= IDLE;
				end case;
			end if;
			
		when TX_RED => -- Transmit the indicated bit
			tx_dv_t <= '1';
			word_count <= word_count + '1';
			tc_state <= RED;
			
		when GREEN => -- Spell out Green 1,2 or 3 On or Off
			tx_dv_t <= '0';
			if (word_count = "0000") then
				tx_byte_t <= G;	
				tc_state <= TX_GREEN ;
			elsif tx_done = '1' then
				case word_count is
				when "0001" =>
					tx_byte_t <= R;	
					tc_state <= TX_GREEN ;
				when "0010" =>
					tx_byte_t <= E;	
					tc_state <= TX_GREEN ;
				when "0011" =>
					tx_byte_t <= E;	
					tc_state <= TX_GREEN;
				when "0100" =>
					tx_byte_t <= N;	
					tc_state <= TX_GREEN;
				
				when "0101" =>
					case green_index is
					when "01" =>
						tx_byte_t <= G1;	
						tc_state <= TX_GREEN;
					when "10" =>
						tx_byte_t <= G2;	
						tc_state <= TX_GREEN;
					when "11" =>
						tx_byte_t <= G3;	
						tc_state <= TX_GREEN;
					when others =>
						tx_byte_t <= SPACE;	
						tc_state <= TX_GREEN;
					end case;
				when "0110" =>
					tx_byte_t <= SPACE;	
					tc_state <= TX_GREEN;
				when "0111" =>
					tx_byte_t <= O;	
					tc_state <= TX_GREEN;
				
				when "1000" =>
					case green_index is
					when "01" =>
						if (green1_t = '1') then	
							tx_byte_t <= N;	
							tc_state <= TX_GREEN;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;
						
					when "10" =>
						if (green2_t = '1') then	
							tx_byte_t <= N;	
							tc_state <= TX_GREEN;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;
					when "11" =>
						if (green3_t = '1') then	
							tx_byte_t <= N;	
							tc_state <= TX_GREEN;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;
						
					when others =>
						tc_state <= IDLE;
					end case;
					
				when "1001" =>
					case green_index is
					when "01" =>
						if (green1_t = '1') then	
							tc_state <= IDLE;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;
						
					when "10" =>
						if (green2_t = '1') then	
							tc_state <= IDLE;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;
						
					when "11" =>
						if (green3_t = '1') then	
							tc_state <= IDLE;	
						else 
							tx_byte_t <= F;	
							tc_state <= TX_GREEN ;
						end if;	
						
					when others =>
						tc_state <= IDLE;
					end case;
					
				when others =>
					tc_state <= IDLE;
				end case;
			end if;
			
		when TX_GREEN => -- Transmit the indicated bit
			tx_dv_t <= '1';
			word_count <= word_count + '1';
			tc_state <= GREEN;
				
		when others =>
			tc_state <= IDLE;
		
		end case;
			
		tx_dv   <= tx_dv_t;
		tx_byte <= tx_byte_t;     
			
	end if;
 end process; 	
end V1;			
			