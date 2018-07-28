---------------------------------------------------------------------------------
-- Project Name      : UART_RECEIVER                                           --
-- System/Block Name : Receiver                                                --
-- Design Engineer   : Tuna Bicim                                              --
-- Date              : 27.07.2017                                              --
-- Short Description : This is the receiver block of the UART                  --
--                     where the input signal received serially                --
--                     from the transmitter is read serially and               --
--                     then converted to parallel for use.                     --
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL; 

entity UART_Receiver is
    
  port( 
    clk_per_bit         : in STD_LOGIC_VECTOR(31 downto 0); --Number of clock edges for 1 bit to arrive
    parity_bit          : in STD_LOGIC_VECTOR(2  downto 0); --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
    stop_bits           : in STD_LOGIC_VECTOR(1  downto 0); --Stop bit case input. Cases(1,1.5,2) are indexed as (00,01,10)
    data_length         : in STD_LOGIC;                     --Number of bits being sent. Selections (7,8) are indexed as (0,1)
    clk                 : in STD_LOGIC;                     --Input clock usually 10MHz
    rst                 : in STD_LOGIC;                     --Active low reset
    rx_serial           : in STD_LOGIC;                     --Serial input
    option_change       : in STD_LOGIC;                     --Option change input to indicate one the the setup signals has changed thus the system should go on setup state
    rx_data_valid       : out STD_LOGIC;                    --Output signal to imply the reading is done
    rx_byte             : out STD_LOGIC_VECTOR(7 downto 0); --Read data in parallel
    parity_error        : out STD_LOGIC;                    --Parity error output signal
    option_change_done  : out STD_LOGIC);                   --Output signal to indicate the setup has been done and system can be turned back to the idle state
    
    
end UART_Receiver;
  
architecture RECEIVER of UART_Receiver is
    
    type UART_RECEIVER_STATE_TYPES is (SETUP,IDLE,START,DATA,STOP,PARITY,LED_SELECT,CLEANUP); --Receiver state types
    constant BIT_LENGTH     : STD_LOGIC_VECTOR(3  downto 0):= "0111";   --Index for different bit length options
    constant EVEN_PARITY    : STD_LOGIC_VECTOR(2  downto 0):=  "000";   --Indexes for different parity options
    constant ODD_PARITY     : STD_LOGIC_VECTOR(2  downto 0):=  "001";   
    constant NONE_PARITY    : STD_LOGIC_VECTOR(2  downto 0):=  "010";
    constant MARK_PARITY    : STD_LOGIC_VECTOR(2  downto 0):=  "011";
    constant SPACE_PARITY   : STD_LOGIC_VECTOR(2  downto 0):=  "100";
    constant STOP_BIT_1     : STD_LOGIC_VECTOR(1  downto 0):=   "00";   --Indexes for different stop bit options
    constant STOP_BIT_1_5   : STD_LOGIC_VECTOR(1  downto 0):=   "01";
    constant STOP_BIT_2     : STD_LOGIC_VECTOR(1  downto 0):=   "10";
    constant STOP_INDEX_1   : STD_LOGIC_VECTOR(2  downto 0):=  "010";   --Stop Index count times which correspond to number of half cycles that is needed to be counted for different stop bit selections
    constant STOP_INDEX_1_5 : STD_LOGIC_VECTOR(2  downto 0):=  "011";       
    constant STOP_INDEX_2   : STD_LOGIC_VECTOR(2  downto 0):=  "100";

    
    signal Receiver_Main        : UART_RECEIVER_STATE_TYPES; --State definition 
    signal rx_data_b1           : STD_LOGIC;    --Buffer1 data signal for recieved data to avoid metastablity issues
    signal rx_data_b2           : STD_LOGIC;    --Buffer2 data signal for recieved data to avoid metastablity issues
    signal rx_data              : STD_LOGIC;    --The signal where dummy data signal is sent to
    signal rx_data_valid_t      : STD_LOGIC;    --Temp signal for the signal that is sent when the reading is done
    signal parity_check         : STD_LOGIC;    --Temp signal for even and odd parity calculation
    signal parity_error_t       : STD_LOGIC;    --Parity error output signal 
    signal data_length_t        : STD_LOGIC;    --Number of bits being sent
    signal option_change_done_t : STD_LOGIC;    --Temp signal to indicate that the options applied has changed
    signal clk_count            : STD_LOGIC_VECTOR(31 downto 0);    --Counter for waiting until the middle of input signal
    signal rx_byte_t            : STD_LOGIC_VECTOR(7  downto 0);    --Temp signal for parallel data
    signal rx_byte_b            : STD_LOGIC_VECTOR(7  downto 0);    --Buffer signal for parallel data that sets the output when the signal is fully received
    signal bit_index            : STD_LOGIC_VECTOR(3  downto 0);    --Index to keep track of number of bits read
    signal stop_index           : STD_LOGIC_VECTOR(2  downto 0);    --Index to keep track of how long to count for the corresponding stop bit
    signal parity_bit_t         : STD_LOGIC_VECTOR(2  downto 0);    --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
    signal stop_bits_t          : STD_LOGIC_VECTOR(1  downto 0);    --Stopbit case input. Cases(1,1.5,2) are indexed as (00,01,10)
    signal clk_per_bit_t        : STD_LOGIC_VECTOR(31 downto 0);    --Number of clocks edges for 1 bit to arrive
 
    
begin

    Main: process(clk,rst)
    
    begin
    
        if rst = '0' then        --Asynchronous Active Low Reset
            clk_count            <= (others => '0');
            bit_index            <= (others => '0');
            rx_byte_b            <= (others => '0');
            stop_index           <= (others => '0');
            Receiver_Main        <= SETUP;
            parity_check         <= '0';
            parity_error_t       <= '0';
            option_change_done_t <= '0';
            rx_data_valid_t      <= '0';
            rx_data_b1           <= '1';
            rx_data_b2           <= '1';
            rx_data              <= '1';
            rx_byte_t            <= (others => '0');
            rx_byte_b            <= (others => '0');
            stop_bits_t          <= "00";
            parity_bit_t         <= "000";
            data_length_t        <= '0';
            clk_per_bit_t        <= conv_std_logic_vector(87,32);
            
            
        elsif rising_edge(clk) then     --Synchronous Process
            rx_data_b1    <= rx_serial;
            rx_data_b2    <= rx_data_b1;
            rx_data       <= rx_data_b2;
            case Receiver_Main is 
            
            when SETUP =>           --When Number of clocks per bit, data length, parity or stop bits change the 
                                    --system enters the setup state to assign the new values to the temp signals
                clk_per_bit_t        <= clk_per_bit;
                data_length_t        <= data_length;
                parity_bit_t         <= parity_bit;
                stop_bits_t          <= stop_bits;
                option_change_done_t <= '1';
                Receiver_Main        <= IDLE;
                
            when IDLE =>           --Stay in IDLE until start bit comes and return to IDLE when CLEANUP ends
                
                if option_change = '1' then
                    Receiver_Main  <= SETUP;
                elsif rx_data    = '0' then
                    Receiver_Main  <= START;
                else 
                    Receiver_Main  <= IDLE;
                end if;
            
            when START =>          --Count until the middle of the serial input and check the sample 
                if clk_count < ('0' & clk_per_bit_t(31 downto 1)) then
                    clk_count      <= clk_count + 1;
                    Receiver_Main  <= START;
                else 
                    if rx_data  = '0' then
                        clk_count            <= (others => '0');
                        Receiver_Main        <= DATA;
                        rx_data_valid_t      <= '0';
                        parity_error_t       <= '0';
                        option_change_done_t <= '0';
                        rx_byte_t            <= (others => '0');
                    else
                        Receiver_Main   <= IDLE;
                        clk_count       <= (others => '0');
                    end if;
                end if;
            
            when DATA =>             --Count clock cycles per bit and sample in the middle of bits. Write the data on temp data signal
                if (clk_count < (clk_per_bit_t - '1')) and (bit_index < (BIT_LENGTH + data_length_t)) then
                    clk_count         <= clk_count + 1;
                    Receiver_Main     <= DATA;
                elsif bit_index = (BIT_LENGTH + data_length_t) then
                    bit_index <= (others => '0');
                    Receiver_Main   <= PARITY;
                else 
                    clk_count         <= (others => '0');
                    rx_byte_t(conv_integer(bit_index))  <= rx_data;
                    bit_index       <= bit_index + 1;
                    Receiver_Main   <= DATA;
                end if;
          
            when PARITY =>            --Calculate and compare the parity bits. Calculation is only done for even and odd cases
                if clk_count < (clk_per_bit_t - '1') then
                    clk_count       <= clk_count + 1;
                    Receiver_Main   <= PARITY;
                    parity_check <= rx_byte_t(0) xor rx_byte_t(1) xor rx_byte_t(2) xor
                                    rx_byte_t(3) xor rx_byte_t(4) xor rx_byte_t(5) xor 
                                    rx_byte_t(6) xor rx_byte_t(7);          
                else
                    clk_count       <= (others => '0');
     
                    case parity_bit_t is
              
                    when EVEN_PARITY =>            --Check if the parity check bit is equal to the parity bit read on data chanel
                  
                        if parity_check = rx_data  then  
                            parity_error_t  <= '0';  
                            Receiver_Main   <= STOP;
                        else
                            parity_error_t  <= '1'; 
                            Receiver_Main   <= STOP;
                        end if;
              
                    when ODD_PARITY =>            --Check if the parity check bit is equal to the parity bit read on data chanel
                      
                        if (not parity_check) = rx_data  then
                            parity_error_t  <= '0';
                            Receiver_Main   <= STOP;
                        else
                            parity_error_t  <= '1'; 
                            Receiver_Main   <= STOP;
                        end if;
              
                    when NONE_PARITY =>            --Since there is no parity bit to check go for the Stop state. 
                                                   --Stop index is increased by 2 to componsate for the loss of time
                        
                        parity_error_t  <= '0';
                        Receiver_Main   <= STOP;
                        stop_index      <= stop_index + "10";
              
                    when MARK_PARITY =>            --Check if the parity check bit is equal to 1
                        if rx_data = '1' then
                            parity_error_t  <= '0';
                            Receiver_Main   <= STOP;
                        else
                            parity_error_t  <= '1'; 
                            Receiver_Main   <= STOP;
                        end if; 
                  
                    when SPACE_PARITY =>        --Check if the parity check bit is equal to 0
                   
                        if rx_data = '0' then
                            parity_error_t  <= '0';
                            Receiver_Main   <= STOP;
                        else
                            parity_error_t  <= '1';                            
                            Receiver_Main   <= STOP;
                        end if; 
                   
                    when others =>
                        parity_error_t  <= '1'; 
                        Receiver_Main   <= STOP;
                   
                    end case;
                end if;
          
            when STOP => --Wait until the middle of the last stop bit and then compare the results. 
                
                case stop_bits_t is
                  
                when STOP_BIT_1 =>                --Count 2 half clock cycles for 1 stop bit
               
                   if stop_index < STOP_INDEX_1  then
                        if clk_count < ('0' & clk_per_bit_t(31 downto 1)) then
                            clk_count       <= clk_count + 1;
                            Receiver_Main   <= STOP;
                        else  
                            clk_count       <= (others => '0');
                            stop_index <= stop_index + '1';
                        end if;
                    else 
                        Receiver_Main   <= CLEANUP;
                        if ((rx_data = '1') and (parity_error_t = '0')) then
                            rx_data_valid_t <= '1';
                        end if;
                        rx_byte_b           <= rx_byte_t;
                    end if;
                
                when STOP_BIT_1_5 =>            --Count 3 half clock cycles for 1.5 stop bits
                
                    if stop_index < STOP_INDEX_1_5  then
                        if clk_count < ('0' & clk_per_bit_t(31 downto 1)) then
                            clk_count       <= clk_count + 1;
                            Receiver_Main   <= STOP;
                        else  
                            clk_count       <= (others => '0');
                            stop_index <= stop_index + '1';
                        end if;
                    else 
                        Receiver_Main   <= CLEANUP;
                        if ((rx_data = '1') and (parity_error_t = '0')) then
                            rx_data_valid_t <= '1';
                        end if;
                        rx_byte_b           <= rx_byte_t;
                    end if;
                    
                when STOP_BIT_2 =>            --Count 4 half clock cycles for 2 stop bits
                
                    if stop_index < STOP_INDEX_2  then
                        if clk_count < ('0' & clk_per_bit_t(31 downto 1)) then
                            clk_count       <= clk_count + 1;
                            Receiver_Main   <= STOP;
                        else  
                            clk_count       <= (others => '0');
                            stop_index <= stop_index + '1';
                        end if;
                    else 
                        Receiver_Main   <= CLEANUP;
                        if ((rx_data = '1') and (parity_error_t = '0')) then
                            rx_data_valid_t <= '1';
                        end if;
                        rx_byte_b           <= rx_byte_t;
                    end if;
                
                when others =>
                
                Receiver_Main   <= CLEANUP;
                
                end case;
                
                    
            when CLEANUP =>  --Set signals to their initial values and return back to IDLE
                
                Receiver_Main       <= IDLE;
                parity_check        <= '0';
                stop_index          <= (others => '0');
                clk_count           <= (others => '0');
                bit_index           <= (others => '0');
                rx_data_valid_t     <= '0';
            
            when others =>   --If due to an error any other state is reached go back to IDLE
                Receiver_Main       <= IDLE;
                rx_data_valid_t     <= '0';
            
            end case;
          
        end if;
    
    end process Main; --When the start bit comes the process waits until the middle of the bit to verify  
                        --the start bit and then it waits one bit length to take samples of the serial input.
                        --After that these inputs are stored in the parallel data register and  after
                        --the parity bit comes the parities are compared. If there is an error
                        --the output is still given but the error signal also becomes high thus, 
                        --alerting the receiver.Finally the after the stop bit the process goes 
                        --back to idle state to wait for another start bit.

    rx_byte            <= rx_byte_b;            --Buffer value is assigned combinationally but the temp value
                                                --is set to buffer only when all of the signal is received.
    rx_data_valid      <= rx_data_valid_t;              --The output for telling user if the data recieved is valid
    parity_error       <= parity_error_t;       --If there is an error with the parity the user is notified by this signal
    option_change_done <= option_change_done_t; --When the user wants to change the communication options this 
                                                --alerts the user that the changes they made are done
    
end RECEIVER;        