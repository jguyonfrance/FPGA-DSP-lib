----------------------------------------------------------------------------------
-- Company: MGDK-BRAin
-- Engineer: J.Guyon
-- 
-- Create Date: 03.01.2025 14:00:00
-- Design Name: 
-- Module Name:
-- Project Name: 
-- Target Devices: 
-- tool Versions: 
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

Library UNisIM;
use UNisIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


ENTITY mod_pwm is 
  GENERIC(
      sys_clk         : integer := 125_000_000; --system clock frequency in Hz
      pwm_freq        : integer := 80_000;      --PWM switching frequency in Hz
      bits_resolution : integer := 16;          --bits of resolution setting the duty cycle
      phases          : integer := 1);          --number of output pwms 
  PORT(
      clk       : in  std_logic;                                    --system clock
      reset_n   : in  std_logic;                                    --asynchronous reset
      ena       : in  std_logic;                                    --latches in new duty cycle
      duty      : in  std_logic_vector(bits_resolution-1 DOWNto 0); --duty cycle
      pwm_out   : out std_logic_vector(phases-1 DOWNto 0);          --pwm outputs
      pwm_n_out : out std_logic_vector(phases-1 DOWNto 0));         --pwm inverse outputs
end mod_pwm;

architecture Behavioral of mod_pwm is
  constant  c_period     :  integer := sys_clk/pwm_freq;                  
  type counters is array (0 to phases-1) of integer range 0 to c_period - 1; 
  signal  s_count        :  counters := (others => 0);                     
  signal  s_half_duty_new  :  integer range 0 to c_period/2 := 0;         
  type half_duties is array (0 to phases-1) of integer range 0 to c_period/2; 
  signal  s_half_duty    :  half_duties := (others => 0);                    
begin
  process(clk, reset_n)
  begin
    if(reset_n = '0') then                                           
      s_count     <= (others => 0);                              
      pwm_out   <= (others => '0');                                     
      pwm_n_out <= (others => '0');                                    
    elsif rising_edge(i_clk) then
      if(ena = '1') then                                                    
        s_half_duty_new <= conv_integer(duty)*c_period/(2**bits_resolution)/2; 
      end if;
      for i in 0 to phases-1 loop                                         
        if(s_count(0) = c_period - 1 - i*c_period/phases) then                 
          s_count(i)     <= 0;                                         
          s_half_duty(i) <= s_half_duty_new;                                  
        ELSE                                                                
          s_count(i) <= s_count(i) + 1;                                         
        end if;
      end loop;
      for i in 0 to phases-1 loop                                       
        if(s_count(i) = s_half_duty(i)) then                              
          pwm_out(i)   <= '0';                                      
          pwm_n_out(i) <= '1';
        elsif(s_count(i) = c_period - s_half_duty(i)) then
          pwm_out(i)   <= '1';
          pwm_n_out(i) <= '0';
        end if;
      end loop;
    end if;
  end process;
  
end Behavioral;
