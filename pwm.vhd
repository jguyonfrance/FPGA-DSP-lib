----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.09.2025 14:51:37
-- Design Name: 
-- Module Name: pwm - Behavioral
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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY mod_pwm IS 
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
END mod_pwm;

ARCHITECTURE Behavioral OF mod_pwm IS
  SIGNAL  s_period     :  INTEGER RANGE 0 TO  sys_clk:= 0;
  TYPE counters IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO sys_clk - 1;  --data type for array of period counters
  SIGNAL  count        :  counters := (OTHERS => 0);                        --array of period counters
  SIGNAL   half_duty_new  :  INTEGER RANGE 0 TO sys_clk/2 := 0;              --number of clocks in 1/2 duty cycle
  TYPE half_duties IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO sys_clk/2; --data type for array of half duty values
  SIGNAL  half_duty    :  half_duties := (OTHERS => 0);                     --array of half duty values (for each phase)
BEGIN
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                                                 --asynchronous reset
      count <= (OTHERS => 0);                                                --clear counter
      pwm_out <= (OTHERS => '0');                                            --clear pwm outputs
      pwm_n_out <= (OTHERS => '0');                                          --clear pwm inverse outputs
      s_period <= sys_clk/conv_integer(pwm_freq); 
    ELSIF(clk'EVENT AND clk = '1') THEN                                      --rising system clock edge
      s_period <= sys_clk/conv_integer(pwm_freq); 
      IF(ena = '1') THEN                                                   --latch in new duty cycle
        half_duty_new <= conv_integer(duty)*s_period/(2**bits_resolution)/2;   --determine clocks in 1/2 duty cycle
      END IF;
      FOR i IN 0 to phases-1 LOOP                                            --create a counter for each phase
        IF(count(0) = s_period - 1 - i*s_period/phases) THEN                       --end of period reached
          count(i) <= 0;                                                         --reset counter
          half_duty(i) <= half_duty_new;                                         --set most recent duty cycle value
        ELSE                                                                   --end of period not reached
          count(i) <= count(i) + 1;                                              --increment counter
        END IF;
      END LOOP;
      FOR i IN 0 to phases-1 LOOP                                            --control outputs for each phase
        IF(count(i) = half_duty(i)) THEN                                       --phase's falling edge reached
          pwm_out(i) <= '0';                                                     --deassert the pwm output
          pwm_n_out(i) <= '1';                                                   --assert the pwm inverse output
        ELSIF(count(i) = s_period - half_duty(i)) THEN                           --phase's rising edge reached
          pwm_out(i) <= '1';                                                     --assert the pwm output
          pwm_n_out(i) <= '0';                                                   --deassert the pwm inverse output
        END IF;
      END LOOP;
    END IF;
  END PROCESS;
  
END Behavioral;
