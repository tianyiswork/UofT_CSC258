module part4(
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
  inout [7:0] LCD_DATA,    // LCD Data bus 8 bits
  input    PS2_DAT,
  input    PS2_CLK
);


	assign LEDG = 0;

	wire reset = 1'b0;
	wire [7:0] scan_code;

	reg [7:0] history[1:4];
	wire read, scan_ready;

	oneshot pulser(
		.pulse_out(read),
		.trigger_in(scan_ready),
		.clk(CLOCK_50)
	);

	keyboard kbd(
	  .keyboard_clk(PS2_CLK),
	  .keyboard_data(PS2_DAT),
	  .clock50(CLOCK_50),
	  .reset(reset),
	  .read(read),
	  .scan_ready(scan_ready),
	  .scan_code(scan_code)
	);

	hex_7seg dsp0(history[1][3:0],HEX0);
	hex_7seg dsp1(history[1][7:4],HEX1);

	hex_7seg dsp2(history[2][3:0],HEX2);
	hex_7seg dsp3(history[2][7:4],HEX3);

	hex_7seg dsp4(history[3][3:0],HEX4);
	hex_7seg dsp5(history[3][7:4],HEX5);

	hex_7seg dsp6(history[4][3:0],HEX6);
	hex_7seg dsp7(history[4][7:4],HEX7);



	always @(posedge scan_ready)
	begin
		 history[4] <= history[3];
		 history[3] <= history[2];
		 history[2] <= history[1];
		 history[1] <= scan_code;
	end
		 

	// blank remaining digits
	/*
	wire [6:0] blank = 7'h7f;
	assign HEX2 = blank;
	assign HEX3 = blank;
	assign HEX4 = blank;
	assign HEX5 = blank;
	assign HEX6 = blank;
	assign HEX7 = blank;
	*/


	wire [7:0] d1,d2,d3,d4,d5,d6,d7,d8;

	assign d1 = (scan_code[7] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d2 = (scan_code[6] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d3 = (scan_code[5] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d4 = (scan_code[4] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d5 = (scan_code[3] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d6 = (scan_code[2] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d7 = (scan_code[1] == 1'b0) ? 8'b00110000 : 8'b00110001;
	assign d8 = (scan_code[0] == 1'b0) ? 8'b00110000 : 8'b00110001;
	 


	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



	//    All inout port turn to tri-state
	assign    GPIO_0        =    36'hzzzzzzzzz;
	assign    GPIO_1        =    36'hzzzzzzzzz;

	wire [6:0] myclock;
	wire RST;
	assign RST = KEY[0];

	// reset delay gives some time for peripherals to initialize
	wire DLY_RST;
	Reset_Delay r0(    .iCLK(CLOCK_50),.oRESET(DLY_RST) );

	// Send switches to red leds 
	assign LEDR = SW;

	// turn LCD ON
	assign    LCD_ON        =    1'b1;
	assign    LCD_BLON    =    1'b1;

	wire [3:0] hex1, hex0;
	assign hex1 = SW[7:4];
	assign hex0 = SW[3:0];


	LCD_Display u1(
	// Host Side
		.iCLK_50MHZ(CLOCK_50),
		.iRST_N(DLY_RST),
		.d1(d1),
		.d2(d2),
		.d3(d3),
		.d4(d4),
		.d5(d5),
		.d6(d6),
		.d7(d7),
		.d8(d8),
	// LCD Side
		.DATA_BUS(LCD_DATA),
		.LCD_RW(LCD_RW),
		.LCD_E(LCD_EN),
		.LCD_RS(LCD_RS)
	);


	//// blank unused 7-segment digits
	//assign HEX0 = 7'b111_1111;
	//assign HEX1 = 7'b111_1111;
	//assign HEX2 = 7'b111_1111;
	//assign HEX3 = 7'b111_1111;
	//assign HEX4 = 7'b111_1111;
	//assign HEX5 = 7'b111_1111;
	//assign HEX6 = 7'b111_1111;
	//assign HEX7 = 7'b111_1111;

	endmodule

module LCD_Display(iCLK_50MHZ, iRST_N, d1,d2,d3,d4,d5,d6,d7,d8, 
    LCD_RS,LCD_E,LCD_RW,DATA_BUS);
	input iCLK_50MHZ, iRST_N;
	input [7:0] d1,d2,d3,d4,d5,d6,d7,d8;
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
	.d1(d1),
	 .d2(d2),
		.d3(d3),
		.d4(d4),
		.d5(d5),
		.d6(d6),
		.d7(d7),
		.d8(d8)
	);

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

	module LCD_display_string(index,out,d1,d2,d3,d4,d5,d6,d7,d8);
	input [4:0] index;
	input [7:0] d1,d2,d3,d4,d5,d6,d7,d8;
	output [7:0] out;
	reg [7:0] out;
	// ASCII hex values for LCD Display
	// Enter Live Hex Data Values from hardware here
	// LCD DISPLAYS THE FOLLOWING:
	//----------------------------
	//| Count=XX                  |
	//| DE2                       |
	//----------------------------
	// Line 1
		always 
		  case (index)
		 5'h00: out <= d1;
		 5'h01: out <= d2;
		 5'h02: out <= d3;
		 5'h03: out <= d4;
		 5'h04: out <= d5;
		 5'h05: out <= d6;
		 5'h06: out <= d7;
		 5'h07: out <= d8;
	//// Line 2
	//    5'h10: out <= 8'h44;
	//    5'h11: out <= 8'h45;
	//    5'h12: out <= 8'h32;
		 default: out <= 8'h20;
     endcase
endmodule





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

module keyboard(keyboard_clk, keyboard_data, clock50, reset, read, scan_ready, scan_code);
input keyboard_clk;
input keyboard_data;
input clock50; // 50 Mhz system clock
input reset;
input read;
output scan_ready;
output [7:0] scan_code;
reg ready_set;
reg [7:0] scan_code;
reg scan_ready;
reg read_char;
reg clock; // 25 Mhz internal clock

reg [3:0] incnt;
reg [8:0] shiftin;

reg [7:0] filter;
reg keyboard_clk_filtered;

// scan_ready is set to 1 when scan_code is available.
// user should set read to 1 and then to 0 to clear scan_ready

always @ (posedge ready_set or posedge read)
if (read == 1) scan_ready <= 0;
else scan_ready <= 1;

// divide-by-two 50MHz to 25MHz
always @(posedge clock50)
    clock <= ~clock;



// This process filters the raw clock signal coming from the keyboard 
// using an eight-bit shift register and two AND gates

always @(posedge clock)
begin
   filter <= {keyboard_clk, filter[7:1]};
   if (filter==8'b1111_1111) keyboard_clk_filtered <= 1;
   else if (filter==8'b0000_0000) keyboard_clk_filtered <= 0;
end


// This process reads in serial data coming from the terminal

always @(posedge keyboard_clk_filtered)
begin
   if (reset==1)
   begin
      incnt <= 4'b0000;
      read_char <= 0;
   end
   else if (keyboard_data==0 && read_char==0)
   begin
    read_char <= 1;
    ready_set <= 0;
   end
   else
   begin
       // shift in next 8 data bits to assemble a scan code    
       if (read_char == 1)
           begin
              if (incnt < 9) 
              begin
                incnt <= incnt + 1'b1;
                shiftin = { keyboard_data, shiftin[8:1]};
                ready_set <= 0;
            end
        else
            begin
                incnt <= 0;
                scan_code <= shiftin[7:0];
                read_char <= 0;
                ready_set <= 1;
            end
        end
    end
end

endmodule





module oneshot(output reg pulse_out, input trigger_in, input clk);
reg delay;

always @ (posedge clk)
begin
    if (trigger_in && !delay) pulse_out <= 1'b1;
    else pulse_out <= 1'b0;
    delay <= trigger_in;
end 
endmodule




module hex_7seg(hex_digit,seg);
input [3:0] hex_digit;
output [6:0] seg;
reg [6:0] seg;
// seg = {g,f,e,d,c,b,a};
// 0 is on and 1 is off

always @ (hex_digit)
case (hex_digit)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;     // ---a----
        4'h2: seg = 7'b0100100;     // |      |
        4'h3: seg = 7'b0110000;     // f      b
        4'h4: seg = 7'b0011001;     // |      |
        4'h5: seg = 7'b0010010;     // ---g----
        4'h6: seg = 7'b0000010;     // |      |
        4'h7: seg = 7'b1111000;     // e      c
        4'h8: seg = 7'b0000000;     // |      |
        4'h9: seg = 7'b0011000;     // ---d----
        4'ha: seg = 7'b0001000;
        4'hb: seg = 7'b0000011;
        4'hc: seg = 7'b1000110;
        4'hd: seg = 7'b0100001;
        4'he: seg = 7'b0000110;
        4'hf: seg = 7'b0001110;
endcase

endmodule
