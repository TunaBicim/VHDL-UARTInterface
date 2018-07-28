LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.std_logic_arith.ALL; 

entity Top is
    
  port( 
    clk_per_bit         : in STD_LOGIC_VECTOR(31 downto 0); --Number of clocks edges for 1 bit to arrive
    parity_bit          : in STD_LOGIC_VECTOR(2  downto 0); --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
    stop_bits           : in STD_LOGIC_VECTOR(1  downto 0); --Stopbit case input. Cases(1,1.5,2) are indexed as (00,01,10)
    data_length         : in STD_LOGIC;                     --Number of bits being sent. Selections (7,8) are indexed as (0,1)
    clk                 : in STD_LOGIC;                     --Input clock usually 10MHz
    option_change       : in STD_LOGIC;                     --Option change input to indicate one the the setup signals has changed thus the system should go on setup state
    serial_in           : in STD_LOGIC;
    --parity_error        : out STD_LOGIC;                    --Parity error output signal
    --option_done_tx      : out STD_LOGIC;
    --option_done_rx      : out STD_LOGIC;                   --Output signal to indicate the setup has been done and system can be turned back to the idle state
    tx_serial           : out STD_LOGIC;
    --tx_active           : out STD_LOGIC;
    led_r               : out STD_LOGIC;                    --Output signal to light red led up
    led_g1              : out STD_LOGIC;                    --Output signal to light green 1 led up
    led_g2              : out STD_LOGIC;                    --Output signal to light green 2 led up
    --led_g3              : out STD_LOGIC;
    led_active          : out STD_LOGIC;
	fast				: out STD_LOGIC;
	shd					: out STD_LOGIC
 );
end Top;

architecture Top_level of Top is
	component uart_pll is
		port(
			CLK0 : in  std_logic;
			GL0  : out std_logic;
			LOCK : out std_logic
			);
	end component uart_pll;
	
	component sync_reset_block is
		port( clk               : in std_logic;           --clock input which the reset signal is synchronous with       
			  rst_pll_locked_n  : in std_logic;           --pll locked input for the clock signal
		      rstn_apev_out     : out std_logic           --synchronous reset signal used in FPGA-2 
			);
	end component sync_reset_block;
	
    component Led_Idc is
        port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            led : out STD_LOGIC
        );
    end component Led_Idc;
	
	component UART_Receiver  
        port( 
            clk_per_bit         : in STD_LOGIC_VECTOR(31 downto 0); --Number of clocks edges for 1 bit to arrive
            parity_bit          : in STD_LOGIC_VECTOR(2  downto 0); --Parity case input. Cases(EVEN,ODD,NONE,MARK,SPACE) are indexed as (000,001,010,011,100)
            stop_bits           : in STD_LOGIC_VECTOR(1  downto 0); --Stopbit case input. Cases(1,1.5,2) are indexed as (00,01,10)
            data_length         : in STD_LOGIC;                     --Number of bits being sent. Selections (7,8) are indexed as (0,1)
            clk                 : in STD_LOGIC;                     --Input clock usually 10MHz
            rst                 : in STD_LOGIC;                     --Active low reset
            rx_serial           : in STD_LOGIC;                     --Serial input
            option_change       : in STD_LOGIC;                     --Option change input to indicate one the the setup signals has changed thus the system should go on setup state
            rx_data_valid       : out STD_LOGIC;                    --Output signal to imply the reading is done
            rx_byte             : out STD_LOGIC_VECTOR(7 downto 0); --Read data in parallel
            parity_error        : out STD_LOGIC;                    --Parity error output signal
            option_change_done  : out STD_LOGIC);                   --Output signal to indicate the setup has been done and system can be turned back to the idle state
        
    end component UART_Receiver;
    
    component UART_Receiver_Cont is
    
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
        
    end component UART_Receiver_Cont;
    
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

    
    component UART_TX
        
        port(														    -- Define port
            clk             : in STD_LOGIC;								-- Define clock input port
            rst             : in STD_LOGIC;								-- Define reset input port
            data_length     : in STD_LOGIC;  								 
            parity          : in STD_LOGIC_VECTOR(2 downto 0);   								 
            stop_bit_length : in STD_LOGIC_VECTOR(1 downto 0);    									
            baud_rate       : in STD_LOGIC_VECTOR(31 downto 0);
            option_change   : in STD_LOGIC;
            option_done 	: out STD_LOGIC;
            tx_dv           : in STD_LOGIC;								-- Define tx_dv input port for the data come or not
            tx_byte         : in STD_LOGIC_VECTOR(7 downto 0);       	-- Define input 8 byte data port  
            tx_serial       : out STD_LOGIC;
			tx_active       : out STD_LOGIC;
			tx_done         : out STD_LOGIC	);
    
    end component UART_TX;
    
	signal clk_g      : STD_LOGIC;
	signal lock		  : STD_LOGIC;
	signal rst  	  : STD_LOGIC;
	
    signal rx_byte    : STD_LOGIC_VECTOR(7 downto 0);
    signal data_valid : STD_LOGIC;
    
    signal tx_byte    : STD_LOGIC_VECTOR(7 downto 0);
    signal tx_dv      : STD_LOGIC;
    
    signal tx_done_t    : STD_LOGIC;
    
	signal led_r_t   : STD_LOGIC;
    signal led_g1_t  : STD_LOGIC;
    signal led_g2_t  : STD_LOGIC;
    signal led_g3_t  : STD_LOGIC;
    
    signal red_buffer_to_cont      : STD_LOGIC;
	signal green1_buffer_to_cont   : STD_LOGIC;
	signal green2_buffer_to_cont   : STD_LOGIC;
	signal green3_buffer_to_cont   : STD_LOGIC;

 begin
    fast <= '0';
	shd  <= '1';
	
	Clock	   : uart_pll port map( CLK0 => clk,
									GL0  => clk_g, 
									LOCK => lock);
	
	Reset      : sync_reset_block  port map( clk               => clk,
											 rst_pll_locked_n  => lock, 
										     rstn_apev_out 	=> rst);
				
    Led        :  Led_Idc port map(clk => clk,
                                   rst => lock,
                                   led => led_active); 
					  
    Receiver   : UART_Receiver port map(clk_per_bit     => X"000001B2",
                                        parity_bit      => "010",
                                        stop_bits       => "00",
                                        data_length     => '1',
                                        clk             => clk_g,
                                        rst             => rst,
                                        rx_serial       => serial_in ,
                                        option_change   => '0',
                                        rx_data_valid   => data_valid,
                                        rx_byte         => rx_byte,
                                        parity_error    => OPEN,
                                        option_change_done  => OPEN);
    
    Receiver_Controller : UART_Receiver_Cont port map(clk               => clk_g,
                                                      rst               => rst,
                                                      rx_byte   	    => rx_byte,
                                                      data_valid        => data_valid,
                                                      led_buffer_r      => led_r_t,
                                                      led_buffer_g1     => led_g1_t,
                                                      led_buffer_g2     => led_g2_t,
                                                      led_buffer_g3     => led_g3_t,
													  led_r     => led_r,
													  led_g1    => led_g1,
													  led_g2    => led_g2,
													  led_g3    => OPEN);
    
	Transmitter_Buffer: UART_TX_BUFFER port map(clk       => clk_g, 
												rst 	  => rst, 
												
												led_r     => led_r_t,
                                                led_g1    => led_g1_t,
                                                led_g2    => led_g1_t,
                                                led_g3    => led_g3_t,
												
												led_r_o   => red_buffer_to_cont,
												led_g1_o  => green1_buffer_to_cont,
												led_g2_o  => green2_buffer_to_cont ,
												led_g3_o  => green3_buffer_to_cont  
												);	
  
  
     Transmitter_Cont: UART_TX_CONT port map( clk      => clk_g,
											  rst 	   => rst,
											  tx_done  => tx_done_t,

											  led_r    => red_buffer_to_cont,
                                              led_g1   => green1_buffer_to_cont,
                                              led_g2   => green2_buffer_to_cont ,
                                              led_g3   => green3_buffer_to_cont,
												
											  tx_dv    => tx_dv,
											  tx_byte  => tx_byte);
	  
       
    Transmitter: UART_TX port map(clk                => clk_g,
								  rst 	             => rst,
								  data_length        => '1',                   --data_length,
								  parity	         => "010",                 -- parity_bit ,  								 
								  stop_bit_length 	 => "00",                  --stop_bits ,    									
								  baud_rate	         => X"000001B2",           --clk_per_bit ,
								  option_change	     => '0',                   --option_change,
								  option_done        => OPEN,                   --option_done_tx,	
								  tx_dv	             => tx_dv,      
								  tx_byte		     => tx_byte,        
	   							  tx_active 	     => OPEN,      
								  tx_serial		     => tx_serial,      
								  tx_done		     => tx_done_t);
    
end Top_Level;