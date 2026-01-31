----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- 
-- Create Date: 31.01.2026 14:00:00
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use IEEE.std_logic_signed.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity filter_FIR8 is
--  
PORT( 
    i_clk   	: IN STD_LOGIC;
    i_rst   	: IN STD_LOGIC;    
    o_done      : OUT STD_LOGIC;
    i_adc_data  : IN SIGNED(15 DOWNTO 0);
	
    o_filtered_adc_data : OUT SIGNED(15 DOWNTO 0)
);
end filter_FIR8;

architecture Behavioral of filter_FIR8 is

signal adc_done			: std_logic := '0';

type coeff_type is array(0 to 8) of signed(15 downto 0);
signal coeff: coeff_type := ( X"04F6",
							  X"0AE4",
							  X"1089",
							  X"1496",
							  X"160F",
							  X"1496",
							  X"1089",
							  X"0AE4",
							  X"04F6"
							  );
							  
type delayed_signal_type is array(0 to 8) of signed(15 downto 0);						  
type prod_type is array(0 to 8) of signed(31 downto 0);							  
type sum_0_type is array(0 to 4) of signed(32 downto 0);						  
type sum_1_type is array(0 to 2) of signed(33 downto 0);						  
type sum_2_type is array(0 to 1) of signed(34 downto 0);						  


signal delayed_signal: delayed_signal_type;
signal prod: prod_type;
signal sum_0: sum_0_type;
signal sum_1: sum_1_type;
signal sum_2: sum_2_type;
signal sum_3: signed(35 downto 0);

						  

begin

o_done <= adc_done;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			delayed_signal(0) <= i_adc_data;
			for i in 1 to 8 loop 
			 delayed_signal(i) <= delayed_signal(i-1);
			 end loop;
		end if;
end process;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			for j in 0 to 8 loop 
			 prod(j) <= delayed_signal(j) * coeff(j);
			 end loop;
		end if;
end process;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			sum_0(0) <= (prod(0)(31) & prod(0)) + (prod(1)(31) & prod(1));
			sum_0(1) <= (prod(2)(31) & prod(2)) + (prod(3)(31) & prod(3));
			sum_0(2) <= (prod(4)(31) & prod(4)) + (prod(5)(31) & prod(5));
			sum_0(3) <= (prod(6)(31) & prod(6)) + (prod(7)(31) & prod(7));
			sum_0(4) <= prod(8)(31) & prod(8);
		end if;
end process;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			sum_1(0) <= (sum_0(0)(32) & sum_0(0)) + (sum_0(1)(32) & sum_0(1));
			sum_1(1) <= (sum_0(2)(32) & sum_0(2)) + (sum_0(3)(32) & sum_0(3));
			sum_1(2) <= sum_0(4)(32) & sum_0(4);
		end if;
end process;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			sum_2(0) <= (sum_1(0)(33) & sum_1(0)) + (sum_1(1)(33) & sum_1(1));
			sum_2(1) <= sum_1(2)(33) & sum_1(2);
		end if;
end process;

process(i_clk)
	begin 
		if(rising_edge(i_clk)) then
			sum_3 <= (sum_2(0)(34) & sum_2(0)) + (sum_2(1)(34) & sum_2(1));
		end if;
end process;

o_filtered_adc_data <= sum_3(35) & sum_3(28 downto 14);

   
   
end Behavioral;