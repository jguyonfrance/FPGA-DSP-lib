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

entity Transform_PARK is
  port( 
    i_clk           : IN  STD_LOGIC;                           
    i_rst_n         : IN  STD_LOGIC;     

    i_Alpha   	    : in signed(31 downto 0);   --Q32.16
    i_Beta    	    : in signed(31 downto 0);   --Q32.16
    i_Theta    	    : in signed(15 downto 0);   --Q16.13
	i_datavalid		: in std_logic;
    
    o_Direct   	    : out signed(31 downto 0);   --Q32.30
    o_Quadrature    : out signed(31 downto 0);   --Q32.30
	o_datavalid 	: out std_logic
  );
end Transform_PARK;
  
architecture Behavioral of Transform_PARK is

    component mult_gen_0 
      Port ( 
        CLK : in STD_LOGIC;
        A : in STD_LOGIC_VECTOR ( 31 downto 0 );
        B : in STD_LOGIC_VECTOR ( 15 downto 0 );
        P : out STD_LOGIC_VECTOR ( 47 downto 0 )
      );
    end component;

	signal state					: natural range 0 to 10 := 0;
	signal start_cordic			: std_logic := '0';

	signal cordic_done 	: std_logic;
    signal sin_std, cos_std 			: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); -- type: Q0.15
	signal sine_int, cosine_int     : signed(31 downto 0) := (others => '0'); -- type: Q15.16

	signal s_Alpha	:	signed(31 downto 0) := (others=>'0');
	signal s_Beta	:	signed(31 downto 0) := (others=>'0');

	signal s_Direct   	:	signed(47 downto 0) := (others=>'0');
	signal s_Quadrature	:	signed(47 downto 0) := (others=>'0');
	
	--signals for multiplier
	signal mult_in_a	:	STD_LOGIC_VECTOR(31 downto 0) := (others=>'0');
	signal mult_in_b	:	STD_LOGIC_VECTOR(15 downto 0) := (others=>'0');
	signal mult_out_sin_d	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');
	signal mult_out_cos_d	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');

	signal mult_out_sin_q	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');
	signal mult_out_cos_q	:	STD_LOGIC_VECTOR(47 downto 0) := (others=>'0');

begin
	-- multiplier
	

inst_mult_gen_cos_d_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>mult_out_cos_d,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_Beta),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>cos_std--Multiplier inputB bus, width determined by WIDTH_B generic
);
inst_mult_gen_sin_d_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>mult_out_sin_d,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_Alpha),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>sin_std--Multiplier inputB bus, width determined by WIDTH_B generic
);	


inst_mult_gen_cos_q_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>mult_out_cos_q,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_Alpha),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>cos_std--Multiplier inputB bus, width determined by WIDTH_B generic
);
inst_mult_gen_sin_q_0:mult_gen_0
port map(
    CLK=>i_clk,
	P=>mult_out_sin_q,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>std_logic_vector(s_Beta),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>sin_std--Multiplier inputB bus, width determined by WIDTH_B generic
);	


		

cordic_sine_cos_0: entity work.cordic_0
 port map (
	aclk		=> i_clk,
	s_axis_phase_tvalid		=> start_cordic,
	s_axis_phase_tdata		=> std_logic_vector(i_Theta),
	m_axis_dout_tvalid		=> cordic_done,
	m_axis_dout_tdata(31 downto 16)		=> sin_std,
	m_axis_dout_tdata(15 downto 0)		=> cos_std
);


   p_park_0: process(i_clk, i_rst_n)
	begin
	
        if(i_rst_n = '0') then
				o_datavalid <= '0';
				state <= 0;
				s_Alpha <= (others => '0');
				s_Beta  <= (others => '0');
        elsif rising_edge(i_clk) then
        
			if (i_datavalid = '1' and state = 0) then
				s_Alpha <= i_Alpha;
				s_Beta  <= i_Beta;
				start_cordic <= '1';
				state <= 1; -- start of state-machine
			elsif (state = 1 and cordic_done = '1') then 
				s_Direct     <= signed(mult_out_cos_d) - signed(mult_out_sin_d);--Q32.14
				s_Quadrature <= signed(mult_out_cos_q) - signed(mult_out_sin_q);--Q32.14
				state <= state + 1;
			elsif (state = 2) then
				o_Direct     <= s_Direct(47 downto 16); --Q32.16
				o_Quadrature <= s_Quadrature(47 downto 16);--Q32.16
				o_datavalid <= '1';

				state <= state + 1;

			elsif (state = 3) then
				o_datavalid <= '0';
				start_cordic <= '0';
				state <= 0;
			end if;
		end if;
	end process;
	

end Behavioral;
