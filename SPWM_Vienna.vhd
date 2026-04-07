----------------------------------------------------------------------------------
-- Company: 
-- Engineer: J.Guyon
-- 
-- Create Date: 10.09.2025 14:49:57
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
    
use IEEE.std_logic_unsigned.all;

library xil_defaultlib;
   use xil_defaultlib.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


--============================================================================--
--                          DECLARATION DE L ENTITE                           --
--============================================================================--
entity SPWM_Vienna is
  port ( 
        i_clk                 : in  std_logic;                      -- clokck system at 125MHz
        i_rst_n               : in  std_logic;                      -- reset system
        i_PWM_en              : in  std_logic;        
        i_pwm_freq            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); --duty cycle
        
        i_theta_wr_en              : in  std_logic;        
        i_theta_A    	    : in STD_LOGIC_VECTOR(31 downto 0);   --Q15.16    -1 = 100% n°1 / 0=0% / 1=100% n°2
        i_theta_B    	    : in STD_LOGIC_VECTOR(31 downto 0);   --Q15.16    -1 = 100% n°1 / 0=0% / 1=100% n°2
        i_theta_C    	    : in STD_LOGIC_VECTOR(31 downto 0);   --Q15.16    -1 = 100% n°1 / 0=0% / 1=100% n°2
        
        
        i_percent_A    	    : in STD_LOGIC_VECTOR(15 downto 0);  --X"FFFF" = 100% 
        i_percent_B    	    : in STD_LOGIC_VECTOR(15 downto 0);  --X"FFFF" = 100%  
        i_percent_C    	    : in STD_LOGIC_VECTOR(15 downto 0);  --X"FFFF" = 100% 
        
        i_cmd_bidir_en    	 : in  std_logic;  
        
        o_en_PWM_VIENNA  : out std_logic;   
        o_PWMA1  : out std_logic;   
        o_PWMA2  : out std_logic;     
        o_PWMB1  : out std_logic; 
        o_PWMB2  : out std_logic; 
        o_PWMC1  : out std_logic; 
        o_PWMC2  : out std_logic
        
       );
end SPWM_Vienna;

architecture Behavioral of SPWM_Vienna is

component mod_pwm IS 
  GENERIC(
      sys_clk         : INTEGER := 125_000_000; --system clock frequency in Hz
      bits_resolution : INTEGER := 16;          --bits of resolution setting the duty cycle
      phases          : INTEGER := 1);         --number of output pwms and phases
  PORT(
      clk       : IN  STD_LOGIC;                                    --system clock
      reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
      ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
      pwm_freq  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0); --duty cycle
      duty      : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0); --duty cycle
      pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0);          --pwm outputs
      pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0));         --pwm inverse outputs
END component;

     signal s_rst       : std_logic;
     signal s_en_pwm       : std_logic;
    
     signal s_wr_en       : std_logic;
     
     signal s_duty_A       : STD_LOGIC_VECTOR(16 downto 0) := (others => '0');
     signal s_duty_B       : STD_LOGIC_VECTOR(16 downto 0) := (others => '0');
     signal s_duty_C       : STD_LOGIC_VECTOR(16 downto 0) := (others => '0');
     
     signal s_mult_percent_A       : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
     signal s_mult_percent_B       : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
     signal s_mult_percent_C       : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
     
     signal s_pwm_A      	: STD_LOGIC := '0';
     signal s_pwm_B     	: STD_LOGIC := '0';
     signal s_pwm_C     	: STD_LOGIC := '0';
     

begin


s_rst <= not i_rst_n;

    
    
MULT_MACRO_inst1:MULT_MACRO -- DSP48 DSP block multipliers.
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>16, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_mult_percent_A,			--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>s_duty_A(15 downto 0),--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>i_percent_A,--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>'1',				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);  
    
MULT_MACRO_inst2:MULT_MACRO -- DSP48 DSP block multipliers.
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>16, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_mult_percent_B,			--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>s_duty_B(15 downto 0),--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>i_percent_B,--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>'1',				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);  
        
MULT_MACRO_inst3:MULT_MACRO -- DSP48 DSP block multipliers.
generic map(
	DEVICE=>"7SERIES",	--TargetDevice:"VIRTEX5","7SERIES","SPARTAN6"
	LATENCY=>3, 		--Desired clock cycle latency, 0-4
	WIDTH_A=>16, 		--Multiplier A-input bus width,1-25
	WIDTH_B=>16) 		--Multiplier B-input bus width,1-18
port map(
	P=>s_mult_percent_C,			--Multiplier ouput bus, width determined by WIDTH_P generic
	A=>s_duty_C(15 downto 0),--Multiplier inputA bus,width determined by WIDTH_A generic
	B=>i_percent_C,--Multiplier inputB bus, width determined by WIDTH_B generic
	CE=>'1',				--1-bit active high input clock enable
	CLK=>i_clk,			--1-bit positive edge clock input
	RST=>s_rst			--1-bit input active high reset
);  


   inst_pwm_A :  mod_pwm
--   generic map(
--      sys_clk = 125_000_000,
--      pwm_freq = 80_000,
--      bits_resolution = 16,
--      phases = 1 )
    port map( 
         clk          => i_clk,                   -- clock system
         reset_n      => i_rst_n,                 -- reset system  
         ena          => s_wr_en,       
         pwm_freq     => i_pwm_freq,        
         duty         => s_duty_A(15 downto 0),--s_mult_percent_A(31 downto 16),                 
         pwm_out(0)      => s_pwm_A,  
         pwm_n_out    => open
    );
    
   inst_pwm_B :  mod_pwm
--   generic map(
--      sys_clk = 125_000_000,
--      pwm_freq = 80_000,
--      bits_resolution = 16,
--      phases = 1 )
    port map( 
         clk          => i_clk,                   -- clock system
         reset_n      => i_rst_n,                 -- reset system  
         ena          => s_wr_en,     
         pwm_freq     => i_pwm_freq,                   
         duty         => s_mult_percent_B(31 downto 16),                 
         pwm_out(0)      => s_pwm_B,  
         pwm_n_out    => open
    );
   inst_pwm_C :  mod_pwm
--   generic map(
--      sys_clk = 125_000_000,
--      pwm_freq = 80_000,
--      bits_resolution = 16,
--      phases = 1 )
    port map( 
         clk          => i_clk,                   -- clock system
         reset_n      => i_rst_n,                 -- reset system  
         ena          => s_wr_en,    
         pwm_freq     => i_pwm_freq,                    
         duty         => s_duty_C(15 downto 0),--s_mult_percent_C(31 downto 16),                 
         pwm_out(0)      => s_pwm_C,  
         pwm_n_out    => open
    );
           -- Data  wr 
           
           

    process(i_clk, i_rst_n)
    begin
    if(i_rst_n = '0') then
            s_duty_A <= (others => '0'); 
            s_duty_B <= (others => '0'); 
            s_duty_C <= (others => '0'); 
            s_wr_en <= '0';
    elsif(rising_edge(i_clk)) then
        if (i_theta_wr_en = '1') then
            s_wr_en <= '1';          
            if (i_theta_A(31) = '1') then
                s_duty_A(15 downto 0) <= not i_theta_A(15 downto 0);  
                s_duty_A(16) <= '1';
            else 
                s_duty_A(15 downto 0) <= i_theta_A(15 downto 0);  
                s_duty_A(16) <= '0';
            end if; 
            if (i_theta_B(31) = '1') then
                s_duty_B(15 downto 0) <= not i_theta_B(15 downto 0);  
                s_duty_B(16) <= '1';
            else 
                s_duty_B(15 downto 0) <= i_theta_B(15 downto 0);  
                s_duty_B(16) <= '0';
            end if; 
            if (i_theta_C(31) = '1') then
                s_duty_C(15 downto 0) <= not i_theta_C(15 downto 0);  
                s_duty_C(16) <= '1';
            else 
                s_duty_C(15 downto 0) <= i_theta_C(15 downto 0);  
                s_duty_C(16) <= '0';
            end if;       
        else 
            s_wr_en <= '0';
        end if;      
    end if;
    end process; 
       -- PWM out en 
       
    s_en_pwm <= i_PWM_en;   
       
    process(i_clk, i_rst_n)
    begin
    if(i_rst_n = '0') then
            o_en_PWM_VIENNA <= '0';
            o_PWMA1 <= '0';
            o_PWMA2 <= '0';
            o_PWMB1 <= '0';
            o_PWMB2 <= '0';
            o_PWMC1 <= '0';
            o_PWMC2 <= '0';   
    elsif(rising_edge(i_clk)) then
        if (s_en_pwm = '1') then
            o_en_PWM_VIENNA <= '1';
            if (i_cmd_bidir_en = '0') then
                o_PWMA1 <= s_pwm_A and (not s_duty_A(16));
                o_PWMA2 <= s_pwm_A and (s_duty_A(16));
                o_PWMB1 <= s_pwm_B and (not s_duty_B(16));
                o_PWMB2 <= s_pwm_B and (s_duty_B(16));
                o_PWMC1 <= s_pwm_C and (not s_duty_C(16));
                o_PWMC2 <= s_pwm_C and (s_duty_C(16));
            else
                o_PWMA1 <= s_pwm_A;
                o_PWMA2 <= s_pwm_A;      
                o_PWMB1 <= s_pwm_B;
                o_PWMB2 <= s_pwm_B;                     
                o_PWMC1 <= s_pwm_C;
                o_PWMC2 <= s_pwm_C;                               
            end if;
        else 
                o_en_PWM_VIENNA <= '0';
                o_PWMA1 <= '0';
                o_PWMA2 <= '0';
                o_PWMB1 <= '0';
                o_PWMB2 <= '0';
                o_PWMC1 <= '0';
                o_PWMC2 <= '0';   
        end if;      
    end if;
    end process; 

end Behavioral;
