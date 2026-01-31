----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- 
-- Create Date: 03.01.2025 14:00:00
-- Design Name: 
-- Module Name:
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.std_logic_unsigned.all;
   use IEEE.std_logic_arith.all;

library xil_defaultlib;
   use xil_defaultlib.all;


entity AD4857_config is
  generic
   (     
   g_IMPL_ILA_ADCSPI  : boolean
   );
  port ( 
        i_clk                 : in  std_logic;                      -- clokck system at 125MHz
        i_rst_n               : in  std_logic;                      -- reset system
        i_write_config_start  : in  std_logic;  
        o_config_busy         : out  std_logic;                                    
        o_config_ready        : out  std_logic;        
        
        o_adc_CSCK   : out std_logic;  
        io_adc_CSDIO : out std_logic;  
        i_adc_CSDO   : in std_logic;  
        o_adc_CS     : out std_logic
        
       );
end AD4857_config;

architecture Behavioral of AD4857_config is


  TYPE spi_config_state IS(ready_write_config, wait_busy, write_config, wait_interval_config, sucess_config ); --needed states
  SIGNAL s_spi_config_state              : spi_config_state := ready_write_config;                       --state machine
  SIGNAL s_spi_busy           : STD_LOGIC;                              --busy signal from SPI component
  SIGNAL s_spi_ena            : STD_LOGIC;                              --enable for SPI component
  SIGNAL s_spi_tx_data        : STD_LOGIC_VECTOR(23 DOWNTO 0);           --transmit data for SPI component
  SIGNAL s_spi_rx_data        : STD_LOGIC_VECTOR(23 DOWNTO 0);           --received data from SPI component
  SIGNAL s_write_config_start_n            : STD_LOGIC;                        
  SIGNAL s_write_config_start            : STD_LOGIC;                             

    
  --declare SPI Master component
  COMPONENT spi_master IS
     GENERIC(
        slaves  : INTEGER := 1;  --number of spi slaves
        d_width : INTEGER := 24); --data bus width
     PORT(
        clock   : IN     STD_LOGIC;                             --system clock
        reset_n : IN     STD_LOGIC;                             --asynchronous reset
        enable  : IN     STD_LOGIC;                             --initiate transaction
        cpol    : IN     STD_LOGIC;                             --spi clock polarity
        cpha    : IN     STD_LOGIC;                             --spi clock phase
        cont    : IN     STD_LOGIC;                             --continuous mode command
        clk_div : IN     INTEGER;                               --system clock cycles per 1/2 period of sclk
        addr    : IN     INTEGER;                               --address of slave
        tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
        miso    : IN     STD_LOGIC;                             --master in, slave out
        sclk    : OUT    STD_LOGIC;                             --spi clock
        ss_n    : OUT    STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
        mosi    : OUT    STD_LOGIC;                             --master out, slave in
        busy    : OUT    STD_LOGIC;                             --busy / data ready signal
        rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)); --data received
  END COMPONENT spi_master;
  
-- Sin function array
    type spi_data_config_array is array (0 to 35) of std_logic_vector(7 downto 0);
    constant spi_config_register : spi_data_config_array := (
	 X"00", X"00", X"30",
	 X"00", X"01", X"80",
	 X"00", X"25", X"01",--444
	 X"00", X"14", X"00",
	 X"00", X"2A", X"01", -- CH0 -/+2.5V range L3
	 X"00", X"3C", X"01", -- CH1 -/+2.5V range L2
	 X"00", X"4E", X"01", -- CH2 -/+2.5V range L1
	 X"00", X"60", X"0B", -- CH3 -/+20V range IL3
	 X"00", X"72", X"0B", -- CH4 -/+20V range IL1
	 X"00", X"84", X"0B", -- CH5 -/+20V range IL2
	 X"00", X"96", X"01", -- CH6 -/+2.5V range NP
	 X"00", X"A8", X"01"  -- CH7 -/+2.5V range PP
	 );
	 
	constant spi_config_register_len : integer := 33;
    signal index_config_reg 	: integer range 0 to 100 := 0;
    signal wait_interval_cpt 	: integer range 0 to 65530 := 0;
    signal wait_latence_cpt 	: integer range 0 to 100 := 0;
	constant wait_interval_max : integer := 2500;
	constant wait_latence_busy_spi : integer := 3;
	
begin

  --instantiate the SPI Master component
  spi_master_0:  spi_master
    GENERIC MAP(
        slaves => 1, 
        d_width => 24
        )
    PORT MAP(
        clock => i_clk, 
        reset_n => i_rst_n, 
        enable => s_spi_ena, 
        cpol => '1', cpha => '1',
        cont => '0', 
        clk_div => 250,  --SPI 1mhz 
        addr => 0, 
        tx_data => s_spi_tx_data, 
        miso => i_adc_CSDO,
        sclk => o_adc_CSCK, 
        ss_n(0) => o_adc_CS, 
        mosi => io_adc_CSDIO, 
        busy => s_spi_busy, 
        rx_data => s_spi_rx_data
    ); 

   p_spi_config_fsm : process(i_clk, i_rst_n)
   begin
      if(i_rst_n = '0') then
        index_config_reg <= 0;
        o_config_ready <= '0';
        o_config_busy <= '0';
        s_write_config_start_n <= '0';
        s_write_config_start <= '0';
      elsif rising_edge(i_clk) then
         s_write_config_start <= i_write_config_start;   
         s_write_config_start_n <= s_write_config_start;  
         
         case s_spi_config_state is
            when ready_write_config =>      
                s_spi_ena  <= '0';      
				if ((s_write_config_start_n = '0') and (s_write_config_start = '1')) then
					s_spi_config_state <= wait_busy;
                    o_config_busy <= '1';
                    o_config_ready <= '0';
                else
                    o_config_busy <= '0';
                    o_config_ready <= '0';
				end if; 
                index_config_reg <= 0;
            when wait_busy =>        
                o_config_ready <= '0';
                o_config_busy <= '1';
                s_spi_ena  <= '0';   
				if (s_spi_busy = '0') then
					s_spi_config_state <= write_config;
				end if;
            when write_config =>

                s_spi_tx_data(7 downto 0)   <= spi_config_register(index_config_reg + 2)(7 downto 0);
                s_spi_tx_data(15 downto 8)  <= spi_config_register(index_config_reg + 1)(7 downto 0);
                s_spi_tx_data(23 downto 16) <= spi_config_register(index_config_reg + 0)(7 downto 0);
                s_spi_ena  <= '1';                    
                if(index_config_reg < spi_config_register_len) then
                    index_config_reg <= index_config_reg + 3;
                    s_spi_config_state <= wait_interval_config;
                    wait_interval_cpt <= 0;        
                    wait_latence_cpt <= 0; 
                    o_config_ready <= '0';
                    o_config_busy <= '1';
                else                     
                    index_config_reg <= 0;
                    s_spi_config_state <= sucess_config;
                    o_config_busy <= '0';
                    o_config_ready <= '1';  
                end if;
            when wait_interval_config =>  
                o_config_ready <= '0';
                o_config_busy <= '1';
                s_spi_ena  <= '0';
                if(wait_latence_cpt < wait_latence_busy_spi) then
                    wait_latence_cpt <= wait_latence_cpt + 1;
                else      
                    if(wait_interval_cpt < wait_interval_max) then
                        if (s_spi_busy = '0') then
				            wait_interval_cpt <= wait_interval_cpt + 1;
				        end if;
                    else      
                        wait_interval_cpt <= 0;        
                        wait_latence_cpt <= 0;     
                        s_spi_config_state <= wait_busy;
                    end if;
                 end if;
            when sucess_config =>  
                s_spi_ena  <= '0';                         
				if ((s_write_config_start_n = '0') and (s_write_config_start = '1')) then
					s_spi_config_state <= wait_busy;
                    o_config_busy <= '1';
                    o_config_ready <= '0';
                else
                    o_config_busy <= '0';
                    o_config_ready <= '1';
				end if;             
				when others =>
                    o_config_busy <= '0';
                    o_config_ready <= '0';
         end case;
      end if;
   end process p_spi_config_fsm;


end Behavioral;
