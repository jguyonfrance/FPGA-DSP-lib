----------------------------------------------------------------------------------
-- Company: MGDK-BRAIN
-- Engineer: J.Guyon
-- 
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
   use IEEE.std_logic_unsigned.all;
   use IEEE.std_logic_arith.all;

library xil_defaultlib;
   use xil_defaultlib.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity NCO_BF is
  GENERIC(
      PHASE_INC_CPT: integer := 512
      );
  PORT(
      i_clk           : IN  STD_LOGIC;                           
      i_rst_n         : IN  STD_LOGIC;                               
      i_ena           : IN  STD_LOGIC;                              
      i_freq          : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      o_sincos_U_tvalid   : OUT  STD_LOGIC;      
      o_cos_U           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0); 
      o_sin_U           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
      o_sincos_V_tvalid   : OUT  STD_LOGIC;                              
      o_cos_V           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0); 
      o_sin_V           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);   
      o_sincos_W_tvalid   : OUT  STD_LOGIC;        
      o_cos_W           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0); 
      o_sin_W           : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0)      
      );
end NCO_BF;

architecture Behavioral of NCO_BF is


constant  c_2PI_POS: signed(23 downto 0) := X"00c910"; --Q24.13
constant  c_2PI_NEG: signed(23 downto 0) := X"ff36f0"; --Q24.13



constant  c_PI_POS: signed(15 downto 0) := X"6488";--Q16.13
constant  c_PI_NEG: signed(15 downto 0) := X"9b78";--Q16.13
constant  c_DEG120: signed(15 downto 0) := X"4305";--Q16.13

signal s_phase_cmd_cordic: signed(23 downto 0) := (others => '0');
signal s_phase_cmd_vect_U: signed(23 downto 0) := (others => '0');
signal s_phase_cmd_vect_V: signed(23 downto 0) := (others => '0');
signal s_phase_cmd_vect_W: signed(23 downto 0) := (others => '0');


signal s_phase_cmd_cordic_U: signed(15 downto 0) := (others => '0');
signal s_phase_cmd_cordic_U_tvalid: std_logic := '0';
signal s_phase_cmd_cordic_V: signed(15 downto 0) := (others => '0');
signal s_phase_cmd_cordic_V_tvalid: std_logic := '0';
signal s_phase_cmd_cordic_W: signed(15 downto 0) := (others => '0');
signal s_phase_cmd_cordic_W_tvalid: std_logic := '0';


signal s_sincos_U_tvalid: std_logic := '0';
signal s_sincos_V_tvalid: std_logic := '0';
signal s_sincos_W_tvalid: std_logic := '0';


signal s_sin_U, s_cos_U: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal s_sin_V, s_cos_V: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal s_sin_W, s_cos_W: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

signal s_clk_pulse_cordic : std_logic := '0';
signal s_cpt_clk_cordic : STD_LOGIC_VECTOR(15 DOWNTO 0); 


begin


cordic_inst_U: entity work.cordic_0
 port map (
	aclk		=> i_clk,
	s_axis_phase_tvalid		=> s_phase_cmd_cordic_U_tvalid,
	s_axis_phase_tdata		=> std_logic_vector(s_phase_cmd_cordic_U),
	m_axis_dout_tvalid		=> s_sincos_U_tvalid,
	m_axis_dout_tdata(31 downto 16)		=> s_sin_U,
	m_axis_dout_tdata(15 downto 0)		=> s_cos_U
);
cordic_inst_V: entity work.cordic_0
 port map (
	aclk		=> i_clk,
	s_axis_phase_tvalid		=> s_phase_cmd_cordic_V_tvalid,
	s_axis_phase_tdata		=> std_logic_vector(s_phase_cmd_cordic_V),
	m_axis_dout_tvalid		=> s_sincos_V_tvalid,
	m_axis_dout_tdata(31 downto 16)		=> s_sin_V,
	m_axis_dout_tdata(15 downto 0)		=> s_cos_V
);
cordic_inst_W: entity work.cordic_0
 port map (
	aclk		=> i_clk,
	s_axis_phase_tvalid		=> s_phase_cmd_cordic_W_tvalid,
	s_axis_phase_tdata		=> std_logic_vector(s_phase_cmd_cordic_W),
	m_axis_dout_tvalid		=> s_sincos_W_tvalid,
	m_axis_dout_tdata(31 downto 16)		=> s_sin_W,
	m_axis_dout_tdata(15 downto 0)		=> s_cos_W
);
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


   p_nco_0 : process(i_clk, i_rst_n)
   begin
        if(i_rst_n = '0') then
            o_sin_U <= (others => '0');
            o_cos_U <= (others => '0');
            o_sin_V <= (others => '0');
            o_cos_V <= (others => '0');
            o_sin_W <= (others => '0');
            o_cos_W <= (others => '0');
            
            
            
            s_phase_cmd_cordic_U_tvalid <= '0';
            
            o_sincos_U_tvalid <= '0';
            s_phase_cmd_cordic_U <= (others => '0');
            o_sincos_V_tvalid <= '0';
            s_phase_cmd_cordic_V <= (others => '0');           
            o_sincos_W_tvalid <= '0';
            s_phase_cmd_cordic_W <= (others => '0');            
            
        elsif rising_edge(i_clk) then

            if(i_ena = '1') then
                o_sincos_U_tvalid <= s_sincos_U_tvalid;
                o_sin_U <= s_sin_U;
                o_cos_U <= s_cos_U;
                o_sincos_V_tvalid <= s_sincos_V_tvalid;
                o_sin_V <= s_sin_V;
                o_cos_V <= s_cos_V;
                o_sincos_W_tvalid <= s_sincos_W_tvalid;
                o_sin_W <= s_sin_W;
                o_cos_W <= s_cos_W;
                
                s_phase_cmd_cordic_U_tvalid <= '1';
                
                if(s_clk_pulse_cordic = '1') then
                    if (s_phase_cmd_cordic + PHASE_INC_CPT < c_2PI_POS) then 
                        s_phase_cmd_cordic <= s_phase_cmd_cordic + PHASE_INC_CPT;
                    else 
                        s_phase_cmd_cordic <= (others => '0');
                    end if;
                    
                    s_phase_cmd_vect_U <= s_phase_cmd_cordic - c_PI_POS;
                    
                    if ((s_phase_cmd_cordic + c_DEG120) > c_2PI_POS) then 
                        s_phase_cmd_vect_V <= ((s_phase_cmd_cordic + c_DEG120) - c_2PI_POS - c_PI_POS);
                    else 
                        s_phase_cmd_vect_V <= (s_phase_cmd_cordic + c_DEG120)-c_PI_POS;                 
                    end if; 
                                    
                    if ((s_phase_cmd_cordic - c_DEG120) < 0) then 
                        s_phase_cmd_vect_W <= ((s_phase_cmd_cordic - c_DEG120) + c_2PI_POS - c_PI_POS);
                    else 
                        s_phase_cmd_vect_W <= (s_phase_cmd_cordic - c_DEG120)-c_PI_POS;                 
                    end if;  
                    
                    s_phase_cmd_cordic_U <= s_phase_cmd_vect_U(15 DOWNTO 0);
                    s_phase_cmd_cordic_V <= s_phase_cmd_vect_V(15 DOWNTO 0);
                    s_phase_cmd_cordic_W <= s_phase_cmd_vect_W(15 DOWNTO 0);                
                    
                end if; 
            else            
                        o_sin_U <= (others => '0');
                        o_cos_U <= (others => '0');
                        o_sin_V <= (others => '0');
                        o_cos_V <= (others => '0');
                        o_sin_W <= (others => '0');
                        o_cos_W <= (others => '0');
                        
                        s_phase_cmd_cordic_U_tvalid <= '0';
                        
                        o_sincos_U_tvalid <= '0';
                        s_phase_cmd_cordic_U <= (others => '0');
                        o_sincos_V_tvalid <= '0';
                        s_phase_cmd_cordic_V <= (others => '0');           
                        o_sincos_W_tvalid <= '0';
                        s_phase_cmd_cordic_W <= (others => '0');            
            end if; 
        end if;
   end process p_nco_0;

end Behavioral;
