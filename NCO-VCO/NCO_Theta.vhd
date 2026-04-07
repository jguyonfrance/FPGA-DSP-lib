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
   use IEEE.std_logic_signed.all;

library xil_defaultlib;
   use xil_defaultlib.all;
Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity NCO_Theta is
  GENERIC(
      PHASE_INC_CPT: integer := 128
      );
  PORT(
      i_clk           : IN  STD_LOGIC;                           
      i_rst_n         : IN  STD_LOGIC;                               
      i_ena           : IN  STD_LOGIC;                              
      i_freq          : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      i_freq_min      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      i_freq_max      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_Theta         : OUT  signed(15 downto 0) --Q16.13
      );
end NCO_Theta;

architecture Behavioral of NCO_Theta is

constant  c_2PI_POS: signed(23 downto 0) := X"00c910"; --Q24.13
constant  c_2PI_NEG: signed(23 downto 0) := X"ff36f0"; --Q24.13



constant  c_PI_POS: signed(15 downto 0) := X"6488";--Q16.13
constant  c_PI_NEG: signed(15 downto 0) := X"9b78";--Q16.13
constant  c_DEG120: signed(15 downto 0) := X"4305";--Q16.13

signal s_phase_cmd_cordic: signed(23 downto 0) := (others => '0');
signal s_phase_cmd_vect: signed(23 downto 0) := (others => '0');

signal s_clk_pulse_cordic : std_logic := '0';
signal s_cpt_clk_cordic : STD_LOGIC_VECTOR(31 DOWNTO 0); 


begin

process(i_clk)
begin              
 if(i_rst_n = '0') then
         s_cpt_clk_cordic <= (others => '0');
 elsif rising_edge(i_clk) then
    if(s_cpt_clk_cordic = (not i_freq)) then
         s_cpt_clk_cordic <= (others => '0');
         s_clk_pulse_cordic <= '1';
    else
         s_cpt_clk_cordic <= s_cpt_clk_cordic + x"1";
         s_clk_pulse_cordic <= '0';
    end if;  
 end if;
end process;
    
    o_Theta <= s_phase_cmd_vect(15 DOWNTO 0);    

   p_nco_0 : process(i_clk, i_rst_n)
   begin
        if(i_rst_n = '0') then
            s_phase_cmd_vect <= (others => '0');
        elsif rising_edge(i_clk) then

            if(i_ena = '1') then
                if(s_clk_pulse_cordic = '1') then
                    if (s_phase_cmd_cordic + PHASE_INC_CPT < c_2PI_POS) then 
                        s_phase_cmd_cordic <= s_phase_cmd_cordic + PHASE_INC_CPT;
                    else 
                        s_phase_cmd_cordic <= (others => '0');
                    end if;
                    s_phase_cmd_vect <= s_phase_cmd_cordic - c_PI_POS;
                end if; 
            end if; 
        end if;
   end process p_nco_0;

end Behavioral;

