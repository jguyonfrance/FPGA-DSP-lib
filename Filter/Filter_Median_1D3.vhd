----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- https://github.com/jguyonfrance
-- Create Date: 01.02.2026 14:00:00
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Filter_Median_1D3 is
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
end Filter_Median_1D3;

architecture Behavioral of Filter_Median_1D3 is

signal s_data_n0: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal s_data_n1: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal s_data_n2: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal s_o_data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal s_table_in: STD_LOGIC_VECTOR(3 downto 0) := (others => '0');


begin

s_data_n0 <= i_data_n0;
s_data_n1 <= i_data_n1;
s_data_n2 <= i_data_n2;

s_table_in(0) <= '1' when (s_data_n0 > s_data_n1) else '0';
s_table_in(1) <= '1' when (s_data_n1 > s_data_n2) else '0';
s_table_in(2) <= '1' when (s_data_n0 > s_data_n2) else '0';


with s_table_in select s_o_data <=      s_data_n2 when "101",
                                        s_data_n1 when "000",
                                        s_data_n0 when "100",
                                        s_data_n0 when "011",    
                                        s_data_n1 when "111",
                                        s_data_n0 when others;

process(i_clk)
begin              
 if(i_rst_n = '0') then
         o_data <= (others => '0');
 elsif rising_edge(i_clk) then
    if(i_wr_en = '1') then
         o_data <= s_o_data;
         o_data_valid <= '1';
    else
         o_data_valid <= '0';
    end if;  
 end if;
end process;


end Behavioral;