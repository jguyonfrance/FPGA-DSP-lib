----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.01.2025 11:47:15
-- Design Name: 
-- Module Name: tb_adc - Behavioral
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

entity tb_adc is
--  Port ( );
end tb_adc;

architecture Behavioral of tb_adc is

constant  CORDIC_PERIOD: time := 2500ps;
constant  FIR_PERIOD: time := 12500ps;
constant  PI_POS: signed(15downto 0) := X"6488";
constant  PI_NEG: signed(15downto 0) := X"9878";
constant  PHASE_INC_2Mhz: integer := 200;
constant  PHASE_INC_30Mhz: integer := 3000;




component adc_filter is
PORT( 
    i_clk   	: IN STD_LOGIC;
    i_rst   	: IN STD_LOGIC;    
    o_done      : OUT STD_LOGIC;
    i_adc_data  : IN SIGNED(15 DOWNTO 0);
    o_filtered_adc_data : OUT SIGNED(15 DOWNTO 0)
);
end component;

signal cordic_clk: std_logic := '0';
signal fir_clk: std_logic := '0';
signal phase_tvalid: std_logic := '0';
signal phase_2MHz: signed(15 downto 0) := (others => '0');
signal phase_30MHz: signed(15 downto 0) := (others => '0');
signal sincos_2MHz_tvalid: std_logic := '0';
signal sin_2Mhz, cos_2MHz: std_logic_vector(15 downto 0);
signal sincos_30MHz_tvalid: std_logic := '0';
signal sin_30Mhz, cos_30MHz: std_logic_vector(15 downto 0);
signal noisy_signal: signed(15 downto 0);
signal filtered_signal: std_logic_vector(23 downto 0);




begin


	rst 	<= '1', '0' after 30 ns;
	clk   <= not clk after 20 ns;
	cordic_clk   <= not cordic_clk after CORDIC_PERIOD;
	fir_clk   <= not fir_clk after FIR_PERIOD;
	
	
cordic_inst_0: entity work.cordic_0
 port map (
	aclk		=> cordic_clk,
	s_axis_phase_tvalid		=> phase_tvalid,
	s_axis_phase_tdata		=> std_logic_vector(phase_2MHz),
	m_axis_dout_tvalid		=> sincos_2MHz_tvalid,
	m_axis_dout_tdata(31 downto 16)		=> sin_2Mhz,
	m_axis_dout_tdata(15 downto 0)		=> cos_2MHz
);

cordic_inst_1: entity work.cordic_0
 port map (
	aclk		=> cordic_clk,
	s_axis_phase_tvalid		=> phase_tvalid,
	s_axis_phase_tdata		=> std_logic_vector(phase_30MHz),
	m_axis_dout_tvalid		=> sincos_30MHz_tvalid,
	m_axis_dout_tdata(31 downto 16)		=> sin_30Mhz,
	m_axis_dout_tdata(15 downto 0)		=> cos_30MHz
);

process (cordic_clk)
begin 
	if rising_edge(cordic_clk) then 
		phase_tvalid <= '1';
		
		if (phase_2MHz + PHASE_INC_2MHZ < PI_POS) then 
			phase_2MHz <= phase_2MHz + PHASE_INC_2MHZ;
		else 
			phase_2MHz <= PI_NEG + (phase_2MHz+PHASE_INC_2MHZ - PI_POS);
		end if;
		
		if (phase_30MHz + PHASE_INC_30MHZ < PI_POS) then 
			phase_30MHz <= phase_30MHz + PHASE_INC_30MHZ;
		else 
			phase_30MHz <= PI_NEG + (phase_30MHz+PHASE_INC_30MHZ - PI_POS);
		end if;
	end if;
	
	
end process;

process (fir_clk)
begin 
	if rising_edge(fir_clk) then 
		noisy_signal <= (signed(sin_2MHz) + signed(sin_30MHz))/2;
	end if;
end process;

	UUT : filter_FIR8
	port map(
		i_clk   	=> fir_clk,
		i_rst   	=> rst,
		i_adc_data  => noisy_signal,
		o_done        => OPEN,
		o_filtered_adc_data    => filtered_signal
  );

   
end Behavioral;

