----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- https://github.com/jguyonfrance
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

----------------------------------------------------------------------------------
--                        _______ ADC______
--                       |                 |
--                   ->  | i_clk           |
--                   ->  | i_rst_n         |
--                       |                 |
--     FPGA_BOARD    <-  | o_done          |               AD4857
--                   <-  | o_data0         |
--                       |                 |
--                       |     i_adc_sdo_0 |<-
--                       |      o_adc_sclk |->
--                       |      o_adc_cnv  |->
--                       |_________________|
--
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.NUMERIC_STD.ALL;
   
library xil_defaultlib;
   use xil_defaultlib.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity ADC7980_data is
  generic
   (     
   g_IMPL_ILA_ADC7980  : boolean
   );
  port ( 
         i_clk         : in  std_logic;                      -- clokck system at 125MHz
         i_rst_n       : in  std_logic;                      -- reset system
         i_pulse_acq   : in  std_logic;                                    
         i_sdo         : in  std_logic;                   
         o_sck         : out std_logic;                      
         o_conv        : out std_logic;                      
         o_done        : out std_logic;                      
         o_adc_data  : out std_logic_vector(15 downto 0));

end ADC7980_data;

architecture behavioral of ADC7980_data is


   component ila_adc7980 is
   port
   (
      clk       : in  std_logic;
      probe0    : in  std_logic_vector(0 downto 0);
      probe1    : in  std_logic_vector(0 downto 0);
      probe2    : in  std_logic_vector(0 downto 0);
      probe3    : in  std_logic_vector(0 downto 0);
      probe4    : in  std_logic_vector(0 downto 0);
      probe5   : in  std_logic_vector(15 downto 0);
      probe6   : in  std_logic_vector(1 downto 0)
   );
   end component;

   constant C_TEN_TIME  : integer range 0 to  200 :=  12;  -- time between conv sck (nb of sck)
   constant C_SCLK_TIME  : integer range 0 to  200 :=  10;  -- time between conv sck (nb of sck)
   constant C_CONV_TIME : integer range 0 to 200 := 95;  -- time duration for conv signal
   constant C_NB_DATA   : integer range 0 to  32 := 16;  -- nb bit to get from SPI

   type spi_fsm is(IDLE_ST,       -- default state to wait next acq
                   WAIT_CONV_ST,  -- state to wait end of conv time
                   SCK_ST,        -- sck clock rising edge
                   WAIT_DATA_ST); -- wait data from spi

   signal s_spi_state      : spi_fsm;
   signal s_spi_state_ila  : std_logic_vector(1 downto 0);
   signal s_pulse_sck      : std_logic;                     -- pulse to manage spi clock
   signal s_count_data     : integer range 0 to 32;         -- counter for nb of bit get from spi
   signal s_spi_data       : std_logic_vector(15 downto 0); -- spi data register
   signal s_count_conv     : integer range 0 to 200;        -- counter for conv timing
   signal s_sclk           : std_logic;
   signal s_conv           : std_logic;
   signal s_done           : std_logic;
   signal s_adc_data       : std_logic_vector(15 downto 0);


begin

impl_ila_ADC7980 : if g_IMPL_ILA_ADC7980 generate

  process (i_clk)
   begin
      if rising_edge(i_clk) then
         case s_spi_state is
            when IDLE_ST            => s_spi_state_ila    <= "00";
            when WAIT_CONV_ST       => s_spi_state_ila    <= "01";
            when SCK_ST             => s_spi_state_ila    <= "10";
            when others             => s_spi_state_ila    <= "11";
         end case;
     end if;
   end process;

   iILA_ADC  : ila_adc7980
   port map
   (
      clk         => i_clk             ,
      probe0(0)   => i_sdo             ,
      probe1(0)   => i_pulse_acq       ,
      probe2(0)   => s_sclk            ,
      probe3(0)   => s_conv            ,
      probe4(0)   => s_done            ,
      probe5      => s_adc_data        ,
      probe6      => s_spi_state_ila    
   );
end generate impl_ila_ADC7980;

   -- process to manage spi data
   -- This process is used to respect ADC timing (t_conv, ten)
   -- This process is used to get data from spi bus
   -- Refer to AD7980 datasheet for more details
   p_spi : process(i_clk, i_rst_n)
   begin
      if(i_rst_n = '0') then
         s_spi_state  <= IDLE_ST;
         s_conv       <= '0';
         s_sclk       <= '0';
         s_done       <= '0';
         s_count_data <= 0;
         s_count_conv <= 0;
         s_spi_data   <= (others => '0');

      elsif(rising_edge(i_clk)) then
         case s_spi_state is
            when IDLE_ST =>                        -- state to wait new acq enable
               s_done <= '0';                      -- reset to set only for one clk
               s_conv <= '0';                      -- by default conv is set to '0'
               s_spi_data <= (others => '0');
               if(i_pulse_acq = '1') then          -- when new acq is enable
                  s_spi_state  <= WAIT_CONV_ST;    -- next state is to wait conv timing
                  s_conv       <= '1';             -- set conv to start conversion of ADC
               end if;

            when WAIT_CONV_ST =>                                         -- state to wait conv and tentiming

               if(s_count_conv = C_CONV_TIME) then                       -- when conv timing is over
                     s_conv      <= '0';
               end if;
               if(s_count_conv = (C_CONV_TIME+C_TEN_TIME)) then          -- when conv timing is over
                     s_spi_state  <= SCK_ST;                             -- next state is to manage clock spi
                     s_spi_data <= (others => '0');
                     s_count_conv <= 0;                                  -- reset counter for next new acq
               else                                                      -- when conv timing is not over
                  s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
               end if;

            when SCK_ST =>                                              -- state to manage rising edge of sck
                if(s_count_conv = (C_SCLK_TIME)) then          -- when conv timing is over
                    s_spi_state  <= WAIT_DATA_ST;   
                    s_count_conv <= 0; 
                else                                                      -- when conv timing is not over
                    s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
                end if;        
                                            
                  s_sclk      <= '1';                                   -- set spi clock to '1'
                  s_pulse_sck <= '0';

            when WAIT_DATA_ST =>
                if(s_count_conv = (C_SCLK_TIME)) then          -- when conv timing is over
                  if(s_count_data = (C_NB_DATA)) then                  -- when all bits have been read
                     s_count_data <= 0;                                -- reset counter to managed new acq
                     s_adc_data <= s_spi_data;
                     s_done       <= '1';
                     s_spi_state  <= IDLE_ST;                          -- next state is to wait new acq
                  else                                                 -- when no all bits is read
                     s_done       <= '0';
                     s_count_data <= s_count_data + 1;                 -- one more bits is read
                     s_spi_state  <= SCK_ST;                           -- next state is to read another value
                     s_spi_data   <= s_spi_data(14 downto 0) & i_sdo;      -- get one bit from spi bus
                  end if;
                  s_count_conv <= 0; 
                else                                                      -- when conv timing is not over
                    s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
                end if;  
                
                s_sclk <= '0';   -- set spi clock to '0'
               
            when others =>
               s_spi_state <= IDLE_ST;
         end case;
      end if;

   end process;

   -- Affectation des sorties
   o_sck      <= s_sclk;
   o_conv      <= s_conv;
   o_done      <= s_done;
   o_adc_data  <= s_adc_data;
   
   
end Behavioral;
