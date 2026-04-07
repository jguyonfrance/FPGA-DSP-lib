----------------------------------------------------------------------------------
-- Company: 
-- Engineer: J.Guyon
-- 
-- Create Date: 10.09.2025 14:49:57
-- Design Name: 
-- Module Name: pulse_monostable - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Generation d'un pulse "monostable"
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


--============================================================================--
--                          DECLARATION DE L ENTITE                           --
--============================================================================--
entity PontH_16B is
  GENERIC(
      sys_clk         : INTEGER := 125_000_000; --system clock frequency in Hz
      duty_min_drivers        : INTEGER := 200; -- nb of system clock 
      bits_resolution : INTEGER := 10;          --bits of resolution setting the offset/duty cycle
      g_IMPL_ILA  : boolean := true
      );
  PORT(
      i_clk             : IN  STD_LOGIC;                                 
      i_rst_n           : IN  STD_LOGIC;  
         
      i_pont_en        : IN  STD_LOGIC;  
           
      i_freq_wr_en      : IN  STD_LOGIC;       
      i_freq            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      i_duty_wr_en    : IN  STD_LOGIC;       
      i_duty          : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);
      i_offset_wr_en  : IN  STD_LOGIC;       
      i_offset        : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);
      i_offset_sign   : IN  STD_LOGIC;

      
      o_side_A_H_en     : OUT  STD_LOGIC;
      o_side_A_L_en     : OUT  STD_LOGIC;
      o_side_B_H_en     : OUT  STD_LOGIC;
      o_side_B_L_en     : OUT  STD_LOGIC;   

      o_side_A_H_pwm    : OUT  STD_LOGIC;
      o_side_A_L_pwm    : OUT  STD_LOGIC;
      o_side_B_H_pwm    : OUT  STD_LOGIC;
      o_side_B_L_pwm    : OUT  STD_LOGIC
  
      );
end PontH_16B;

architecture Behavioral of PontH_16B is


   component ila_pontH is
   port
   (
      clk       : in  std_logic;
      probe0    : in  std_logic_vector(0 downto 0);
      probe1    : in  std_logic_vector(0 downto 0);
      probe2    : in  std_logic_vector(0 downto 0);
      probe3    : in  std_logic_vector(0 downto 0);
      
      probe4    : in  std_logic_vector(0 downto 0);
      probe5    : in  std_logic_vector(0 downto 0);
      probe6    : in  std_logic_vector(0 downto 0);
      probe7    : in  std_logic_vector(0 downto 0);
      
      probe8    : in  std_logic_vector(0 downto 0);
      probe9    : in  std_logic_vector(31 downto 0);
      probe10   : in  std_logic_vector(9 downto 0);
      probe11   : in  std_logic_vector(9 DOWNTO 0)
      
      
   );
   end component;

    --------------------------------------------------------------------------------
    -- Declaration des signaux
    --------------------------------------------------------------------------------
    
    signal s_side_A_H_pwm       : std_logic;
    signal s_side_A_L_pwm       : std_logic;
    signal s_side_B_H_pwm       : std_logic;
    signal s_side_B_L_pwm       : std_logic;
    
    signal s_offset_sign         : std_logic := '0';
    signal s_switchside_AB       : std_logic := '0'; -- '0' for side A
    
    signal  period_pwm        :  INTEGER RANGE 0 TO sys_clk := 10000;
    signal  counter_pwm       :  INTEGER RANGE 0 TO sys_clk := 0;                        
    signal  duty_pwm          :  INTEGER RANGE 0 TO sys_clk := 5000;    
    signal  duty_pwm_offset   :  INTEGER RANGE 0 TO sys_clk := 5;         
    signal  offset_pwm        :  INTEGER RANGE 0 TO sys_clk := 5;     
    
    
begin


impl_ila_ADC : if g_IMPL_ILA generate

--  process (i_clk)
--   begin
--      if rising_edge(i_clk) then
--         case s_spi_state is
--            when IDLE_ST            => s_spi_state_ila    <= "00";
--            when WAIT_CONV_ST       => s_spi_state_ila    <= "01";
--            when SCK_ST             => s_spi_state_ila    <= "10";
--            when others             => s_spi_state_ila    <= "11";
--         end case;
--     end if;
--   end process;
   
   iILA_PONTH  : ila_pontH
   port map
   (
      clk         => i_clk           ,
      probe0(0)   => i_pont_en       ,
      probe1(0)   => i_freq_wr_en       ,
      probe2(0)   => i_duty_wr_en       ,
      probe3(0)   => i_offset_wr_en     ,
      probe4(0)   => s_switchside_AB    ,
      probe5(0)   => s_side_A_L_pwm     ,
      probe6(0)   => s_side_A_H_pwm     ,
      probe7(0)  => s_side_B_L_pwm     ,
      probe8(0)  => s_side_B_H_pwm     ,
      probe9     => i_freq          ,
      probe10    => i_duty          ,
      probe11    => i_offset  
   );
end generate impl_ila_ADC;


   -----------------------------------------------------------------------------
   -- output meta/en
   -----------------------------------------------------------------------------
    process(i_clk)
    begin
    if(rising_edge(i_clk)) then
        if( i_pont_en = '1') then 
            o_side_A_H_en <= '1';
            o_side_A_L_en <= '1'; 
            if (s_side_A_L_pwm = '1') then
                o_side_A_H_pwm <= '0';
                o_side_A_L_pwm <= '1';
            else
                o_side_A_H_pwm <= s_side_A_H_pwm;
                o_side_A_L_pwm <= '0';            
            end if; 
            
            o_side_B_H_en <= '1';
            o_side_B_L_en <= '1'; 
            if (s_side_B_L_pwm = '1') then
                o_side_B_H_pwm <= '0';
                o_side_B_L_pwm <= '1';
            else
                o_side_B_H_pwm <= s_side_B_H_pwm;
                o_side_B_L_pwm <= '0';            
            end if; 
            
        else
            o_side_A_H_en <= '0';
            o_side_A_L_en <= '0';
            o_side_A_H_pwm <= '0';
            o_side_A_L_pwm <= '0';
            
            o_side_B_H_en <= '0';
            o_side_B_L_en <= '0';
            o_side_B_H_pwm <= '0';
            o_side_B_L_pwm <= '0';
        end if; 
         
         
     end if;
    end process;


   
   process(i_clk)
   begin
      if(i_rst_n = '0') then
    
        s_side_A_H_pwm <= '0';
        s_side_A_L_pwm <= '0';
        s_side_B_H_pwm <= '0';
        s_side_B_L_pwm <= '0';
        s_switchside_AB <= '0';
        
      elsif rising_edge(i_clk) then        
        if (i_freq_wr_en = '1') then
            period_pwm <= sys_clk/((conv_integer(i_freq)*2));
        end if; 
        if (i_duty_wr_en = '1') then
             duty_pwm <= period_pwm - (conv_integer(i_duty)*period_pwm/(2**bits_resolution) - duty_min_drivers);
        end if;
        if (i_offset_wr_en = '1') then
             offset_pwm <= conv_integer(i_offset)*period_pwm/(2**bits_resolution);
             s_offset_sign <= i_offset_sign;
        end if;        
                                           
        if(i_pont_en = '1') then 
            if(counter_pwm = period_pwm - 1 ) then    
              counter_pwm <= 0;   
              s_switchside_AB <= not s_switchside_AB;                                         
            else                                                     
              counter_pwm <= counter_pwm + 1;                                     
            end if;   

            if (s_switchside_AB = '0') then
                s_side_B_H_pwm <= '0';
                s_side_B_L_pwm <= '1';
                
                if(s_offset_sign = '1') then    
                    duty_pwm_offset <= duty_pwm + offset_pwm;
                else
                    duty_pwm_offset <= duty_pwm - offset_pwm;
                end if;
                
                if(counter_pwm < duty_min_drivers) then    
                    s_side_A_H_pwm <= '0';
                    s_side_A_L_pwm <= '0';
                else
                    if(counter_pwm >= (duty_pwm_offset + duty_min_drivers)) then    
                        s_side_A_H_pwm <= '1';
                    else 
                        s_side_A_H_pwm <= '0';
                    end if;
                    if(counter_pwm >= duty_pwm_offset) then    
                        s_side_A_L_pwm <= '0';
                    else 
                        s_side_A_L_pwm <= '1';
                    end if;
                end if; 
            else
                s_side_A_H_pwm <= '1';
                s_side_A_L_pwm <= '0';
                
                if(s_offset_sign = '0') then    
                    duty_pwm_offset <= duty_pwm + offset_pwm;
                else
                    duty_pwm_offset <= duty_pwm - offset_pwm;
                end if;
                
                if(counter_pwm < duty_min_drivers) then    
                    s_side_B_H_pwm <= '0';
                    s_side_B_L_pwm <= '0';
                else
                    if(counter_pwm >= (duty_pwm_offset + duty_min_drivers)) then    
                        s_side_B_H_pwm <= '1';
                    else 
                        s_side_B_H_pwm <= '0';
                    end if;
                    if(counter_pwm >= duty_pwm_offset) then    
                        s_side_B_L_pwm <= '0';
                    else 
                        s_side_B_L_pwm <= '1';
                    end if;
                end if;         
            end if; 
            
                
        else
            counter_pwm <= 0;
            s_switchside_AB <= '0';
            s_side_B_H_pwm <= '0';
            s_side_B_L_pwm <= '0';       
        end if;
        
        


     end if;
   end process;

end Behavioral;
