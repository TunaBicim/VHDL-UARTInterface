---------------------------------------------------------------------------------
-- Project Name      : UART_TRANSMITTER                                        --
-- System/Block Name : Transmitter                                             --
-- Design Engineer   : Tuna Bicim                                              --  
-- Date              : 26.07.2017                                              --
-- Short Description : This is the transmitter block of the UART               --
--                     where the output signal is created by                   --
--                     converting the parallel data to serial pulses           --
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL; 

entity UART_Transmitter is

  port (														
    clk             : in STD_LOGIC;								-- Input clock usually 10MHz
    rst             : in STD_LOGIC;								-- Active low reset	
   	data_length     : in STD_LOGIC;  							-- Number of bits being sent. Selections (7,8) are indexed as (0,1)	 
    parity          : in STD_LOGIC_VECTOR(2 downto 0);   		-- Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)						 
    stop_bit_length : in STD_LOGIC_VECTOR(1 downto 0);    		-- Stop bit case input. Cases(1,1.5,2) are indexed as (00,01,10)							
    baud_rate       : in STD_LOGIC_VECTOR(31 downto 0);			-- Amount of bits that is sent per second 
	option_change   : in STD_LOGIC;								-- Input signal to indicate that a new configuration will be made 
	option_done 	: out STD_LOGIC;							-- Output signal to indicate the setup has been done and system can be turned back to the idle state
    tx_dv           : in STD_LOGIC;								-- Define tx_dv input port for the data come or not
    tx_byte         : in STD_LOGIC_VECTOR(7 downto 0);       	-- Define input 8 byte data port 
    tx_active       : out STD_LOGIC;							-- Define the output port which determine the data sending or not
    tx_serial       : out STD_LOGIC;							-- Define the output port for the send 1 bit data 
    tx_done         : out STD_LOGIC								-- Define the output port which determine that the data sending finished or not		
  );  
end UART_Transmitter;

architecture TRANSMITTER of UART_Transmitter is
  
  type UART_TRANSMITTER_STATE_TYPES is (IDLE, TX_START_BIT, TX_DATA_BITS, PARITY_r, TX_STOP_BIT, LED_WRITEOUT,CLEANUP, SETUP); -- Transmitter state types
  signal tx_state     : UART_TRANSMITTER_STATE_TYPES; -- Define the signal which refer to the main state 
   
  signal data_length_t     : STD_LOGIC;  								 
  signal parity_t          : STD_LOGIC_VECTOR(2 downto 0);   								 
  signal stop_bit_length_t : STD_LOGIC_VECTOR(1 downto 0);    									
  signal baud_rate_t       : STD_LOGIC_VECTOR(31 downto 0);
  
  
  constant EVEN_p      : STD_LOGIC_VECTOR(2 downto 0):="000";	-- Parity bit is taken from the generic port which is consist of 3 bit array	
  constant ODD_p       : STD_LOGIC_VECTOR(2 downto 0):="001";	--   to be able to use taken parity with case structere, define the each case 				
  constant NONE_p      : STD_LOGIC_VECTOR(2 downto 0):="010";   --   like as a constant. When the parity is equal to defining constant value, 
  constant MARK_p      : STD_LOGIC_VECTOR(2 downto 0):="011";	--   enter this case. Default parameter given; EVEN = 000, ODD = 001, NONE = 010,
  constant SPACE_p     : STD_LOGIC_VECTOR(2 downto 0):="100";	--   											 MARK = 011, SPACE = 100.
  constant STOPBIT_1   : STD_LOGIC_VECTOR(1 downto 0):="00";  	-- Stop bit is taken from the generic port which is consist of 2 bit array to be able to use taken stop bit 
  constant STOPBIT_1_5 : STD_LOGIC_VECTOR(1 downto 0):="01";   	--   with case structere, define the each case like as a constant. When the stop bit is equal to defining 
  constant STOPBIT_2   : STD_LOGIC_VECTOR(1 downto 0):="10";   	--   constant value, enter this case. Default parameter length given; 1 = 00, 1.5 = 01, 2 = 10 
  constant BIT_LENGTH  : STD_LOGIC_VECTOR(3 downto 0):="0110";
  
  signal clk_per_bit   : STD_LOGIC_VECTOR(31 downto 0);  		-- Define clock frequency / baudrate which becomes number of clock cycles for a bit
  signal clk_count     : STD_LOGIC_VECTOR(31 downto 0);		    -- Define the counter signal
  signal bit_index     : STD_LOGIC_VECTOR(3 downto 0);			-- Define bit index, which is show data index when sending serial port.
  signal tx_data       : STD_LOGIC_VECTOR(7 downto 0); 			-- Define the 8 bit data signal
  signal tx_done_r     : STD_LOGIC ;							-- Define the tx_done signal which is show the data sending end(=1) or not(=0)
  signal parity_bit    : STD_LOGIC ;							-- Define the parity bit signal which is used for the calculating parity bit(odd and even part)
  
  
begin 
  process(clk, rst) 
  begin
    if rst = '0' then    --Asynchronous Active Low Reset
	  tx_state			 <= SETUP;
	  data_length_t      <= '0';  								 
	  parity_t           <= "000";   								 
	  stop_bit_length_t  <= "00";    									
	  baud_rate_t        <= conv_std_logic_vector(10000000/57600,32);
	  tx_active    <= '0';
      tx_serial    <= '1';
	  option_done  <= '0';
	  
      clk_per_bit  <= (others => '0');
	  clk_count    <= (others => '0');
      bit_index    <= (others => '0');
	  tx_data      <= (others => '0');
	  
	  tx_done_r    <= '0';
      parity_bit   <= '0';
	  
	elsif rising_edge(clk) then --Synchronous Process
      case tx_state is
      when IDLE =>						--Stay in IDLE until data comes and return to IDLE when CLEANUP ends								
          if (option_change = '1') then
			tx_state   <= SETUP;
		  else
			clk_per_bit  <= baud_rate_t;                 
			tx_active    <= '0';
			tx_serial    <= '1';
			tx_done_r    <= '0';
			clk_count    <= (others => '0');
			bit_index    <= (others => '0');
			option_done  <= '0';
		  
			if tx_dv = '1' then
				tx_data(7 downto 0) <= tx_byte;
				tx_state     <= TX_START_BIT;									
			else
				tx_state     <= IDLE;											
			end if;
		  end if;		  	  
	
      when TX_START_BIT =>       --Send the start bit
          tx_active    <= '1';					
          tx_serial    <= '0';
          parity_bit   <= '0';

          if clk_count < clk_per_bit-1 then 
            clk_count  <= clk_count+1;
            tx_state   <= TX_START_BIT;
          else 
            clk_count  <= (others => '0');
			tx_state   <= TX_DATA_BITS;
          end if;
		  
	  when TX_DATA_BITS =>		 -- Send the data bits
          tx_serial    <= tx_data(conv_integer(bit_index));          
          if clk_count < clk_per_bit-1 then
            clk_count  <= clk_count+1;
            tx_state   <=  TX_DATA_BITS;
          else
            clk_count    <= (others => '0');
			
			if (bit_index < BIT_LENGTH + data_length_t) then
			  bit_index  <= bit_index +1;
              tx_state   <= TX_DATA_BITS;
            else
              bit_index  <= (others => '0');								-- Reset the bit_index
			  tx_state 	 <= PARITY_r;										-- Assign the next state
			  parity_bit <= tx_data(0) xor tx_data(1) xor tx_data(2) xor  	-- Check parity
							tx_data(3) xor tx_data(4) xor tx_data(5) xor    
							tx_data(6) xor tx_data(7);						
            end if;
          end if;
      
      when PARITY_r =>   	-- Send the parity bit 
          case parity_t  is						
		  when EVEN_p =>  								-- When parity equal even
			  tx_serial  <= parity_bit;                 -- Write parity bit, which is calculated at TX_DATA_BITS part, into the serial port
              if clk_count < clk_per_bit-1 then         -- Up to clk_per_bit-1, count the clk_counter
                clk_count  <= clk_count+1;
                tx_state   <= PARITY_r;
              else 										-- If clk_count reach the clk_per_bit
                clk_count  <= (others => '0');			-- Reset clk_count
                tx_state   <= TX_STOP_BIT;				-- Pass through the next state(STOP_BIT)
              end if;  
			  
          when ODD_p => 								-- When parity equal odd
			  tx_serial  <= not (parity_bit);           -- Write parity bit, which is calculated at TX_DATA_BITS part, into the serial port
              if clk_count < clk_per_bit-1 then         -- Up to clk_per_bit-1, count the clk_counter
                clk_count  <= clk_count+1;
                tx_state   <= PARITY_r;
              else 										-- If clk_count reach the clk_per_bit
                clk_count  <= (others => '0');			-- Reset clk_count
                tx_state   <= TX_STOP_BIT;				-- Pass through the next state(STOP_BIT)
              end if;  
              
          when NONE_p =>                         		-- When parity equal none
              tx_state  <= TX_STOP_BIT;					-- If parity bit equal to NONE, nothing do and pass through the next state (STOP_BIT)			
          
          when MARK_p =>                         		-- When parity equal mark
              tx_serial <= '1';							-- Write parity bit = 1  into the serial port
              if clk_count < clk_per_bit-1 then         -- Up to clk_per_bit-1, count the clk_counter
                clk_count  <= clk_count+1;
                tx_state   <= PARITY_r;
              else 										-- If clk_count reach the clk_per_bit
                clk_count  <= (others => '0');			-- Reset clk_count
                tx_state   <= TX_STOP_BIT;              -- Pass through the next state(STOP_BIT)
              end if;
          
          when SPACE_p =>                         		-- When parity equal space
              tx_serial <= '0';							-- Write parity bit = 0  into the serial port
              if clk_count < clk_per_bit-1 then         -- Up to clk_per_bit-1, count the clk_counter
                clk_count  <= clk_count+1;
                tx_state   <= PARITY_r;
              else 										-- If clk_count reach the clk_per_bit
                clk_count  <= (others => '0');			-- Reset clk_count
                tx_state   <= TX_STOP_BIT;              -- Pass through the next state(STOP_BIT)
              end if;
              
          when others =>                                -- If undefined parity_bit come, pass through the next state(STOP_BIT)
              tx_state  <= TX_STOP_BIT;
          end case;
                          
      when TX_STOP_BIT =>								-- Send the stop bit
		  case stop_bit_length is
		  when STOPBIT_1 =>
              tx_serial <= '1';
              if clk_count < clk_per_bit-1 then
                clk_count  <= clk_count+1;
                tx_state   <= TX_STOP_BIT;
              else
                tx_done_r  <= '1';
                clk_count  <= (others => '0');
				tx_state   <= Cleanup;
              end if;
		  when STOPBIT_1_5 =>
              tx_serial <= '1';
              if clk_count < (clk_per_bit+('0' & clk_per_bit(31 downto 1)))-1 then
                clk_count  <= clk_count+1;
                tx_state   <= TX_STOP_BIT;
              else
                tx_done_r  <= '1';
                clk_count  <= (others => '0');
                tx_state   <= Cleanup;
              end if;
		  when STOPBIT_2 =>
              tx_serial <= '1';
              if clk_count < (clk_per_bit(30 downto 0) & '0')-1 then   
                clk_count  <= clk_count+1;
                tx_state   <= TX_STOP_BIT;
              else
                tx_done_r  <= '1';
                clk_count  <= (others => '0');
                tx_state   <= CLEANUP;
              end if;
		  when others =>
			    tx_state   <= TX_STOP_BIT;
		  end case;
		  		  
	  when CLEANUP =>		--Set signals to their initial values and return back to IDLE
          tx_active   <= '0';
          if (option_change = '1')  then
			tx_state  <= SETUP;	
		  else
			tx_state  <= IDLE;
		  end if;
	  
	  when SETUP =>         	--When Number of clocks per bit, data length, parity or stop bits change the 
                                --system enters the setup state to assign the new values to the temp signals 
			data_length_t     <= data_length;  								 
			parity_t          <= parity;   								 
			stop_bit_length_t <= stop_bit_length;    									
			baud_rate_t       <= baud_rate;
			option_done       <= '1';
			tx_state  		  <= IDLE;	
		
      when Others =>
		tx_state <= IDLE;      
      
      end case; 
    end if;
  end process; 
  tx_done <= tx_done_r;                       
end TRANSMITTER;