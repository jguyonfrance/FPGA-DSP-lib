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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use IEEE.std_logic_signed.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_cordic is
--  Port ( );
end tb_cordic;

architecture Behavioral of tb_cordic is

constant  CORDIC_PERIOD: time := 4ns;
constant  FIR_PERIOD: time := 8ns;
constant  PI_POS: signed(15downto 0) := X"6488";
constant  PI_NEG: signed(15downto 0) := X"9b78";
constant  PHASE_INC_2Mhz: integer := 1;
constant  PHASE_INC_30Mhz: integer := 3000;

component NCO_BF 
  GENERIC(
      PHASE_INC_CPT         : INTEGER := 512 -- Hz 
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
    end component; 
    
component Transform_CLARK_Triphase
  port( 
    i_clk           : IN  STD_LOGIC;                           
    i_rst_n         : IN  STD_LOGIC;     
    i_Ua			: in signed(31 downto 0);   --Q15.16
    i_Ub			: in signed(31 downto 0);   --Q15.16
    i_Uc			: in signed(31 downto 0);   --Q15.16
	i_datavalid		: in std_logic;
    
    o_Alpha   	    : out signed(31 downto 0);   --Q15.16
    o_Beta    	    : out signed(31 downto 0);   --Q15.16
	o_datavalid 	: out std_logic
  );
end component; 
    
    
signal cordic_clk: std_logic := '0';

signal sin_nco_u, cos_nco_u: std_logic_vector(15 downto 0);
signal sin_nco_v, cos_nco_v: std_logic_vector(15 downto 0);
signal sin_nco_w, cos_nco_w: std_logic_vector(15 downto 0);

signal sin_Ua, sin_Ub, sin_Uc: std_logic_vector(31 downto 0);



  signal rst      	: std_logic;
  signal rst_n      	: std_logic;
  signal clk        : std_logic := '0';
  signal data       : std_logic_vector(7 downto 0);
  signal data_val   : std_logic := '0';
  signal cpt       	: std_logic_vector(7 downto 0);

begin


	rst 	<= '1', '0' after 30 ns;
	clk   <= not clk after 20 ns;
	cordic_clk   <= not cordic_clk after CORDIC_PERIOD;
	
    PROCESS(clk)
        BEGIN 
            if(rising_edge(clk)) then
                if(rst = '1') then
                    data     	<= (others => '0');
					cpt <= (others => '0'); 
                else
                    if(cpt = X"7D")then    
						data_val    <= '1';
                    else
						data_val    <= '0';
                    end if;                    
                end if;
            end if;
    end process;
	
rst_n <= not rst;
	
UUT_test : NCO_BF
    generic map(
       PHASE_INC_CPT   => 512 -- Hz 
    )    
   port map (
      i_clk            => cordic_clk,                          
      i_rst_n         => rst_n,                            
      i_ena            => '1',                             
      i_freq           => X"DED8", --60Hz AF0B 50 9ED8 25 3DB7
      o_sincos_u_tvalid  => open,                 
      o_cos_u           => cos_nco_u,
      o_sin_u          => sin_nco_u,
      o_sincos_v_tvalid  => open,                 
      o_cos_v           => cos_nco_v,
      o_sin_v          => sin_nco_v,
      o_sincos_w_tvalid  => open,                 
      o_cos_w          => cos_nco_w,
      o_sin_w          => sin_nco_w 
      
      
      
      );
	
sin_Ua(31 downto 17) <= (others => sin_nco_u(15));
sin_Ua(16 downto 2) <= sin_nco_u(14 downto 0);
sin_Ua(1 downto 0) <= (others => '0');

sin_Ub(31 downto 17) <= (others => sin_nco_v(15));
sin_Ub(16 downto 2) <= sin_nco_v(14 downto 0);
sin_Ub(1 downto 0) <= (others => '0');

sin_Uc(31 downto 17) <= (others => sin_nco_w(15));
sin_Uc(16 downto 2) <= sin_nco_w(14 downto 0);
sin_Uc(1 downto 0) <= (others => '0');


UUT_test_2 : Transform_CLARK_Triphase
   port map (
        i_clk           => cordic_clk,                          
        i_rst_n         => rst_n,    
        i_Ua			=> signed(sin_Ua),
        i_Ub			=> signed(sin_Ub),
        i_Uc			=> signed(sin_Uc),
        i_datavalid		=> '1',
        o_Alpha   	    => open,
        o_Beta    	    => open,
        o_datavalid 	=> open 
  );



end Behavioral;
