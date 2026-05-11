----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.05.2026 22:02:48
-- Design Name: 
-- Module Name: tb_median - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_median is
--  Port ( );
end tb_median;

architecture Behavioral of tb_median is

    component Filter_Median_1D3
      port(
          i_clk           : IN   STD_LOGIC;                           
          i_rst_n         : IN   STD_LOGIC;                               
          i_wr_en         : IN   STD_LOGIC;         
          i_data_n0       : IN   STD_LOGIC_VECTOR(31 DOWNTO 0); 
          i_data_n1       : IN   STD_LOGIC_VECTOR(31 DOWNTO 0);                             
          i_data_n2       : IN   STD_LOGIC_VECTOR(31 DOWNTO 0); 
          o_data          : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);   
          o_data_valid    : OUT  STD_LOGIC           
          );
    end component;
  
constant  CLK_HALFPERIOD: time := 4ns;
  
    signal   s_adc_data  :  std_logic_vector(15 downto 0);
    
    signal   s_adc_data_valid  :  std_logic;
    signal   s_adc_data_mean4  :  std_logic_vector(15 downto 0);
    signal   s_adc_data_mean4_valid  :  std_logic;
    
    signal   s_adc_data_offgain :  std_logic_vector(31 downto 0);
    signal   s_adc_data_offgain_overflow  :  std_logic;
    signal   s_adc_data_offgain_valid  :  std_logic;
    
    
    signal   s_adc_data_median  :  std_logic_vector(31 downto 0);
    signal   s_adc_data_median_valid  :  std_logic;
    
    signal s_adc_data_n0:            std_logic_vector(15 downto 0);
    signal s_adc_data_n1:            std_logic_vector(15 downto 0);
    signal s_adc_data_n2:            std_logic_vector(15 downto 0);
 
  signal i_rst      	: std_logic;
  signal i_rst_n      : std_logic;
  signal i_clk        : std_logic := '0';
  signal cmd_on     : std_logic := '0';
 
begin

	i_rst 	<= '1', '0' after 100ns;
    i_rst_n <= not i_rst;
	i_clk   <= not i_clk after CLK_HALFPERIOD;

 
      
process begin
         s_adc_data_n0 <= X"FFFF";
         s_adc_data_n1 <= X"F0FF";
         s_adc_data_n2 <= X"F5FF";
         wait for 500ns;
         s_adc_data_n0 <= X"F0FF";
         s_adc_data_n1 <= X"FFFF";
         s_adc_data_n2 <= X"F5FF";
         wait for 500ns;
         s_adc_data_n0 <= X"FFFF";
         s_adc_data_n1 <= X"F5FF";
         s_adc_data_n2 <= X"F0FF";
         wait for 500ns;
         s_adc_data_n0 <= X"F0FF";
         s_adc_data_n1 <= X"F5FF";
         s_adc_data_n2 <= X"FFFF";
         wait for 500ns;
         s_adc_data_n0 <= X"F5FF";
         s_adc_data_n1 <= X"FFFF";
         s_adc_data_n2 <= X"F0FF";
         wait for 500ns;
         s_adc_data_n0 <= X"F5FF";
         s_adc_data_n1 <= X"F0FF";
         s_adc_data_n2 <= X"FFFF";
         wait for 500ns;
end process;	

 inst_Filter_Median_adc :  Filter_Median_1D3 
 port map( 
         i_clk         => i_clk,                   -- clock system
         i_rst_n       => i_rst_n,                 -- reset system 
         i_wr_en       => '1',
         i_data_n0(31 DOWNTO 16)    => (others => '0'),
         i_data_n0(15 DOWNTO 0)     => s_adc_data_n0,   
         i_data_n1(31 DOWNTO 16)    => (others => '0'),
         i_data_n1(15 DOWNTO 0)     => s_adc_data_n1, 
         i_data_n2(31 DOWNTO 16)    => (others => '0'),  
         i_data_n2(15 DOWNTO 0)     => s_adc_data_n2,   
         o_data(31 downto 0)        => s_adc_data_median,    
         o_data_valid  => s_adc_data_median_valid       
      );


end Behavioral;
