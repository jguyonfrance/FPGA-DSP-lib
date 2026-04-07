----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- https://github.com/jguyonfrance
-- Create Date: 03.04.2026 14:00:00
-- Design Name: 
-- Module Name: Filter_SINC3
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
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity Filter_SINC3 is
 port(
        i_clk         : in  std_logic;                      -- clokck system at 125MHz
        i_rst_n       : in  std_logic;                      -- reset system
        i_M_IN        : in  std_logic;  -- data devide  
        i_M_CLK        : in  std_logic;  -- clk device
        i_CNR         : in  std_logic;  -- clk decimation "mclk/m"
        
        o_CN5 : out std_logic_vector(24 downto 0) -- out data filter
 );
end Filter_SINC3;

architecture Behavioral of Filter_SINC3 is

  
    signal s_DN0, s_DN1, s_DN3, s_DN5 : std_logic_vector(24 downto 0);
    signal s_CN1, s_CN2, s_CN3, s_CN4 : std_logic_vector(24 downto 0);
    signal s_DELTA1 : std_logic_vector(24 downto 0);
    
 
begin

    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
            s_DELTA1 <= (others => '0');
          elsif(rising_edge(i_clk)) then
                if((i_M_CLK and i_M_IN) = '1') then
                    s_DELTA1 <= s_DELTA1 + 1;
                end if;  
           end if;
    end process;  

    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
            s_CN1 <= (others => '0');
            s_CN2 <= (others => '0');
          elsif(rising_edge(i_clk)) then
                if((i_M_CLK) = '1') then
                    s_CN1 <= s_CN1 + s_DELTA1;
                    s_CN2 <= s_CN2 + s_CN1;                 
                end if; 
           end if;
    end process;  


    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
             s_DN0 <= (others => '0');
             s_DN1 <= (others => '0');
             s_DN3 <= (others => '0');
             s_DN5 <= (others => '0');
          elsif(rising_edge(i_clk)) then
                if((i_CNR) = '1') then
                     s_DN0 <= s_CN2;
                     s_DN1 <= s_DN0;
                     s_DN3 <= s_CN3;
                     s_DN5 <= s_CN4;                
                end if; 
           end if;
    end process;  

 s_CN3 <= s_DN0 - s_DN1;
 s_CN4 <= s_CN3 - s_DN3;
 o_CN5 <= s_CN4 - s_DN5;


end Behavioral;



 