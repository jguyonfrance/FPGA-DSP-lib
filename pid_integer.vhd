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
library IEEE;
   use IEEE.std_logic_1164.all;
   use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
   use xil_defaultlib.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity PID is
    Port( 
        i_clk             : IN  STD_LOGIC;                                 
        i_rst_n           : IN  STD_LOGIC;
        i_consign	: in signed(24 downto 0);
        i_consign_wr_en   : IN  STD_LOGIC;  
        i_Kp    	: in signed(15 downto 0);
        i_Ki    	: in signed(15 downto 0);
        i_Kd    	: in signed(15 downto 0);
        i_d_ready   : IN  STD_LOGIC;  
        i_d_in  	: in signed(24 downto 0);
        o_d_out 	: out signed(40 downto 0)
	);
end PID;




architecture Behavioral of PID is

component c_accum_0
  Port ( 
    B : in STD_LOGIC_VECTOR ( 24 downto 0 );
    CLK : in STD_LOGIC;
    CE : in STD_LOGIC;
    SCLR : in STD_LOGIC;
    Q : out STD_LOGIC_VECTOR ( 25 downto 0 )
  );
end component;

signal s_rst		: STD_LOGIC;

signal s_consign 	    : signed(24 downto 0) := (others => '0');

signal s_input 		    : signed(24 downto 0) := (others => '0');
signal s_output		    : signed(40 downto 0) := (others => '0');



signal s_error 		    : STD_LOGIC_VECTOR(24 downto 0) := (others => '0');
signal s_prev_error 	: STD_LOGIC_VECTOR(24 downto 0) := (others => '0');

signal s_integral		: STD_LOGIC_VECTOR(25 downto 0) := (others => '0');
signal s_integral_limit : STD_LOGIC := '0';
signal s_derivative	    : STD_LOGIC_VECTOR(24 downto 0) := (others => '0');

signal s_pTerm		: STD_LOGIC_VECTOR(40 downto 0) := (others => '0');
signal s_iTerm		: STD_LOGIC_VECTOR(40 downto 0) := (others => '0');
signal s_dTerm		: STD_LOGIC_VECTOR(40 downto 0) := (others => '0');

constant c_clk_en 		: STD_LOGIC := '1';


begin



MULT_MACRO_inst1:MULT_MACRO -- DSP48 DSP block multipliers.
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>25, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_pTerm,			--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>STD_LOGIC_VECTOR(s_error),--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>STD_LOGIC_VECTOR(i_Kp),--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>c_clk_en,				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);

MULT_MACRO_inst2:MULT_MACRO
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>25, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_iTerm,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>STD_LOGIC_VECTOR(s_integral(25 downto 1)),	--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>STD_LOGIC_VECTOR(i_Ki),--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>c_clk_en,				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);


MULT_MACRO_inst3:MULT_MACRO
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>25, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_dTerm,				--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>STD_LOGIC_VECTOR(s_derivative),--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>STD_LOGIC_VECTOR(i_Kd),	--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>c_clk_en,				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);

ADDSUB_MACRO_inst1 : ADDSUB_MACRO
generic map (
   DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
   LATENCY => 2,        -- Desired clock cycle latency, 0-2
   WIDTH => 25)         -- Input / Output bus width, 1-48
port map (
   RESULT => s_error,     -- Add/sub result output, width defined by WIDTH generic
   A => STD_LOGIC_VECTOR(s_consign),               -- Input A bus, width defined by WIDTH generic
   ADD_SUB => '0',   -- 1-bit add/sub input, high selects add, low selects subtract
   B => STD_LOGIC_VECTOR(s_input),               -- Input B bus, width defined by WIDTH generic
   CARRYIN => '1',   -- 1-bit carry-in input
	CE=>c_clk_en,				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);

ADDSUB_MACRO_inst2 : c_accum_0
port map (
    Q => s_integral,    
    B => STD_LOGIC_VECTOR(s_error), 
    CE => s_integral_limit,
    CLK=>i_clk,		
    SCLR=>s_rst		
);


with s_integral(25 downto 24) select    s_integral_limit <=      (i_d_ready and not s_error(24))        when "10",
                                                                 (i_d_ready and s_error(24))        when "01",
                                                                  i_d_ready                         when others;



ADDSUB_MACRO_inst3 : ADDSUB_MACRO
generic map (
   DEVICE => "7SERIES", -- Target Device: "VIRTEX5", "7SERIES", "SPARTAN6"
   LATENCY => 2,        -- Desired clock cycle latency, 0-2
   WIDTH => 25)         -- Input / Output bus width, 1-48
port map (
   RESULT => s_derivative,     -- Add/sub result output, width defined by WIDTH generic
   A => STD_LOGIC_VECTOR(s_error),               -- Input A bus, width defined by WIDTH generic
   ADD_SUB => '0',   -- 1-bit add/sub input, high selects add, low selects subtract
   B => STD_LOGIC_VECTOR(s_prev_error),               -- Input B bus, width defined by WIDTH generic
   CARRYIN => '1',   -- 1-bit carry-in input
	CE=>c_clk_en,				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);

-- End of ADDSUB_MACRO_inst instantiation
s_rst <= not i_rst_n;
o_d_out <= s_output; 




    process(i_clk) begin
        if (i_rst_n = '0') then
            s_input 		<= (others => '0');        
            s_output <= (others => '0');
            s_consign <= (others => '0');    
            s_prev_error 	<= (others => '0');		
        elsif rising_edge(i_clk) then
            if (i_consign_wr_en = '1') then
                s_consign <= i_consign;    
            end if;
            if (i_d_ready = '1') then
                s_input 		<= i_d_in;
                s_output <= signed(s_pTerm) + signed(s_iTerm) + signed(s_dTerm);
                
                s_prev_error <= s_error;	
                
            end if;
            
        end if;
    end process;




--derivative <= input-SHIFT_LEFT(prev_input,1)+prev_input2;
--derivative <= SHIFT_RIGHT(input - prev_input,4);
--output <= prev_output + signed(pTerm) + signed(iTerm) - signed(dTerm);
--d_out <= output when output(38) = '0' else output(38) & ((not output(37 downto 0)) - 1); 

--d_out <= output;


end Behavioral;