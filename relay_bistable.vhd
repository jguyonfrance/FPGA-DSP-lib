----------------------------------------------------------------------------------
-- Company: 
-- Engineer: J.Guyon
-- https://github.com/jguyonfrance
-- Create Date: 10.09.2025 14:49:57
-- Design Name: 
-- Module Name: relay_bistable - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Generation d'un pulse "monostable" pour commande ralais bistable
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


entity relay_bistable is
  GENERIC(
      CLK_DIV_1mS_g        : std_logic_vector(31 downto 0)      := x"0001E848"; -- CLK 125MHz
      CPT_1mS_TON          : std_logic_vector(15 downto 0)      := x"02BC"; -- 700ms
      CPT_1mS_TOFF         : std_logic_vector(15 downto 0)      := x"0032" -- 50ms
      );
  PORT(
      i_clk           : IN  STD_LOGIC;                                    --system clock
      i_rst_n         : IN  STD_LOGIC;                                    --asynchronous reset
      i_cmd_on        : IN  STD_LOGIC;              
      o_state_relay   : OUT STD_LOGIC;        
      o_relay_A       : OUT STD_LOGIC;        
      o_relay_B       : OUT STD_LOGIC        
      );
end relay_bistable;

architecture Behavioral of relay_bistable is
    --------------------------------------------------------------------------------
    -- Declaration des signaux
    --------------------------------------------------------------------------------
    signal s_cpt_clk_1m          : std_logic_vector(31 downto 0) := (others=>'0');
    signal s_TC_CPT_1us          : std_logic;
    signal s_TC_CPT_1us_reg      : std_logic;
    signal s_PULSE_1us           : std_logic;
    
    signal s_CPT_Ton             : std_logic_vector(15 downto 0) := (others=>'0');
    signal s_TC_CPT_Ton          : std_logic;
    signal s_CPT_Toff            : std_logic_vector(15 downto 0) := (others=>'0');
    
    signal s_pulse_en            : std_logic;
    
    signal s_state_relay            : std_logic;

    signal s_cmd_on,s_cmd_on_r   : std_logic;

begin

   -----------------------------------------------------------------------------
   -- Compteur 1 ms
   -----------------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
          if(i_rst_n = '0') then
          
          elsif(rising_edge(i_clk)) then
                if(s_cpt_clk_1m = CLK_DIV_1mS_g) then
                     s_cpt_clk_1m <= (others => '0');
                     s_TC_CPT_1us <= '1';
                else
                     s_cpt_clk_1m <= s_cpt_clk_1m + x"1";
                     s_TC_CPT_1us <= '0';
                end if;  
           end if;
    end process; 

                       
o_state_relay <= s_state_relay;
s_cmd_on <= i_cmd_on;

   process(i_clk)
   begin
      if(i_rst_n = '0') then
         s_CPT_Ton <=  (others=>'0');
         s_pulse_en <= '0';
      elsif rising_edge(i_clk) then 
         s_cmd_on_r <= s_cmd_on;
         s_pulse_en <= s_cmd_on_r xor s_cmd_on;
         if (s_pulse_en='1') then
               s_CPT_Ton   <= (others=>'0');
               s_state_relay <= s_cmd_on;
         end if; 
              
         if (s_TC_CPT_1us='1') then
         
                if (s_CPT_Toff < CPT_1mS_TOFF) then
                   s_CPT_Toff  <= s_CPT_Toff +1;
                   o_relay_A <= '0';
                   o_relay_B <= '0';
                else
                    if (s_CPT_Ton < CPT_1mS_TON) then
                       s_CPT_Ton  <= s_CPT_Ton +1;
                       o_relay_A <= s_state_relay;
                       o_relay_B <= not s_state_relay;
                       s_CPT_Toff  <= (others=>'0');
                    end if;                   
                end if;
                

        end if;
      end if;
   end process;
   
end Behavioral;