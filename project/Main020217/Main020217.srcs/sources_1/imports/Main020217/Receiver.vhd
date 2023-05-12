library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
------------------------------------------
entity Receiver is
	generic (Freq: integer :=100000000; Baud: integer :=115200);
	port (Clk,Rst,Start,RXD: in std_logic;
			Parity:	in	std_logic_vector(1 downto 0);--10,11 for no parity, 00 for even parity and 01 for odd parity
			Busy,Rdy,Error: out	std_logic;
			Dout:	out	std_logic_vector(7 downto 0));
end Receiver;
------------------------------------------
architecture Behavioral of Receiver is
	type my_type is (St_Idle,St_Start,St_Half,St_Data,St_Parity,St_Stop,St_Return);
	signal	State:	my_type:=St_Idle;
	------------------------------------------
	constant	Half:	integer:=Freq/(2*115200);
	constant	Full:	integer:=Freq/(1*115200);
	------------------------------------------
	signal	Cnt:	integer;
	signal	Number:	integer range 0 to 7;
	------------------------------------------
	signal	Parity_Check:	std_logic;
	signal	Data:	std_logic_vector(7 downto 0);
begin
	process(Clk)
	begin
		if (rising_edge(Clk))	then
			if (Rst='1')	then
				State<=St_Idle;	Cnt<=0;	Number<=0;	Busy<='0';	Rdy<='0';	Error<='0';	Dout<="00000000";	Data<="00000000";
			else
				case	(State)	is
				when	St_Idle	=>
					Cnt<=0;	Number<=0;	Busy<='0';	Rdy<='0';	Error<='0';	Dout<="00000000";	Data<="00000000";
					if (Start='1')	then	State<=St_Start;	else	State<=St_Idle;	end if;
				when	St_Start	=>
					Cnt<=0;	Number<=0;	Busy<='1';	Rdy<='0';	Error<='0';	Dout<="00000000";
					if (RXD='0')	then	State<=St_Half;	else	State<=St_Start;	end if;
				when	St_Half	=>
					if (Cnt=Half)	then
						Cnt<=0;
						if (RXD='0')	then	State<=St_Data;	Parity_Check<=Parity(0);	else	State<=St_Start;	end if;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Data	=>
					if (Cnt=Full)	then
						Cnt<=0;
						Data(Number)<=RXD;
						Parity_Check<=(Parity_Check xor RXD);
						if (Number=7)	then
							Number<=0;
							case	(Parity)	is
								when	"00"	=>	State<=St_Parity;
								when	"01"	=>	State<=St_Parity;
								when	others	=>	State<=St_Stop;
							end case;
						else	Number<=Number+1;
						end if;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Parity	=>
					if (Cnt=Full)	then
						Cnt<=0;
						Parity_Check<=(Parity_Check xor RXD);
						State<=St_Stop;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Stop	=>
					if (Cnt=Full)	then
						Cnt<=0;
						if (RXD='1')	then	State<=St_Return;	else	State<=St_Start;	end if;
					else
						Cnt<=Cnt+1;
					end if;
				when	St_Return	=>
					Busy<='0';
					case	(Parity)	is
						when	"00"	=>	if (Parity_Check='0')	then	 Dout<=Data;	Rdy<='1';	else	Error<='1';	end if;
						when	"01"	=>	if (Parity_Check='0')	then	 Dout<=Data;	Rdy<='1';	else	Error<='1';	end if;
						when	others	=>	Dout<=Data;	Rdy<='1';
					end case;
					if (Start='0')	then	State<=St_Start;	end if;
				when	others	=>
					State<=St_Idle;
				end case;
			end if;
		end if;
	end process;
	
end Behavioral;

