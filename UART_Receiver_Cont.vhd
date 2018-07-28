---------------------------------------------------------------------------------
-- Project Name      : UART_RECEIVER	                                       --
-- System/Block Name : Receiver Controller                                     --
-- Design Engineer   : Tuna Bicim                                              --
-- Date              : 26.07.2017                                              --
-- Short Description : This is the receiver controller block of the UART       --
--                     where the LEDs are turned on or off depending on the    --
--					   input signal from the transmitter					   --
---------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL; 

entity UART_Receiver_Cont is
    
  port( 
    clk                 : in STD_LOGIC;                     --Input clock usually 10MHz
    rst                 : in STD_LOGIC;                     --Active low reset
    rx_byte             : in STD_LOGIC_VECTOR(7 downto 0); --Read data in parallel
    data_valid          : in STD_LOGIC;
    led_r               : out STD_LOGIC;                    --Output signal to light red led up
    led_g1              : out STD_LOGIC;                    --Output signal to light green 1 led up
    led_g2              : out STD_LOGIC;                    --Output signal to light green 2 led up
    led_g3              : out STD_LOGIC;
	led_buffer_r        : out STD_LOGIC;                    --Output signal to light red led up
    led_buffer_g1       : out STD_LOGIC;                    --Output signal to light green 1 led up
    led_buffer_g2       : out STD_LOGIC;                    --Output signal to light green 2 led up
    led_buffer_g3       : out STD_LOGIC);                   --Output signal to light green 3 led up
    
end UART_Receiver_Cont;

architecture CONTROLLER of UART_RECEIVER_CONT is
    type UART_RECEIVER_CONTROLLER_STATE_TYPES is (IDLE,DECIDE); --Controller state types
    constant RED            : STD_LOGIC_VECTOR(7 downto  0):= "01010010";      --The data input needed to turn the leds on
    constant GREEN1         : STD_LOGIC_VECTOR(7 downto  0):= "01000111";
    constant GREEN2         : STD_LOGIC_VECTOR(7 downto  0):= "01001000";
    constant GREEN3         : STD_LOGIC_VECTOR(7 downto  0):= "01001010";

    signal Controller_Main  : UART_RECEIVER_CONTROLLER_STATE_TYPES;
    signal rx_byte_t        : STD_LOGIC_VECTOR(7 downto  0);
    signal led_r_t          : STD_LOGIC;                    --Temp Signal for the red led
    signal led_g1_t         : STD_LOGIC;                    --Temp Signal for the first green led
    signal led_g2_t         : STD_LOGIC;                    --Temp Signal for the second green led
    signal led_g3_t         : STD_LOGIC;                    --Temp Signal for the third green led
    signal data_valid_t     : STD_LOGIC; 
    
	
begin
    LED_SELECT: process(clk,rst)
    begin
        if rst = '0' then -- Asynchronous reset
            led_r_t              <= '0';
            led_g1_t             <= '0';
            led_g2_t             <= '0';
            led_g3_t             <= '0';
            rx_byte_t            <= (others => '0');
            Controller_Main      <= IDLE;
            data_valid_t         <= '0';
			
        elsif rising_edge(clk) then -- Synchronous process
            rx_byte_t <= rx_byte;
            data_valid_t <= data_valid ;
            case Controller_Main is 
            
            when IDLE =>
            
                if data_valid_t = '1' then
                Controller_Main <= DECIDE;
                else 
                Controller_Main <= IDLE;
                end if;
                
            when DECIDE => -- Decide which LED to invert
            
                case rx_byte_t is
            
                when RED =>
                
                    led_r_t         <= not led_r_t ;
                    Controller_Main <= IDLE;
                
                when GREEN1 =>
                    
                    led_g1_t         <= not led_g1_t;
                    Controller_Main <= IDLE;
                
                when GREEN2 =>
                
                    led_g2_t         <= not led_g2_t ;
                    Controller_Main <= IDLE;
                
                when GREEN3 =>
                    
                    led_g3_t         <= not led_g3_t ;
                    Controller_Main <= IDLE;
                
                when others =>
            
                    Controller_Main <= IDLE;
                end case;
            
            when others =>
                Controller_Main <= IDLE;
            
            end case;
        end if;
    end process;
    led_buffer_r       <= led_r_t;   
    led_buffer_g1      <= led_g1_t;   
    led_buffer_g2      <= led_g2_t;
    led_buffer_g3      <= led_g3_t;
    led_r              <= led_r_t;
    led_g1             <= led_g1_t;
    led_g2             <= led_g2_t;
    led_g3             <= led_g3_t;
    
end CONTROLLER;

            
            
            
            