
----------------------------------------------------------------------------------
-- Company     : FPGATECHSOLUTION
-- Module Name : UART_CONTROL
-- URL     		: WWW.FPGATECHSOLUTION.com
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY UART_CONTROL IS
PORT(		
		RESET	: IN STD_LOGIC;
		CLK		: IN STD_LOGIC;
		RXD		: IN STD_LOGIC;
		TXD 	: OUT STD_LOGIC;
		TEST_LED: OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END ENTITY UART_CONTROL;

ARCHITECTURE UART_BEH OF UART_CONTROL IS

	CONSTANT CLK_FREQUENCY : INTEGER := 12000000;
	CONSTANT BAUD          : INTEGER := 9600;

	SIGNAL RXD_DATA_READY, TXD_BUSY,DELAY_ENB,DELAY_CLK,DELAY_FINISH,RX_STROBE : STD_LOGIC;
	SIGNAL TXD_START : STD_LOGIC :='0';
	SIGNAL RXD_DATA, TXD_DATA : STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE ROM_TYPE IS ARRAY (127 DOWNTO 0) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL MSG_CNT,DELAY_COUNT,COMP_CNT: INTEGER;
		
	TYPE STATE_TYPE IS (IDLE,MSG_BUFF,S1,S2,S3,S4,S5,S6,S7,S8,S9);
	SIGNAL STATE : STATE_TYPE :=IDLE;

	COMPONENT UART IS
		GENERIC
		(
			FREQUENCY		: INTEGER := 12000000;
			BAUD			: INTEGER:= 9600
		);
	PORT(
		CLK				: IN STD_LOGIC;
		RXD				: IN STD_LOGIC;
		TXD				: OUT STD_LOGIC;
		TXD_DATA		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		TXD_START		: IN STD_LOGIC;
		TXD_BUSY		: OUT STD_LOGIC;
		RXD_DATA		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		RXD_DATA_READY	: OUT STD_LOGIC
		);
	END COMPONENT UART;


   FUNCTION CHAR_TO_HEX(C: CHARACTER) RETURN STD_LOGIC_VECTOR IS
      VARIABLE L: STD_LOGIC_VECTOR(7 DOWNTO 0);
   BEGIN
      CASE C IS
           WHEN 'A' => L:=X"41";
           WHEN 'B' => L:=X"42";
           WHEN 'C' => L:=X"43";
           WHEN 'D' => L:=X"44";
           WHEN 'E' => L:=X"45";
           WHEN 'F' => L:=X"46";
           WHEN 'G' => L:=X"47";
           WHEN 'H' => L:=X"48";
           WHEN 'I' => L:=X"49";
           WHEN 'J' => L:=X"4A";
           WHEN 'K' => L:=X"4B";
           WHEN 'L' => L:=X"4C";
           WHEN 'M' => L:=X"4D";
           WHEN 'N' => L:=X"4E";
           WHEN 'O' => L:=X"4F";
           WHEN 'P' => L:=X"50";
           WHEN 'Q' => L:=X"51";
           WHEN 'R' => L:=X"52";
           WHEN 'S' => L:=X"53";
           WHEN 'T' => L:=X"54";
           WHEN 'U' => L:=X"55";
           WHEN 'V' => L:=X"56";
           WHEN 'W' => L:=X"57";
           WHEN 'X' => L:=X"58";
           WHEN 'Y' => L:=X"59";
           WHEN 'Z' => L:=X"5A";
           WHEN '0' => L:=X"30";
           WHEN '1' => L:=X"31";
           WHEN '2' => L:=X"32";
           WHEN '3' => L:=X"33";
           WHEN '4' => L:=X"34";
           WHEN '5' => L:=X"35";
           WHEN '6' => L:=X"36";
           WHEN '7' => L:=X"37";
           WHEN '8' => L:=X"38";
           WHEN '9' => L:=X"39";
           WHEN '=' => L:=X"3D";
           WHEN '*' => L:=X"2A";
           WHEN '+' => L:=X"2B";
           WHEN ' ' => L:=X"20";
		   WHEN '.' => L:=X"2E";
		   WHEN 'e' => L:=X"0A";
		   WHEN 'd' => L:=X"0D";
           WHEN OTHERS => L:=X"20";
      END CASE;
      RETURN L;
   END FUNCTION CHAR_TO_HEX;

   
FUNCTION TO_STD_LOGIC_VECTOR(S: STRING) RETURN STD_LOGIC_VECTOR IS 
      VARIABLE SLV : STD_LOGIC_VECTOR(((S'HIGH)*8)-1 DOWNTO 0);
      VARIABLE K   : INTEGER;
         BEGIN  
      K:=S'LOW;
		FOR I IN S'RANGE LOOP
            SLV((I*8)-1 DOWNTO((I*8)-1)-7):=CHAR_TO_HEX(S(I));
            K :=K+1;
		END LOOP;
      RETURN SLV;
END FUNCTION TO_STD_LOGIC_VECTOR;
   
   SIGNAL GEN_MSG :STRING(1 TO 70);
   SIGNAL GEN_MSG_HEX1:STD_LOGIC_VECTOR((GEN_MSG'HIGH*8)-1 DOWNTO 0);
   SIGNAL ALL_ZERO:STD_LOGIC_VECTOR((GEN_MSG'HIGH*8)-1 DOWNTO 0):=(OTHERS=>'0');

   SIGNAL MSG_CHAR1 :STRING(1 TO 61);
   SIGNAL MSG_HEX1:STD_LOGIC_VECTOR((MSG_CHAR1'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR2 :STRING(1 TO 37);
   SIGNAL MSG_HEX2:STD_LOGIC_VECTOR((MSG_CHAR2'HIGH*8)-1 DOWNTO 0);

   SIGNAL MSG_CHAR3 :STRING(1 TO 20);
   SIGNAL MSG_HEX3:STD_LOGIC_VECTOR((MSG_CHAR3'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR4 :STRING(1 TO 20);
   SIGNAL MSG_HEX4:STD_LOGIC_VECTOR((MSG_CHAR4'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR5 :STRING(1 TO 20);
   SIGNAL MSG_HEX5:STD_LOGIC_VECTOR((MSG_CHAR5'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR6 :STRING(1 TO 20);
   SIGNAL MSG_HEX6:STD_LOGIC_VECTOR((MSG_CHAR6'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR7 :STRING(1 TO 20);
   SIGNAL MSG_HEX7:STD_LOGIC_VECTOR((MSG_CHAR7'HIGH*8)-1 DOWNTO 0);


   SIGNAL MSG_CHAR8 :STRING(1 TO 20);
   SIGNAL MSG_HEX8:STD_LOGIC_VECTOR((MSG_CHAR8'HIGH*8)-1 DOWNTO 0);




   
BEGIN

	MSG_CHAR1<="ed THIS FPGA KIT IS DESIGN AND DEVELOPED BY FPGATECHSOLUTION ";
    MSG_HEX1<=TO_STD_LOGIC_VECTOR(MSG_CHAR1);


	MSG_CHAR2<="ed VISIT US WWW.FPGATECHSOLUTION.COM ";
    MSG_HEX2<=TO_STD_LOGIC_VECTOR(MSG_CHAR2);

	


	INST_UARTTRANSMITTER: UART 
		GENERIC MAP
	(
		FREQUENCY		=> CLK_FREQUENCY,
		BAUD			=> BAUD
	)
	PORT MAP(
		CLK =>CLK ,
		TXD =>TXD ,
        RXD=>RXD,
		TXD_DATA =>TXD_DATA ,
		TXD_START =>TXD_START ,
		TXD_BUSY => TXD_BUSY,
        RXD_DATA=>RXD_DATA,
        RXD_DATA_READY=>RX_STROBE
	);


TEST_LED<=RXD_DATA;




STATE_PROC: PROCESS(CLK,RXD_DATA_READY,RESET,DELAY_COUNT)
	               VARIABLE T3,TOTAL_CHAR:INTEGER;
		    BEGIN
	                IF(RESET='1')THEN
						DELAY_ENB<='0';
						MSG_CNT<=0;
						TXD_START <= '0';
						STATE<=IDLE;
							COMP_CNT<=240;
					ELSIF RISING_EDGE(CLK) THEN
						
						CASE STATE IS

							
							WHEN IDLE=>
								DELAY_ENB<='0';
								TXD_START <= '0';
								STATE<=IDLE;
								COMP_CNT<=240;
								STATE <= MSG_BUFF;
						
							WHEN MSG_BUFF=>
	
									CASE MSG_CNT IS
										WHEN 0 =>
						
											GEN_MSG_HEX1<=(  ALL_ZERO((GEN_MSG_HEX1'HIGH-MSG_HEX1'HIGH)-1 DOWNTO 0) & MSG_HEX1);
											TOTAL_CHAR:=(((MSG_HEX1'HIGH+1)/8));
										WHEN 1 =>
											GEN_MSG_HEX1<=(  ALL_ZERO((GEN_MSG_HEX1'HIGH-MSG_HEX2'HIGH)-1 DOWNTO 0) & MSG_HEX2);
											TOTAL_CHAR:=(((MSG_HEX2'HIGH+1)/8));

										WHEN OTHERS=>NULL;
					
										END CASE;
								DELAY_ENB<='0';
								STATE <= S1;
					
							WHEN S1=>
								
								IF(DELAY_ENB='0' AND DELAY_FINISH='0')THEN	
									DELAY_ENB<='1';
									STATE <= S1;
								ELSIF(DELAY_FINISH='1')THEN
									STATE <= S2;
								END IF;
					
							WHEN S2 =>
								DELAY_ENB<='0';
								T3:=0;
								TXD_START <= '1';
								STATE <= S3;	
		              
							WHEN S3 =>
								IF(TXD_BUSY = '0' )THEN
									TXD_DATA <= GEN_MSG_HEX1(((T3+1)*8)-1 DOWNTO (T3*8));
									STATE <= S3;
									T3:=T3+1;
								ELSIF( T3 = TOTAL_CHAR)THEN--5
									T3:=0;
									STATE <= S4;
									TXD_START <= '0';
								END IF;	

							WHEN S4 =>
								IF(MSG_CNT<2) THEN 
									MSG_CNT<=MSG_CNT+1;
									STATE <= IDLE;
								ELSE 
									STATE <= S5;
								END IF ;
							WHEN S5 =>
								STATE <= S5;


							WHEN OTHERS=>NULL;
					
						END CASE;
					END IF;
		
			END PROCESS STATE_PROC;
	



	
			PROCESS(CLK)
				VARIABLE T3:STD_LOGIC_VECTOR(1 DOWNTO 0):=(OTHERS=>'0');
			BEGIN
				IF CLK'EVENT AND CLK = '1' THEN
					T3:=T3+1;
				END IF;
					DELAY_CLK<=T3(1);
			END PROCESS;



			PROCESS(DELAY_CLK,RESET,DELAY_ENB)
				VARIABLE T3: INTEGER;
			BEGIN
				IF(RESET='1')THEN
					T3:=0;
				ELSIF RISING_EDGE(DELAY_CLK) THEN
					IF(DELAY_ENB='0')THEN
						T3:=0;
						DELAY_FINISH<='0';
					ELSIF(T3 < COMP_CNT)THEN
						DELAY_FINISH<='0';
						T3:=T3+1;
					ELSE
						DELAY_FINISH<='1';
					END IF;
				END IF;
					DELAY_COUNT<=T3;
			END PROCESS ;
	
	
	
		
	
	
END ARCHITECTURE UART_BEH;