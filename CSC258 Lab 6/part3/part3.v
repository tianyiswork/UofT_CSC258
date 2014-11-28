module part3(
  input CLOCK_50,    //    50 MHz clock
  input [3:0] KEY,      //    Pushbutton[3:0]
  input [17:0] SW,    //    Toggle Switch[17:0]
  output [6:0]    HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,  // Seven Segment Digits
  output [8:0] LEDG,  //    LED Green
  output [17:0] LEDR,  //    LED Red
  inout [35:0] GPIO_0,GPIO_1,    //    GPIO Connections
//    LCD Module 16X2
  output LCD_ON,    // LCD Power ON/OFF
  output LCD_BLON,    // LCD Back Light ON/OFF
  output LCD_RW,    // LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN,    // LCD Enable
  output LCD_RS,    // LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA    // LCD Data bus 8 bits
);

	assign LEDG[0] = ((Q == 4'b1111) | (Q == 4'b1010)) ? 1'b1 : 1'b0;
	
	wire [3:0] Q;
	
	d_flip_flop dff3 (((SW[1]) | (Q[2] & Q[0])), KEY[0], SW[0], Q[3]);
	d_flip_flop dff2 (((~Q[3] & SW[1]) | (Q[1] & Q[0]) | (SW[1] & Q[2] & Q[1])), KEY[0], SW[0], Q[2]);
	d_flip_flop dff1 (((~Q[2] & SW[1]) | (Q[0])), KEY[0], SW[0], Q[1]);
	d_flip_flop dff0 (~SW[1], KEY[0], SW[0], Q[0]);
	
	convert con1 (Q, LEDR[8:0]);
	
	// determine letter to print
	wire [7:0] letterState;
	assign letterState = (Q == 4'b0000) ? 8'b01000001 : // state A
								(Q == 4'b0001) ? 8'b01000010 : // state B
								(Q == 4'b0011) ? 8'b01000011 : // state C
								(Q == 4'b0111) ? 8'b01000100 : // state D
								(Q == 4'b1111) ? 8'b01000101 : // state E
								(Q == 4'b1110) ? 8'b01000110 : // state F
								(Q == 4'b1100) ? 8'b01000111 : // state G
								(Q == 4'b1000) ? 8'b01001000 : // state H	
								(Q == 4'b1010) ? 8'b01001001 : 8'b11111111; // state I
								
	// HIGH or LOW assingnment
	wire [7:0] let1, let2, let3, let4;
	assign let1 = ((Q == 4'b1111) | (Q == 4'b1010)) ? 8'b01001000 : 8'b01001100;	// H or L
	assign let2 = ((Q == 4'b1111) | (Q == 4'b1010)) ? 8'b01001001 : 8'b01001111;	// I or O
	assign let3 = ((Q == 4'b1111) | (Q == 4'b1010)) ? 8'b01000111 : 8'b01010111;	// G or W
	assign let4 = ((Q == 4'b1111) | (Q == 4'b1010)) ? 8'b01001000 : 8'b00100000;	// H or blank

	//    All inout port turn to tri-state
	assign    GPIO_0        =    36'hzzzzzzzzz;
	assign    GPIO_1        =    36'hzzzzzzzzz;

	wire [6:0] myclock;
	wire RST;
	//assign RST = KEY[0];																				!!!

	// reset delay gives some time for peripherals to initialize
	wire DLY_RST;
	Reset_Delay r0(    .iCLK(CLOCK_50),.oRESET(DLY_RST) );

	// Send switches to red leds 
	//assign LEDR = SW;																					!!!

	// turn LCD ON
	assign    LCD_ON        =    1'b1;
	assign    LCD_BLON    =    1'b1;

	//wire [3:0] hex1, hex0;																			!!!
	//assign hex1 = SW[7:4];
	//assign hex0 = SW[3:0];

// A D flip-flop
module d_flip_flop (D, Clk, Rst, Q);

	input D, Clk, Rst;
	output reg Q;
	
	always @ (posedge Clk or negedge Rst)
	begin
		if (~Rst)
			Q <= 1'b0;
		else
			Q = D;
	end

endmodule


// convert a 4-bit input to the state code
module convert (x, y);

	input [3:0] x;
	output [8:0] y;
	
	assign y = (x[3:0] == 4'b0000 )? 9'b000000001: // state A
				  (x[3:0] == 4'b0001 )? 9'b000000010: // state B
				  (x[3:0] == 4'b0011 )? 9'b000000100: // state C
				  (x[3:0] == 4'b0111 )? 9'b000001000: // state D
				  (x[3:0] == 4'b1111 )? 9'b000010000: // state E
				  (x[3:0] == 4'b1110 )? 9'b000100000: // state F
				  (x[3:0] == 4'b1100 )? 9'b001000000: // state G
				  (x[3:0] == 4'b1000 )? 9'b010000000: // state H
				  (x[3:0] == 4'b1010 )? 9'b100000000: 9'b111111111; // state I
endmodule

LCD_Display u1(
// Host Side
   .iCLK_50MHZ(CLOCK_50),
   .iRST_N(DLY_RST),
   .letterState(letterState),
   .let1(let1),
	.let2(let2),
	.let3(let3),
	.let4(let4),
// LCD Side
   .DATA_BUS(LCD_DATA),
   .LCD_RW(LCD_RW),
   .LCD_E(LCD_EN),
   .LCD_RS(LCD_RS)
);

//LCD_Display u1(
//// Host Side
//   .iCLK_50MHZ(CLOCK_50),
//   .iRST_N(DLY_RST),
//   .hex0(hex0),
//   .hex1(hex1),
//// LCD Side
//   .DATA_BUS(LCD_DATA),
//   .LCD_RW(LCD_RW),
//   .LCD_E(LCD_EN),
//   .LCD_RS(LCD_RS)
//);
// blank unused 7-segment digits
	assign HEX0 = 7'b111_1111;
	assign HEX1 = 7'b111_1111;
	assign HEX2 = 7'b111_1111;
	assign HEX3 = 7'b111_1111;
	assign HEX4 = 7'b111_1111;
	assign HEX5 = 7'b111_1111;
	assign HEX6 = 7'b111_1111;
	assign HEX7 = 7'b111_1111;
endmodule

module LCD_Display(iCLK_50MHZ, iRST_N, letterState, let1, let2, let3, let4, 
						 LCD_RS,LCD_E,LCD_RW,DATA_BUS);
	input iCLK_50MHZ, iRST_N;
	input [7:0] letterState, let1, let2, let3, let4;
	//input [3:0] hex1, hex0;
	output LCD_RS, LCD_E, LCD_RW;
	inout [7:0] DATA_BUS;

	parameter
	HOLD = 4'h0,
	FUNC_SET = 4'h1,
	DISPLAY_ON = 4'h2,
	MODE_SET = 4'h3,
	Print_String = 4'h4,
	LINE2 = 4'h5,
	RETURN_HOME = 4'h6,
	DROP_LCD_E = 4'h7,
	RESET1 = 4'h8,
	RESET2 = 4'h9,
	RESET3 = 4'ha,
	DISPLAY_OFF = 4'hb,
	DISPLAY_CLEAR = 4'hc;

	reg [3:0] state, next_command;
	// Enter new ASCII hex data above for LCD Display
	reg [7:0] DATA_BUS_VALUE;
	wire [7:0] Next_Char;
	reg [19:0] CLK_COUNT_400HZ;
	reg [4:0] CHAR_COUNT;
	reg CLK_400HZ, LCD_RW_INT, LCD_E, LCD_RS;

	// BIDIRECTIONAL TRI STATE LCD DATA BUS
	assign DATA_BUS = (LCD_RW_INT? 8'bZZZZZZZZ: DATA_BUS_VALUE);

	LCD_display_string u1(
	.index(CHAR_COUNT),
	.out(Next_Char),
	.letterState(letterState),
	.let1(let1),
	.let2(let2),
	.let3(let3),
	.let4(let4));

	assign LCD_RW = LCD_RW_INT;

	always @(posedge iCLK_50MHZ or negedge iRST_N)
		 if (!iRST_N)
		 begin
			 CLK_COUNT_400HZ <= 20'h00000;
			 CLK_400HZ <= 1'b0;
		 end
		 else if (CLK_COUNT_400HZ < 20'h0F424)
		 begin
			 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1'b1;
		 end
		 else
		 begin
			CLK_COUNT_400HZ <= 20'h00000;
			CLK_400HZ <= ~CLK_400HZ;
		 end
	// State Machine to send commands and data to LCD DISPLAY

	always @(posedge CLK_400HZ or negedge iRST_N)
		 if (!iRST_N)
		 begin
		  state <= RESET1;
		 end
		 else
		 case (state)
		 RESET1:            
	// Set Function to 8-bit transfer and 2 line display with 5x8 Font size
	// see Hitachi HD44780 family data sheet for LCD command and timing details
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h38;
			state <= DROP_LCD_E;
			next_command <= RESET2;
			CHAR_COUNT <= 5'b00000;
		 end
		 RESET2:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h38;
			state <= DROP_LCD_E;
			next_command <= RESET3;
		 end
		 RESET3:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h38;
			state <= DROP_LCD_E;
			next_command <= FUNC_SET;
		 end
	// EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD

		 FUNC_SET:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h38;
			state <= DROP_LCD_E;
			next_command <= DISPLAY_OFF;
		 end

	// Turn off Display and Turn off cursor
		 DISPLAY_OFF:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h08;
			state <= DROP_LCD_E;
			next_command <= DISPLAY_CLEAR;
		 end

	// Clear Display and Turn off cursor
		 DISPLAY_CLEAR:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h01;
			state <= DROP_LCD_E;
			next_command <= DISPLAY_ON;
		 end

	// Turn on Display and Turn off cursor
		 DISPLAY_ON:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h0C;
			state <= DROP_LCD_E;
			next_command <= MODE_SET;
		 end

	// Set write mode to auto increment address and move cursor to the right
		 MODE_SET:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h06;
			state <= DROP_LCD_E;
			next_command <= Print_String;
		 end

	// Write ASCII hex character in first LCD character location
		 Print_String:
		 begin
			state <= DROP_LCD_E;
			LCD_E <= 1'b1;
			LCD_RS <= 1'b1;
			LCD_RW_INT <= 1'b0;
		 // ASCII character to output
			if (Next_Char[7:4] != 4'h0)
			  DATA_BUS_VALUE <= Next_Char;
			  // Convert 4-bit value to an ASCII hex digit
			else if (Next_Char[3:0] >9)
			  // ASCII A...F
				DATA_BUS_VALUE <= {4'h4,Next_Char[3:0]-4'h9};
			else
			  // ASCII 0...9
				DATA_BUS_VALUE <= {4'h3,Next_Char[3:0]};
		 // Loop to send out 32 characters to LCD Display  (16 by 2 lines)
			if ((CHAR_COUNT < 31) && (Next_Char != 8'hFE))
				CHAR_COUNT <= CHAR_COUNT + 1'b1;
			else
				CHAR_COUNT <= 5'b00000; 
		 // Jump to second line?
			if (CHAR_COUNT == 15)
			  next_command <= LINE2;
		 // Return to first line?
			else if ((CHAR_COUNT == 31) || (Next_Char == 8'hFE))
			  next_command <= RETURN_HOME;
			else
			  next_command <= Print_String;
		 end

	// Set write address to line 2 character 1
		 LINE2:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'hC0;
			state <= DROP_LCD_E;
			next_command <= Print_String;
		 end

	// Return write address to first character postion on line 1
		 RETURN_HOME:
		 begin
			LCD_E <= 1'b1;
			LCD_RS <= 1'b0;
			LCD_RW_INT <= 1'b0;
			DATA_BUS_VALUE <= 8'h80;
			state <= DROP_LCD_E;
			next_command <= Print_String;
		 end

	// The next three states occur at the end of each command or data transfer to the LCD
	// Drop LCD E line - falling edge loads inst/data to LCD controller
		 DROP_LCD_E:
		 begin
			LCD_E <= 1'b0;
			state <= HOLD;
		 end
	// Hold LCD inst/data valid after falling edge of E line                
		 HOLD:
		 begin
			state <= next_command;
		 end
		 endcase
	endmodule

module LCD_display_string(index,out,letterState,let1,let2,let3,let4);
input [4:0] index;
input [7:0] letterState,let1,let2,let3,let4;														//!!!
//input [3:0] hex0,hex1;
output [7:0] out;
reg [7:0] out;
// ASCII hex values for LCD Display
// Enter Live Hex Data Values from hardware here
// LCD DISPLAYS THE FOLLOWING:
//----------------------------
//| State=X                  |
//| HIGH/LOW                 |
//----------------------------



// Line 1
	always
	  case (index)
	 5'h00: out <= 8'h53;
    5'h01: out <= 8'h74;
    5'h02: out <= 8'h61;
    5'h03: out <= 8'h74;
    5'h04: out <= 8'h65;
    5'h05: out <= 8'h3D;
	 5'h06: out <= letterState;   // put letter of state here
// Line 2
	 5'h10: out <= 8'h5A;
    5'h11: out <= 8'h3D;
	 5'h12: out <= let1;				// H   L
	 5'h13: out <= let2;				// I   O
	 5'h14: out <= let3;				// G   W
	 5'h15: out <= let4;				// H
	 default: out <= 8'h20;
	  endcase
	 
	 
////----------------------------
////| Count=XX                  |
////| DE2                       |
////----------------------------
//// Line 1
//   always 
//     case (index)
//    5'h00: out <= 8'h43;
//    5'h01: out <= 8'h6F;
//    5'h02: out <= 8'h75;
//    5'h03: out <= 8'h6E;
//    5'h04: out <= 8'h74;
//    5'h05: out <= 8'h3D;
//    5'h06: out <= {4'h0,hex1};
//    5'h07: out <= {4'h0,hex0};
//// Line 2
//    5'h10: out <= 8'h44;
//    5'h11: out <= 8'h45;
//    5'h12: out <= 8'h32;
//    default: out <= 8'h20;
//     endcase
endmodule



//////////////////////////////////////////////
///
///		reset_delay.v
///
//////////////////////////////////////////////


module    Reset_Delay(iCLK,oRESET);
input        iCLK;
output reg    oRESET;
reg    [19:0]    Cont;

always@(posedge iCLK)
begin
    if(Cont!=20'hFFFFF)
    begin
        Cont    <=    Cont+1'b1;
        oRESET    <=    1'b0;
    end
    else
    oRESET    <=    1'b1;
end

endmodule



