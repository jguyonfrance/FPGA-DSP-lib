----------------------------------------------------------------------------------
-- Company:
-- Engineer: J.Guyon
--
-- Create Date: 
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
--                        _______ ADC______
--                       |                 |
--                   ->  | i_clk           |
--                   ->  | i_rst_n         |
--                       |                 |
--     FPGA_BOARD    <-  | o_done          |               AD4857
--                   <-  | o_data0         |
--                   <-  | o_data1         |
--                   <-  | o_data2         |
--                   <-  | o_data3         |
--                   <-  | o_data4         |
--                   <-  | o_data5         |
--                   <-  | o_data6         |
--                   <-  | o_data7         |
--                       |                 |
--                       |     i_adc_sdo_0 |<-
--                       |     i_adc_sdo_1 |<-  
--                       |     i_adc_sdo_2 |<- 
--                       |     i_adc_sdo_3 |<- 
--                       |     i_adc_sdo_4 |<- 
--                       |     i_adc_sdo_5 |<-
--                       |     i_adc_sdo_6 |<- 
--                       |     i_adc_sdo_7 |<-  
--                       |      o_adc_sclk |->
--                       |      o_adc_cnv  |->
--                       |_________________|
--
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.std_logic_unsigned.all;
   use IEEE.std_logic_arith.all;

-- library xil_defaultlib;
   -- use xil_defaultlib.all;

-- Library UNisIM;
-- use UNisIM.vcomponents.all;
-- library UNIMACRO;
-- use unimacro.Vcomponents.all;


entity AD4857_data is
  generic
   (     
   g_IMPL_ILA_ADC  : boolean
   );
  port ( 
         i_clk         : in  std_logic;                      -- clokck system at 125MHz
         i_rst_n       : in  std_logic;                      -- reset system
         i_pulse_acq   : in  std_logic;                                    
         i_sdo_0       : in  std_logic;              
         i_sdo_1       : in  std_logic;                   
         i_sdo_2       : in  std_logic;              
         i_sdo_3       : in  std_logic;                 
         i_sdo_4       : in  std_logic;                    
         i_sdo_5       : in  std_logic;                   
         i_sdo_6       : in  std_logic;              
         i_sdo_7       : in  std_logic;               
         o_sck         : out std_logic;   
         o_cs          : out std_logic;                                        
         o_conv        : out std_logic;                      
         o_done        : out std_logic;                      
         o_adc_data_0  : out std_logic_vector(15 downto 0);
         o_adc_data_1  : out std_logic_vector(15 downto 0);
         o_adc_data_2  : out std_logic_vector(15 downto 0);
         o_adc_data_3  : out std_logic_vector(15 downto 0);
         o_adc_data_4  : out std_logic_vector(15 downto 0);
         o_adc_data_5  : out std_logic_vector(15 downto 0);
         o_adc_data_6  : out std_logic_vector(15 downto 0);
         o_adc_data_7  : out std_logic_vector(15 downto 0));

end AD4857_data;

architecture behavioral of AD4857_data is

   component ila_adc is
   port
   (
      clk       : in  std_logic;
      probe0    : in  std_logic_vector(0 downto 0);
      probe1    : in  std_logic_vector(0 downto 0);
      probe2    : in  std_logic_vector(0 downto 0);
      probe3    : in  std_logic_vector(0 downto 0);
      probe4    : in  std_logic_vector(0 downto 0);
      probe5    : in  std_logic_vector(0 downto 0);
      probe6    : in  std_logic_vector(0 downto 0);
      probe7    : in  std_logic_vector(0 downto 0);
      probe8    : in  std_logic_vector(0 downto 0);
      probe9    : in  std_logic_vector(0 downto 0);
      probe10   : in  std_logic_vector(0 downto 0);
      probe11   : in  std_logic_vector(0 downto 0);
      probe12   : in  std_logic_vector(15 downto 0);
      probe13   : in  std_logic_vector(15 downto 0);
      probe14   : in  std_logic_vector(15 downto 0);
      probe15   : in  std_logic_vector(15 downto 0);
      probe16   : in  std_logic_vector(15 downto 0);
      probe17   : in  std_logic_vector(15 downto 0);
      probe18   : in  std_logic_vector(15 downto 0);
      probe19   : in  std_logic_vector(15 downto 0);
      probe20   : in  std_logic_vector(1 downto 0)
   );
   end component;

   constant C_TEN_TIME  : integer range 0 to 100     := 40;    -- time between conv sck (nb of sck)
   constant C_TCSSSCKI  : integer range 0 to 100       := 20;    -- time between conv sck (nb of sck)

   constant C_CONV_TIME : integer range 0 to 1000    := 200;  -- time duration for conv signal
   constant C_SCLK_HALFTIME : integer range 0 to 1000    := 8;  -- time duration for conv signal

   constant C_NB_DATA   : integer range 0 to 32     := 16;   -- nb bit to get from SPI

   type spi_fsm is(IDLE_ST,       -- default state to wait next acq
                   WAIT_CONV_ST,  -- state to wait end of conv time
                   SCK_ST,        -- sck clock rising edge
                   WAIT_DATA_ST); -- wait data from spi

   signal s_spi_state       : spi_fsm;
   signal s_spi_state_ila   : std_logic_vector(1 downto 0); 
   signal s_pulse_sck       : std_logic;                     -- pulse to manage spi clock
   signal s_latch_miso      : std_logic;                     -- register to detect edge of pulse_sck
   signal s_count_sck       : integer range 0 to 100;         -- counter for freq clock spi
   signal s_count_data      : integer range 0 to 32;         -- counter for nb of bit get from spi
   signal s_spi_data_0        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_1        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_2        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_3        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_4        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_5        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_6        : std_logic_vector(15 downto 0); -- spi data register
   signal s_spi_data_7        : std_logic_vector(15 downto 0); -- spi data register


   signal s_count_conv      : integer range 0 to 1000;        -- counter for conv timing
   
   signal s_sclk            : std_logic; 
   signal s_cs            : std_logic; 
   signal s_conv            : std_logic; 
   signal s_done            : std_logic; 
   
   signal s_adc_data_0        : std_logic_vector(15 downto 0); 
   signal s_adc_data_1        : std_logic_vector(15 downto 0);
   signal s_adc_data_2        : std_logic_vector(15 downto 0);
   signal s_adc_data_3        : std_logic_vector(15 downto 0);
   signal s_adc_data_4        : std_logic_vector(15 downto 0);
   signal s_adc_data_5        : std_logic_vector(15 downto 0);
   signal s_adc_data_6        : std_logic_vector(15 downto 0);
   signal s_adc_data_7        : std_logic_vector(15 downto 0);

begin

impl_ila_ADC : if g_IMPL_ILA_ADC generate

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
   
   iILA_ADC  : ila_adc
   port map
   (
      clk         => i_clk             ,
      probe0(0)   => i_sdo_0           ,
      probe1(0)   => i_sdo_1           ,
      probe2(0)   => i_sdo_2           ,
      probe3(0)   => i_sdo_3           ,
      probe4(0)   => i_sdo_4           ,
      probe5(0)   => i_sdo_5           ,
      probe6(0)   => i_sdo_6           ,
      probe7(0)   => i_sdo_7           ,
      probe8(0)   => i_pulse_acq       ,
      probe9(0)   => s_sclk            ,
      probe10(0)   => s_latch_miso      ,
      probe11(0)   => s_done            ,
      probe12       => s_adc_data_0        ,
      probe13       => s_spi_data_1        ,
      probe14       => s_spi_data_2        ,
      probe15       => s_spi_data_3        ,
      probe16       => s_spi_data_4        ,
      probe17      => s_spi_data_5        ,
      probe18      => s_spi_data_6        ,
      probe19      => s_spi_data_7        ,
      probe20      => s_spi_state_ila
   );
end generate impl_ila_ADC;
    
   p_spi : process(i_clk, i_rst_n)
   begin
      if(i_rst_n = '0') then
         s_spi_state  <= IDLE_ST;
         s_conv       <= '0';
         s_sclk       <= '0';
         s_cs         <= '1';
         s_done       <= '0';
         s_count_data <= 0;
         s_count_conv <= 0;
         s_adc_data_0 <= (others => '0');
         s_adc_data_1 <= (others => '0');             
         s_adc_data_2 <= (others => '0');
         s_adc_data_3 <= (others => '0');               
         s_adc_data_4 <= (others => '0');
         s_adc_data_5 <= (others => '0');          
         s_adc_data_6 <= (others => '0');
         s_adc_data_7 <= (others => '0');      

      elsif(rising_edge(i_clk)) then
         case s_spi_state is
            when IDLE_ST =>                        -- state to wait new acq enable
               s_done <= '0';                      -- reset to set only for one clk
               s_conv <= '0';                      -- by default conv is set to '0'
               s_adc_data_0 <= (others => '0');
               s_adc_data_1 <= (others => '0');             
               s_adc_data_2 <= (others => '0');
               s_adc_data_3 <= (others => '0');               
               s_adc_data_4 <= (others => '0');
               s_adc_data_5 <= (others => '0');          
               s_adc_data_6 <= (others => '0');
               s_adc_data_7 <= (others => '0');      
               if(i_pulse_acq = '1') then          -- when new acq is enable
                  s_spi_state  <= WAIT_CONV_ST;    -- next state is to wait conv timing
                  s_conv       <= '1';             -- set conv to start conversion of ADC
               end if;
               s_cs         <= '1';
            when WAIT_CONV_ST =>                                         -- state to wait conv and tentiming
               if(s_count_conv = C_CONV_TIME) then                       -- when conv timing is over
                 s_conv      <= '0';
               end if;
               if(s_count_conv = C_CONV_TIME+C_TCSSSCKI) then                       -- when conv timing is over
                 s_cs         <= '0';
               end if;
               if(s_count_conv = (C_CONV_TIME+C_TEN_TIME)) then          -- when conv timing is over
                 s_spi_state  <= SCK_ST;                             -- next state is to manage clock spi
                 s_adc_data_0 <= (others => '0');
                 s_adc_data_1 <= (others => '0');             
                 s_adc_data_2 <= (others => '0');
                 s_adc_data_3 <= (others => '0');               
                 s_adc_data_4 <= (others => '0');
                 s_adc_data_5 <= (others => '0');          
                 s_adc_data_6 <= (others => '0');
                 s_adc_data_7 <= (others => '0');                   
                 s_count_conv <= 0;                                  -- reset counter for next new acq
               else  
                  s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
               end if;
               s_pulse_sck <= '0';  
            when SCK_ST =>   
               s_cs         <= '0';  
               s_sclk      <= '1';                                   -- set spi clock to '1'                     
               if(s_count_conv = 3) then          -- when conv timing is over
                     s_count_conv <= 0;                                  -- reset counter for next new acq
                    if(s_pulse_sck = '1') then
                         s_spi_state <= WAIT_DATA_ST;                          -- next state is to wait data from spi
                         s_pulse_sck <= '0';    

                                                          
                      else                                                 -- when no all bits is read
                         s_pulse_sck       <= '1'; 
                    end if;
               else                                                      -- when conv timing is not over
                  s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
               end if;

            when WAIT_DATA_ST =>
               s_cs         <= '0';
               s_sclk <= '0';   -- set spi clock to '0'
               if(s_count_conv = 3) then          -- when conv timing is over
                if(s_pulse_sck = '1') then                                       -- when no all bits is read
                  s_pulse_sck <= '0';
                  if(s_count_data = (C_NB_DATA)) then                  -- when all bits have been read
                     s_count_data <= 0;                                -- reset counter to managed new acq
                     s_adc_data_0 <= s_spi_data_0;
                     s_adc_data_1 <= s_spi_data_1;                     
                     s_adc_data_2 <= s_spi_data_2; 
                     s_adc_data_3 <= s_spi_data_3;                     
                     s_adc_data_4 <= s_spi_data_4;   
                     s_adc_data_5 <= s_spi_data_5;                     
                     s_adc_data_6 <= s_spi_data_6;   
                     s_adc_data_7 <= s_spi_data_7;    
                     s_done       <= '1';
                     s_spi_state  <= IDLE_ST;                          -- next state is to wait new acq
                     
                  else                    
                     s_done       <= '0';
                     s_count_data <= s_count_data + 1;                 -- one more bits is read
                     s_spi_state  <= SCK_ST;                           -- next state is to read another value
                     s_spi_data_0  <= s_spi_data_0(14 downto 0) & i_sdo_0;
                     s_spi_data_1  <= s_spi_data_1(14 downto 0) & i_sdo_1;    
                     s_spi_data_2  <= s_spi_data_2(14 downto 0) & i_sdo_2;
                     s_spi_data_3  <= s_spi_data_3(14 downto 0) & i_sdo_3; 
                     s_spi_data_4  <= s_spi_data_4(14 downto 0) & i_sdo_4;
                     s_spi_data_5  <= s_spi_data_5(14 downto 0) & i_sdo_5; 
                     s_spi_data_6  <= s_spi_data_6(14 downto 0) & i_sdo_6;
                     s_spi_data_7  <= s_spi_data_7(14 downto 0) & i_sdo_7;   
                  end if;
                else
                  s_pulse_sck <= '1';
                end if;
                s_count_conv <= 0;                                  -- reset counter for next new acq
               else                                                      -- when conv timing is not over
                s_count_conv <= s_count_conv + 1;                      -- increment counter for conv timing
               end if;
            when others =>
               s_cs         <= '1';
               s_spi_state <= IDLE_ST;
         end case;
      end if;

   end process;
   
   
   -- Affectation des sorties
   o_cs        <= s_cs;
   o_sck       <= s_sclk;
   o_conv      <= s_conv;
   o_done      <= s_done;
   o_adc_data_0  <= s_adc_data_0;
   o_adc_data_1  <= s_adc_data_1;
   o_adc_data_2  <= s_adc_data_2;
   o_adc_data_3  <= s_adc_data_3;
   o_adc_data_4  <= s_adc_data_4;
   o_adc_data_5  <= s_adc_data_5;
   o_adc_data_6  <= s_adc_data_6;
   o_adc_data_7  <= s_adc_data_7;

end Behavioral;
