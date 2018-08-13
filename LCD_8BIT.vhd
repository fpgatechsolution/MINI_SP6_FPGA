----------------------------------------------------------------------------------
-- COMPANY      : FPGATECHSOLUTION
-- MODULE NAME  : LCD_CONTROL
-- URL     		: WWW.FPGATECHSOLUTION.COM
----------------------------------------------------------------------------------
--


LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
ENTITY LCD_CONTROL IS
	PORT(reset, CLK_12MHZ				: IN	STD_LOGIC; --reset and clock
		 LCD_RS: OUT	STD_LOGIC;--Select registers
		 LCD_E	: OUT	STD_LOGIC; --Starts data read/write.
		 LCD_RW						: OUT STD_LOGIC; --red or wright
C1L1,C2L1,C3L1,C4L1,C5L1,C6L1,C7L1,C8L1,C9L1: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);--charctor no of first line--c1l1 is first char. first line
C10L1,C11L1,C12L1,C13L1,C14L1,C15L1,C16L1: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);--charctor no of first line
C1L2,C2L2,C3L2,C4L2,C5L2,C6L2,C7L2,C8L2,C9L2: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);--charctor no of second line
C10L2,C11L2,C12L2,C13L2,C14L2,C15L2,C16L2: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);--charctor no of second line
		 DATA_BUS				: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0));--data
		 
END LCD_CONTROL;

ARCHITECTURE BHE OF LCD_CONTROL IS


	TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, WRITE_CHAR1,
	WRITE_CHAR2,WRITE_CHAR3,WRITE_CHAR4,WRITE_CHAR5,WRITE_CHAR6,WRITE_CHAR7,
	WRITE_CHAR8, WRITE_CHAR9, WRITE_CHAR10,WRITE_CHAR11,WRITE_CHAR12,WRITE_CHAR13,WRITE_CHAR14,
	WRITE_CHAR15,WRITE_CHAR16,RETURN_HOME, TOGGLE_E, RESET1, RESET2, 
	RESET3, DISPLAY_OFF, DISPLAY_CLEAR);-- these are the states 
	
	SIGNAL state: STATE_TYPE := RESET1 ;
	SIGNAL next_command: STATE_TYPE:= RESET2;
				
			
	SIGNAL DATA_BUS_VALUE: STD_LOGIC_VECTOR(7 DOWNTO 0):=X"38" ;
	SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0):=X"00000" ;
	SIGNAL CLK_COUNT_10HZ: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CLK_400HZ, CLK_10HZ,LINE : STD_LOGIC;
BEGIN
	

	DATA_BUS <= DATA_BUS_VALUE ;

	PROCESS
	BEGIN
	 WAIT UNTIL CLK_12MHZ'EVENT AND CLK_12MHZ = '1';
		IF RESET = '1' THEN
		 CLK_COUNT_400HZ <= X"00000";
		 CLK_400HZ <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"03A98" THEN 
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";
				 CLK_400HZ <= NOT CLK_400HZ;
				END IF;
		END IF;
	END PROCESS;
	PROCESS (CLK_400HZ, reset)
	BEGIN
		IF reset = '1' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			next_command <= RESET2;
			LCD_E <= '1';
			LCD_RS <= '0';
			LCD_RW <= '0';

		ELSIF CLK_400HZ'EVENT AND CLK_400HZ = '1' THEN
-- GENERATE 1 SEC CLOCK SIGNAL FOR SECOND COUNT PROCESS
			IF CLK_COUNT_10HZ < 19 THEN
				CLK_COUNT_10HZ <= CLK_COUNT_10HZ + 1;
			ELSE
				CLK_COUNT_10HZ <= X"00";
				CLK_10HZ <= NOT CLK_10HZ;
			END IF;
-- SEND TIME TO LCD			
			CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
				WHEN RESET1 =>
				LINE<='0';
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= RESET2;
				WHEN RESET2 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= RESET3;
				WHEN RESET3 =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
				WHEN FUNC_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';						
						DATA_BUS_VALUE <= X"38";
						state <= TOGGLE_E;
						next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
				WHEN DISPLAY_OFF =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"08";
						state <= TOGGLE_E;
						next_command <= DISPLAY_CLEAR;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_CLEAR =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"01";
						state <= TOGGLE_E;
						next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_ON =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"0C";
						state <= TOGGLE_E;
						next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
				WHEN MODE_SET =>
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
						DATA_BUS_VALUE <= X"06";
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR1;
-- Write ASCII hex character in first LCD character location
				WHEN WRITE_CHAR1 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C1L1;
						ELSE
						DATA_BUS_VALUE <= C1L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR2;
-- Write ASCII hex character in second LCD character location
				WHEN WRITE_CHAR2 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C2L1;
						ELSE
						DATA_BUS_VALUE <= C2L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR3;
-- Write ASCII hex character in third LCD character location
				WHEN WRITE_CHAR3 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C3L1 ;
						ELSE
						DATA_BUS_VALUE <= C3L2 ;
						END IF;						
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR4;
-- Write ASCII hex character in fourth LCD character location
				WHEN WRITE_CHAR4 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C4L1;
						ELSE
						DATA_BUS_VALUE <= C4L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR5;
-- Write ASCII hex character in fifth LCD character location
				WHEN WRITE_CHAR5 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C5L1;
						ELSE
						DATA_BUS_VALUE <= C5L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR6;
-- Write ASCII hex character in sixth LCD character location
				WHEN WRITE_CHAR6 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C6L1 ;
						ELSE
						DATA_BUS_VALUE <= C6L2 ;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR7;
-- Write ASCII hex character in seventh LCD character location
				WHEN WRITE_CHAR7 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C7L1;
						ELSE
						DATA_BUS_VALUE <= C7L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR8;
-- Write ASCII hex character in eighth LCD character location
				WHEN WRITE_CHAR8 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C8L1;
						ELSE
						DATA_BUS_VALUE <= C8L2;
						END IF;
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR9;
				WHEN WRITE_CHAR9 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C9L1;
						ELSE
						DATA_BUS_VALUE <= C9L2;
						END IF;
						state <= TOGGLE_E;						
						next_command <= WRITE_CHAR10;						
				WHEN WRITE_CHAR10 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C10L1;
						ELSE
						DATA_BUS_VALUE <= C10L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR11;
				WHEN WRITE_CHAR11 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C11L1;
						ELSE
						DATA_BUS_VALUE <= C11L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR12;
				WHEN WRITE_CHAR12 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C12L1;
						ELSE
						DATA_BUS_VALUE <= C12L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR13;
				WHEN WRITE_CHAR13 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <= C13L1;
						ELSE
						DATA_BUS_VALUE <= C13L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR14;
				WHEN WRITE_CHAR14 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C14L1;
						ELSE
						DATA_BUS_VALUE <= C14L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR15;
				WHEN WRITE_CHAR15 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C15L1;
						ELSE
						DATA_BUS_VALUE <=C15L2;
						END IF;										
						state <= TOGGLE_E;
						next_command <= WRITE_CHAR16;
				WHEN WRITE_CHAR16 =>
						LCD_E <= '1';
						LCD_RS <= '1';
						LCD_RW <= '0';
						IF(LINE='0')THEN
						DATA_BUS_VALUE <=C16L1;
						ELSE
						DATA_BUS_VALUE <=C16L2;
						END IF;		
						LINE<=NOT LINE ;						
						state <= TOGGLE_E;
						next_command <= RETURN_HOME;
-- Return write address to first character postion
				WHEN RETURN_HOME =>
				--LINE<=NOT LINE ;--'1';
				
						LCD_E <= '1';
						LCD_RS <= '0';
						LCD_RW <= '0';
IF(LINE='1')THEN					
					DATA_BUS_VALUE <=X"C0";-- X"80";
					
ELSE
			DATA_BUS_VALUE <= X"80";
END IF;					

	state <= TOGGLE_E;
						next_command <= WRITE_CHAR1;
-- The next two states occur at the end of each command to the LCD
-- Toggle E line - falling edge loads inst/data to LCD controller
				WHEN TOGGLE_E =>
						LCD_E <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		END IF;
	END PROCESS;

END BHE;
