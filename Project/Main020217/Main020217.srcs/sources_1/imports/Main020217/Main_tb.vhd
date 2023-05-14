LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library std ;
use std.textio.all;
--------------------------------------
ENTITY Main_tb IS
END Main_tb;
--------------------------------------
ARCHITECTURE behavior OF Main_tb IS
	COMPONENT Main
	PORT(
		Clk : IN  std_logic;
		Rst : IN  std_logic;
		RXD : IN  std_logic;
		TXD : OUT  std_logic;
		LED : OUT  std_logic_vector(2 downto 0)
	  );
	END COMPONENT;
	component Receiver
		generic (Freq: integer :=100000000; Baud: integer :=115200);
		port (Clk,Rst,Start,RXD: in std_logic;
			Parity:	in	std_logic_vector(1 downto 0);--10,11 for no parity, 00 for even parity and 01 for odd parity
			Busy,Rdy,Error: out	std_logic;
			Dout:	out	std_logic_vector(7 downto 0));
	end component;
	component Transmitter
		generic (Freq: integer :=100000000; Baud: integer :=115200);
		port (Clk,Rst,Start: in std_logic;
			Parity:	in	std_logic_vector(1 downto 0);--10,11 for no parity, 00 for even parity and 01 for odd parity
			Din:	in	std_logic_vector(7 downto 0);
			Busy,TXD: out	std_logic);
	end component;
	--Inputs
	signal Clk : std_logic := '0';
	signal Rst : std_logic := '0';
	signal RXD : std_logic := '0';
	--Outputs
	signal TXD : std_logic;
	signal LED : std_logic_vector(2 downto 0);
	-- Clock period definitions
	constant Clk_period : time := 10 ns;
	------------------------------------
	signal	RX_Start,RX_Error,RX_Busy,Rx_Rdy,Tx_Start,TX_Busy:	std_logic;
	signal	Rx_Data,Tx_Data:	std_logic_vector(7 downto 0);
	constant   Freq:	integer:=100000000;
	constant   Baud:	integer:=115200;
	constant   Parity: std_logic_vector(1 downto 0):="00";
BEGIN
	-- Instantiate the Unit Under Test (UUT)
	uut: Main PORT MAP (Clk => Clk,Rst => Rst,RXD => RXD,TXD => TXD,LED => LED);
	URX:	Receiver   
			generic map(Freq=>Freq,Baud=>Baud)
			port map(Rst=>Rst,Clk=>Clk,Parity=>Parity,RXD=>TXD,Start=>RX_Start,Error=>RX_Error,Busy=>RX_Busy,Rdy=>Rx_Rdy,Dout=>Rx_Data);
	UTX:	Transmitter   
			generic map(Freq=>Freq,Baud=>Baud)
			port map(Rst=>Rst,Clk=>Clk,Parity=>Parity,TXD=>RXD,Start=>Tx_Start,Busy=>TX_Busy,Din=>Tx_Data);
	-- Clock process definitions
	Clk_process :process
	begin
		Clk <= '0';
		wait for Clk_period/2;
		Clk <= '1';
		wait for Clk_period/2;
	end process;
	-- Stimulus process
	stim_proc: process
		file file1 : text open read_mode is "TestData.txt";
		variable Line1 : line;
		variable data1: integer;
	begin		
		Rst<='1';	Rx_Start<='0';	Tx_Start<='0';	Tx_Data<="00000000";
		wait for Clk_period*10;
		Rst<='0';	wait for Clk_period*10;
		for ii in 0 to 9 loop
			readline(file1,Line1); read(Line1,Data1); Tx_Data<=std_logic_vector(to_unsigned(Data1,8));
			Tx_Start<='1';	wait for Clk_period*1;
			while Tx_Busy='0'	loop	wait for Clk_period*1;	end loop; --to make sure the TX is ready to transmit the data.
			while Tx_Busy='1'	loop	wait for Clk_period*1;	end loop; -- the waiting is executed, as long as the statement(TX_Busy = '1') is true to a avoid data confusion.
			Tx_Start<='0';	wait for Clk_period*2;
		end loop;
		---------------------------------------
		for ii in 0 to 9 loop
			Rx_Start<='1';	wait for Clk_period*1;
			while Rx_Busy='0'	loop	wait for Clk_period*1;	end loop;
			while Rx_Rdy='0'	loop	wait for Clk_period*1;	end loop;
			Rx_Start<='0';	wait for Clk_period*2;
		end loop;
		wait;
	end process;
END;
