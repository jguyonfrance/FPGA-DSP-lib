----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.05.2016 17:26:37
-- Design Name: 
-- Module Name: rgmii_rx - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity rgmii_rx is
    Port ( rx_clk           : in  STD_LOGIC;
           rx_ctl           : in  STD_LOGIC;
           rx_data          : in  STD_LOGIC_VECTOR (3 downto 0);
           link_10mb        : out STD_LOGIC;
           link_100mb       : out STD_LOGIC;
           link_1000mb      : out STD_LOGIC;
           link_full_duplex : out STD_LOGIC;
           data             : out STD_LOGIC_VECTOR (7 downto 0);
           data_valid       : out STD_LOGIC;
           data_enable      : out STD_LOGIC;
           data_error       : out STD_LOGIC;
		   clk_out          : out STD_LOGIC);

end rgmii_rx;

architecture Behavioral of rgmii_rx is
    signal raw_ctl  : std_logic_vector(1 downto 0);
    signal raw_data : std_logic_vector(7 downto 0) := (others => '0');


   component ddr_rx                             
      port
      (
		clkin	: in  	STD_LOGIC; 
		reset	: in  	STD_LOGIC; 
		sclk	: out  	STD_LOGIC; 
		datain	: in 	STD_LOGIC_VECTOR (3 downto 0);
		q		: out 	STD_LOGIC_VECTOR (7 downto 0)
	   );
   end component;


begin


   rx_d_phy : ddr_rx
   port map (
      clkin   	=> rx_clk,
	  reset   	=> '1',
      sclk   	=> clk_out,
	  datain(3 downto 0) => rx_data,
      q(7 downto 0) => raw_data
	  
	  
   );
   
   
process(rx_clk) 
    begin
        if rising_edge(rx_clk) then
            data_valid <= raw_ctl(0);
            data_error <= raw_ctl(0) XOR raw_ctl(1);
            data       <= raw_data;
            -- check for inter-frame with matching upper and lower nibble
            if raw_ctl = "00"  and raw_data(3 downto 0) = raw_data(7 downto 4) then
                link_10mb        <= '0';
                link_100mb       <= '0';
                link_1000mb      <= '0';
                link_full_duplex <= '0';
                case raw_data(2 downto 0) is
                    when "001" => link_10mb   <= '1'; link_full_duplex <= raw_data(3);
                    when "011" => link_100mb  <= '1'; link_full_duplex <= raw_data(3);
                    when "101" => link_1000mb <= '1'; link_full_duplex <= raw_data(3);
                    when others => NULL;
                end case;
            end if; 
        end if;
    end process;
end Behavioral;

