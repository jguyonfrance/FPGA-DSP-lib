----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- https://github.com/jguyonfrance
-- Create Date: 03.01.2025 14:00:00
-- Design Name: 
-- Module Name: ISOSD61L
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
--                        ___________ ADC________
--                       |                       |
--                   ->  | i_clk                 |
--                   ->  | i_rst_n               |
--                       |                       |
--     FPGA_BOARD    ->  | i_pulse_acq           |               ISOSD61L
--                   ->  | i_nb_clk_filt         |
--                       |                       |
--                       |                       |              
--                   <-  | o_adc_data            |
--                       |                       |
--                       |                       |
--                       |     o_ISOSD61_MDCLK_P |->
--                       |     o_ISOSD61_MDCLK_n |->
--                       |                       |
--                       |     i_ISOSD61_MDAT_P  |<-
--                       |     i_ISOSD61_MDAT_n  |<-
--                       |_______________________|
--
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.std_logic_unsigned.all;
   use IEEE.std_logic_arith.all;
   
library xil_defaultlib;
   use xil_defaultlib.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity ISOSD61_data is
  generic
   (     
    g_IMPL_ILA_ISOSD61  : boolean;
      sys_clk            : INTEGER := 125_000_000; --system clock frequency in Hz
      isos61_div_clk   : INTEGER := 100 -- nb of system clock 
   );
  port ( 
        i_clk         : in  std_logic;                      -- clokck system at 125MHz
        i_rst_n       : in  std_logic;                      -- reset system
        i_pulse_acq   : in  std_logic;    
        
        i_nb_clk_filt   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); 
        
        i_ISOSD61_MDAT_P    : in std_logic;   
        i_ISOSD61_MDAT_N    : in std_logic; 
        o_ISOSD61_MDCLK_P   : out std_logic;        
        o_ISOSD61_MDCLK_N   : out std_logic;   
              
        o_adc_data  : out std_logic_vector(15 downto 0));

end ISOSD61_data;

architecture behavioral of ISOSD61_data is


component Filter_SINC3 is
 port(
        i_clk         : in  std_logic;                      -- clokck system at 125MHz
        i_rst_n       : in  std_logic;                      -- reset system
        i_M_IN        : in  std_logic;  -- data devide  
        i_M_CLK        : in  std_logic;  -- clk device
        i_CNR         : in  std_logic;  -- clk decimation "mclk/m"
        
        o_CN5 : out std_logic_vector(24 downto 0) -- out data filter
 );
end component;


   constant C_SCLK_TIME  : integer range 0 to  20000 :=  10;  -- time between sck (nb of sck)
   
    signal  s_cpt_clk_sck        :  INTEGER RANGE 0 TO sys_clk := 1024;

   signal s_pulse_sck      : std_logic;                   
   signal s_out_sck      : std_logic;  
   
   signal s_in_dat      : std_logic;  

   
   signal s_adc_data       : std_logic_vector(24 downto 0);

    signal s_pulse_filt:            std_logic;
    signal s_cpt_clk_filt: std_logic_vector(31 downto 0) := (others => '0');

 
 
 
    
begin



IBUFDS_inst : IBUFDS
generic map (
   DIFF_TERM => FALSE, -- Differential Termination
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => s_in_dat,  -- Buffer output
   I => i_ISOSD61_MDAT_P,  -- Diff_p buffer input (connect directly to top-level port)
   IB => i_ISOSD61_MDAT_N -- Diff_n buffer input (connect directly to top-level port)
);

OBUFDS_inst : OBUFDS
generic map (
   IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
   SLEW => "SLOW")          -- Specify the output slew rate
port map (
   O => o_ISOSD61_MDCLK_P,     -- Diff_p output (connect directly to top-level port)
   OB => o_ISOSD61_MDCLK_N,   -- Diff_n output (connect directly to top-level port)
   I => s_out_sck      -- Buffer input
);
         

--impl_ila_ISOSD61 : if g_IMPL_ILA_ISOSD61 generate
--   iILA_ADC  : ila_ISOSD61
--   port map
--   (
--      clk         => i_clk             ,
--      probe1(0)   => i_pulse_acq       ,
--      probe2(0)   => s_sclk            ,
--      probe3(0)   => s_conv            ,
--      probe5      => s_adc_data        ,
--   );
--end generate impl_ila_ADC7980;


 inst_Filter_SINC3_0 : Filter_SINC3
   port map(
        i_clk           => i_clk,                   -- clock system
        i_rst_n         => i_rst_n,                 -- reset system     

        i_M_IN => s_in_dat, 
        i_M_CLK => s_out_sck, 
        i_CNR => s_pulse_filt, 
        o_CN5(24 downto 0) => s_adc_data(24 downto 0) 
   );  

  -- Affectation des sorties    
    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
             o_adc_data  <= (others => '0');
          elsif(rising_edge(i_clk)) then
             o_adc_data  <= s_adc_data;
           end if;
    end process; 
    
    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
            s_pulse_sck <= '0';
            s_out_sck <= '0';
          elsif(rising_edge(i_clk)) then
                if(s_cpt_clk_sck = isos61_div_clk) then
                     s_cpt_clk_sck <= 0;
                     s_pulse_sck <= not s_out_sck;
                     s_out_sck   <= not s_out_sck;
                else
                     s_out_sck <= '0';
                     s_pulse_sck <= '0';
                     s_cpt_clk_sck <= s_cpt_clk_sck + 1;
                end if;  
           end if;
    end process;  

    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
          
          elsif(rising_edge(i_clk)) then
                if(s_cpt_clk_filt = i_nb_clk_filt) then
                     s_cpt_clk_filt <= (others => '0');
                     s_pulse_filt <= '1';
                else
                     s_cpt_clk_filt <= s_cpt_clk_filt + x"1";
                     s_pulse_filt <= '0';
                end if;  
           end if;
    end process;  





   
end Behavioral;
