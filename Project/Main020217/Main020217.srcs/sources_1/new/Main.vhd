library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
------------------------------------
entity Main is
	port(Clk,Rst,RXD:  in  std_logic;
		TXD:    out std_logic;
		LED:    out std_logic_vector(2 downto 0));
end Main;
------------------------------------
architecture Behavioral of Main is
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
	------------------------------------------
	type my_type is (St_Idle,St_Start,St_Rec0,St_Rec1,St_Rec2,St_Proc0,St_Proc1,St_Send0,St_Send1,St_Send2,St_Send3,St_Return);
	signal	State:	my_type:=St_Idle;
	------------------------------------------
	constant   Freq:	integer:=100000000;
	constant   Baud:	integer:=115200;
	constant   Parity: std_logic_vector(1 downto 0):="00";
	------------------------------------------
	type	My_Array	is array (0 to 9) of std_logic_vector(7 downto 0);
	signal	Mem:    My_Array;
	signal	Cnt0,Cnt1:	integer;
	signal	Number:	integer range 0 to 9;
	------------------------------------------
	signal	RX_Rst,RX_Start,RX_Error,RX_Busy,Rx_Rdy,Tx_Rst,Tx_Start,TX_Busy,Swap:	std_logic;
	signal	Rx_Data,Tx_Data:	std_logic_vector(7 downto 0);
begin
    ------------------------------------------
	URX:	Receiver   
			generic map(Freq=>Freq,Baud=>Baud)
			port map(Rst=>RX_Rst,Clk=>Clk,Parity=>Parity,RXD=>RXD,Start=>RX_Start,Error=>RX_Error,Busy=>RX_Busy,Rdy=>Rx_Rdy,Dout=>Rx_Data);
	UTX:	Transmitter   
			generic map(Freq=>Freq,Baud=>Baud)
			port map(Rst=>Tx_Rst,Clk=>Clk,Parity=>Parity,Start=>Tx_Start,Busy=>TX_Busy,Din=>Tx_Data,TXD=>TXD);
    ------------------------------------------
	process(Clk)
	begin
		if (rising_edge(Clk)) then
			if (Rst='1')    then
				Rx_Rst<='1';    Rx_Start<='0';
				Tx_Rst<='1';    Tx_Start<='0';  Tx_Data<="00000000";	LED<="000";
				State<=St_Idle;
				Cnt0<=0;	Cnt1<=0;	Swap<='0';
			else
				case (State) is
					when	St_Idle	=>
						Rx_Rst<='1';    Rx_Start<='0';
						Tx_Rst<='1';    Tx_Start<='0';  Tx_Data<="00000000";	LED<="000";
						State<=St_Start; Cnt0<=0;	Cnt1<=0;	Swap<='0';
					when	St_Start	=>
						Rx_Rst<='0';	Rx_Start<='1';  State<=St_Rec0;	LED<="001";
					when	St_Rec0	=>
						if (Rx_Busy='1')    then    State<=St_Rec1; end if;
					when	St_Rec1	=>
						if (Rx_Rdy='1')    then    State<=St_Rec2; end if;
					when	St_Rec2	=>
						Rx_Start<='0';
						if (Rx_Error='0')	then
							Mem(Number)<=Rx_Data;
							if (Number=9)   then	Number<=0;  State<=St_Proc0;
							else						Number<=Number+1;   State<=St_Start;
							end if;
						else
							State<=St_Start;
						end if;
					when    St_Proc0  =>
						LED<="010";
						if (unsigned(Mem(Cnt0+1))<unsigned(Mem(Cnt0)))	then
							Mem(Cnt0+1)<=Mem(Cnt0);	Mem(Cnt0)<=Mem(Cnt0+1);	Swap<='1';
						end if;
						if (Cnt0=8)	then	Cnt0<=0;	State<=St_Proc1;
						else					Cnt0<=Cnt0+1;
						end if;
					when	St_Proc1	=>
						Swap<='0';
						if (Swap='0')	then
							State<=St_Send0;
						else
							if (Cnt1=9)	then	Cnt1<=0;	State<=St_Send0;
							else					Cnt1<=Cnt1+1;	State<=St_Proc0;
							end if;
						end if;
					when	St_Send0	=>
						LED<="100";
						Tx_Rst<='0';	Tx_Start<='1';  State<=St_Send1;	Tx_Data<=Mem(Number);
					when	St_Send1	=>
						if (Tx_Busy='1')    then    State<=St_Send2; end if;
					when	St_Send2	=>
						if (Tx_Busy='0')    then    State<=St_Send3; end if;
					when	St_Send3	=>
						Tx_Start<='0';
						if (Number=9)   then	Number<=0;  State<=St_Return;
						else						Number<=Number+1;   State<=St_Send0;
						end if;
					when	St_Return	=>
						State<=St_Idle;	LED<="000";
					when	others	=>
						State<=St_Idle;
				end case;
			end if;
		end if;
	end process;
end Behavioral;
