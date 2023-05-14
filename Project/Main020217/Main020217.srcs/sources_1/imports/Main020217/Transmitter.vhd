library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
------------------------------------------
entity Transmitter is
	generic (Freq: integer :=100000000; Baud: integer :=115200);
	port (Clk,Rst,Start: in std_logic;
			Parity:	in	std_logic_vector(1 downto 0);--10,11 for no parity, 00 for even parity and 01 for odd parity
			Din:	in	std_logic_vector(7 downto 0);
			Busy,TXD: out	std_logic);
end Transmitter;
------------------------------------------
architecture Behavioral of Transmitter is
	type my_type is (St_Idle,St_Start,St_Full,St_Data,St_Parity,St_Stop,St_Return);
	signal	State:	my_type:=St_Idle;
	------------------------------------------
	constant	Half:	integer:=Freq/(2*115200);
	constant	Full:	integer:=Freq/(1*115200);
	------------------------------------------
	signal	Cnt:	integer;
	signal	Number:	integer range 0 to 8;
	------------------------------------------
	signal	Parity_Check:	std_logic;
	signal	Data:	std_logic_vector(7 downto 0);
begin
	process(Clk)
	begin
		if (rising_edge(Clk))	then
			if (Rst='1')	then
				State<=St_Idle;	Cnt<=0;	Number<=0;	Busy<='0';	TXD<='1';	Data<="00000000";
			else
				case	(State)	is
				when	St_Idle	=>
					Cnt<=0;	Number<=0;	Busy<='0';	TXD<='1';
					if (Start='1')	then	State<=St_Start;	Data<=Din;	else	Data<="00000000";	end if;
				when	St_Start	=>
					TXD<='0';	Parity_Check<=Parity(0);	State<=St_Full;
				when	St_Full	=>
					Busy<='1';
					if (Cnt=Full)	then
						Cnt<=0;
						TXD<=Data(Number);	Number<=Number+1;
						Parity_Check<=(Parity_Check xor Data(0));
						State<=St_Data;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Data	=>
					if (Cnt=Full)	then
						Cnt<=0;
						if (Number=8)	then
							Number<=0;
							case	(Parity)	is
								when	"00"	=>	State<=St_Parity;	TXD<=Parity_Check;
								when	"01"	=>	State<=St_Parity;	TXD<=Parity_Check;
								when	others	=>	State<=St_Stop;	TXD<='1';
							end case;
						else	Number<=Number+1;	TXD<=Data(Number);	Parity_Check<=(Parity_Check xor Data(Number));
						end if;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Parity	=>
					if (Cnt=Full)	then
						Cnt<=0;
						TXD<='1';
						State<=St_Stop;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Stop	=>
					if (Cnt=Full)	then
						Cnt<=0;
						State<=St_Return;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Return	=>
					Busy<='0';
					if (Start='0')	then	State<=St_Idle;	end if;
				when	others	=>
					State<=St_Idle;
				end case;
			end if;
		end if;
	end process;
	
end Behavioral;

