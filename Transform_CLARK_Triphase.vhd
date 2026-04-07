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
   use IEEE.std_logic_signed.all;
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
    i_Ua			: in signed(31 downto 0);   -- Q32.16
    i_Ub			: in signed(31 downto 0);   -- Q32.16
    i_Uc			: in signed(31 downto 0);   -- Q32.16
	i_datavalid		: in std_logic;
    
    o_Alpha   	    : out signed(31 downto 0);   --Q32.16
    o_Beta    	    : out signed(31 downto 0);   --Q32.16
	o_datavalid 	: out std_logic
  );
end Transform_CLARK_Triphase;

architecture Behavioral of Transform_CLARK_Triphase is

	component mult_gen_0 
      Port ( 
        CLK : in STD_LOGIC;
        A : in STD_LOGIC_VECTOR ( 31 downto 0 );
        B : in STD_LOGIC_VECTOR ( 15 downto 0 );
        P : out STD_LOGIC_VECTOR ( 47 downto 0 )
      );
    end component;
	-- internal signals
	signal s_state		: natural range 0 to 6 := 0;
	signal s_a_scaled : signed(47 downto 0); -- Q32.16
	signal s_b_scaleddiv2 : signed(47 downto 0); -- Q32.16
	signal s_c_scaleddiv2 : signed(47 downto 0); -- Q32.16
	signal s_alpha_int : signed(31 downto 0); -- Q32.16
	
	--signals for multiplier
--	signal mult_in_a	:	signed(31 downto 0) := (others=>'0');
--	signal mult_in_b	:	signed(31 downto 0) := (others=>'0');
--	signal mult_out	:	signed(63 downto 0) := (others=>'0');
	
	signal s_mult_in_a	:	STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
	signal s_mult_in_b	:	STD_LOGIC_VECTOR(15 downto 0) := (others=>'0');
	signal s_mult_out_sqrt_ub	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');
	signal s_mult_out_sqrt_uc	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');

	signal s_alpha_scaled	:	signed(47 downto 0) := (others=>'0');
	signal s_beta_scaled	:	signed(47 downto 0) := (others=>'0'); 	
	signal s_alpha_2div3	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');
	signal s_beta_2div3   	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');    
	
constant  c_SQRT3div2: STD_LOGIC_VECTOR(15 downto 0) := X"6EDA"; --Q16.15
constant  c_NSQRT3div2: STD_LOGIC_VECTOR(15 downto 0) := X"9126"; --Q16.15
constant  c_2div3: STD_LOGIC_VECTOR(15 downto 0) := X"5555"; --Q16.15
    
begin
	-- multiplier
--	process(mult_in_a, mult_in_b)
--	begin
--		mult_out <= mult_in_a * mult_in_b;
--	end process;
	
	
inst_mult_gen_sqrt_Ub :mult_gen_0
port map(
    CLK=>i_clk,
	P=>s_mult_out_sqrt_ub,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(i_Ub),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>c_SQRT3div2--Multiplier inputB bus, width determined by WIDTH_B generic
);
inst_mult_gen_sqrt_Uc :mult_gen_0
port map(
    CLK=>i_clk,
	P=>s_mult_out_sqrt_uc,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(i_Uc),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>c_NSQRT3div2--Multiplier inputB bus, width determined by WIDTH_B generic
);



inst_mult_gen_alpha_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>s_alpha_2div3,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_alpha_scaled(31 downto 0)),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>c_2div3--Multiplier inputB bus, width determined by WIDTH_B generic
);	
inst_mult_gen_betha_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>s_beta_2div3,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_beta_scaled(47 downto 16)),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>c_2div3--Multiplier inputB bus, width determined by WIDTH_B generic
);	

		

   p_clark_0: process(i_clk, i_rst_n)
	begin
        if(i_rst_n = '0') then
				o_datavalid <= '0';
				s_state <= 0;
				o_Alpha <= (others => '0');
				o_Beta  <= (others => '0');
        elsif rising_edge(i_clk) then
			if (i_datavalid = '1' and s_state = 0) then
				-- alpha = (2/3) * (a + b/2 + c/2)
				-- beta = (2/3) * (sqrt(3)*b/2 + sqrt(3)*c/2)
				o_datavalid <= '0';
				s_a_scaled(47 downto 32) <= (others => i_Ua(31));
				s_a_scaled(31 downto 0) <= i_Ua;
				s_b_scaleddiv2(47 downto 31) <= (others => i_Ub(31));
				s_b_scaleddiv2(30 downto 0) <= i_Ub(31 downto 1);
				s_c_scaleddiv2(47 downto 31) <= (others => i_Uc(31));
				s_c_scaleddiv2(30 downto 0) <= i_Uc(31 downto 1);
				
				s_state <= 1;
			
			elsif (s_state = 1) then
				s_alpha_scaled <= s_a_scaled - s_b_scaleddiv2 - s_c_scaleddiv2;
				s_beta_scaled <= signed(s_mult_out_sqrt_ub) + signed(s_mult_out_sqrt_uc);
				
				
				s_state <= s_state + 1;
			elsif (s_state = 2) then
				o_Alpha <= signed(s_alpha_2div3(46 downto 15));
				o_Beta  <= signed(s_beta_2div3(45 downto 14));
				
				
				s_state <= s_state + 1;			
		    elsif (s_state = 3) then
				o_datavalid <= '1';
				s_state <= s_state + 1;

			elsif (s_state = 4) then
				o_datavalid <= '0';
				s_state <= 0;
			end if;
		end if;
	end process;
end Behavioral;