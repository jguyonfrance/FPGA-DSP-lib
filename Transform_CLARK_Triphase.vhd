----------------------------------------------------------------------------------
-- Company: 
-- Engineer: J.Guyon
-- 
-- Create Date: 10.12.2025 14:49:57
-- Design Name: 
-- Module Name:  - Behavioral
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
   use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
   use xil_defaultlib.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity Transform_CLARK_Triphase is
  port( 

    i_clk           : IN  STD_LOGIC;                           
    i_rst_n         : IN  STD_LOGIC;     
    i_Ua			: in signed(31 downto 0);   --Q15.16
    i_Ub			: in signed(31 downto 0);   --Q15.16
    i_Uc			: in signed(31 downto 0);   --Q15.16
	i_datavalid		: in std_logic;
    
    o_Alpha   	    : out signed(31 downto 0);   --Q15.16
    o_Beta    	    : out signed(31 downto 0);   --Q15.16
	o_datavalid 	: out std_logic
  );
end Transform_CLARK_Triphase;

architecture Behavioral of Transform_CLARK_Triphase is

	-- internal signals
	signal state		: natural range 0 to 5 := 0;

	signal b_scaled : signed(31 downto 0); -- Q15.16
	signal c_scaled : signed(31 downto 0); -- Q15.16
	signal alpha_int : signed(31 downto 0); -- Q15.16
	
	--signals for multiplier
	signal mult_in_a	:	signed(31 downto 0) := (others=>'0');
	signal mult_in_b	:	signed(31 downto 0) := (others=>'0');
	signal mult_out	:	signed(63 downto 0) := (others=>'0');
begin
	-- multiplier
	process(mult_in_a, mult_in_b)
	begin
		mult_out <= mult_in_a * mult_in_b;
	end process;

   p_clark_0: process(i_clk, i_rst_n)
	begin
        if(i_rst_n = '0') then
				o_datavalid <= '0';
				state <= 0;
				o_Alpha <= (others => '0');
				o_Beta  <= (others => '0');
        elsif rising_edge(i_clk) then
			if (i_datavalid = '1' and state = 0) then
				-- alpha = (2/3) * (a + b/2 + c/2)
				-- beta = (2/3) * (sqrt(3)*b/2 + sqrt(3)*c/2)
			    alpha_int <=  i_Ua - shift_right(i_Ub, 1) - shift_right(i_Uc, 1); 
				o_datavalid <= '0';
				mult_in_a <= i_Ub;
				mult_in_b <= to_signed(56756, 32); -- sqrt(3)/2 as Q15.16
			
				state <= 1; -- start state-machine
			
			elsif (state = 1) then
				b_scaled <= resize(shift_right(mult_out, 16), 32);
				mult_in_a <= i_Uc;
				mult_in_b <= - to_signed(56756, 32); -- sqrt(3)/2 as Q15.16				
				state <= state + 1;

			elsif (state = 2) then
				c_scaled <= resize(shift_right(mult_out, 16), 32);
				state <= state + 1;
			elsif (state = 3) then
				mult_in_a <= alpha_int; 
				mult_in_b <= to_signed(43691, 32); -- (2/3) as Q15.16
			
				state <= state + 1;		
					
		    elsif (state = 4) then
		        alpha_int <= resize(shift_right(mult_out, 16), 32);
				mult_in_a <= b_scaled + c_scaled; 
			
				state <= state + 1;

			elsif (state = 5) then
				o_Alpha <= alpha_int;
				o_Beta <= resize(shift_right(mult_out, 16), 32);
				
				o_datavalid <= '1';
			
				state <= state + 1;

			elsif (state = 6) then
				o_datavalid <= '0';
				state <= 0;
			end if;
		end if;
	end process;
end Behavioral;