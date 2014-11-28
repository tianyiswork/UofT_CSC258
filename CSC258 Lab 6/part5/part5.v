module part5(
  // Clock Input (50 MHz)
  input CLOCK_50, // 50 MHz
  input CLOCK_27, // 27 MHz
  //  Push Buttons
  input  [3:0]  KEY,
  //  DPDT Switches 
  input  [17:0]  SW,
  //  7-SEG Displays
  output  [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
  //  LEDs
  output  [8:0]  LEDG,  //  LED Green[8:0]
  output  [17:0]  LEDR, //  LED Red[17:0]
  // TV Decoder
  output TD_RESET, // TV Decoder Reset
  // I2C
  inout  I2C_SDAT, // I2C Data
  output I2C_SCLK, // I2C Clock
  // Audio CODEC
  output/*inout*/ AUD_ADCLRCK, // Audio CODEC ADC LR Clock
  input     AUD_ADCDAT,  // Audio CODEC ADC Data
  output /*inout*/  AUD_DACLRCK, // Audio CODEC DAC LR Clock
  output AUD_DACDAT,  // Audio CODEC DAC Data
  inout     AUD_BCLK,    // Audio CODEC Bit-Stream Clock
  output AUD_XCK,     // Audio CODEC Chip Clock
  //  GPIO Connections
  inout  [35:0]  GPIO_0, GPIO_1
);


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

// Turn off green leds
assign LEDG = 0;

// Turn off 7-segment displays
parameter BLANK = 7'h7f;
//assign HEX0 = BLANK;
//assign HEX1 = BLANK;
//assign HEX2 = BLANK;
//assign HEX3 = BLANK;
//assign HEX4 = BLANK;
assign HEX5 = BLANK;
assign HEX6 = BLANK;
assign HEX7 = BLANK;

hex_7seg d4(SW[17:16],HEX4);
hex_7seg d3(SW[15:12],HEX3);
hex_7seg d2(SW[11:8],HEX2);
hex_7seg d1(SW[7:4],HEX1);
hex_7seg d0(SW[3:0],HEX0);



assign    TD_RESET = 1'b1;  // Enable 27 MHz

VGA_Audio_PLL     p1 (    
    .areset(~DLY_RST),
    .inclk0(CLOCK_27),
    .c0(VGA_CTRL_CLK),
    .c1(AUD_CTRL_CLK),
    .c2(VGA_CLK)
);

I2C_AV_Config u3(    
//    Host Side
  .iCLK(CLOCK_50),
  .iRST_N(KEY[0]),
//    I2C Side
  .I2C_SCLK(I2C_SCLK),
  .I2C_SDAT(I2C_SDAT)    
);

assign    AUD_ADCLRCK    =    AUD_DACLRCK;
assign    AUD_XCK        =    AUD_CTRL_CLK;

audio_clock u4(    
//    Audio Side
   .oAUD_BCK(AUD_BCLK),
   .oAUD_LRCK(AUD_DACLRCK),
//    Control Signals
  .iCLK_18_4(AUD_CTRL_CLK),
   .iRST_N(DLY_RST)    
);

audio_converter u5(
    // Audio side
    .AUD_BCK(AUD_BCLK),       // Audio bit clock
    .AUD_LRCK(AUD_DACLRCK), // left-right clock
    .AUD_ADCDAT(AUD_ADCDAT),
    .AUD_DATA(AUD_DACDAT),
    // Controller side
    .iRST_N(DLY_RST),  // reset
    .AUD_outL(audio_outL),
    .AUD_outR(audio_outR),
    .AUD_inL(audio_inL),
    .AUD_inR(audio_inR)
);

wire [15:0] audio_inL, audio_inR;
wire [15:0] audio_outL, audio_outR;
wire [15:0] signal;




//set up DDS frequency
//Use switches to set freq
wire [31:0] dds_incr;
wire [31:0] freq = SW[3:0]+10*SW[7:4]+100*SW[11:8]+1000*SW[15:12]+10000*SW[17:16];
assign dds_incr = freq * 91626 ; //91626 = 2^32/46875 so SW is in Hz

// Red 1: SW[3:0] = , SW[7:4] = ,     9   8   7    5
// Red 2: SW[3:0] = , SW[7:4] = , 
// Red 3: SW[3:0] = , SW[7:4] = , 
// Yellow: SW[3:0] = , SW[7:4] = ,     + 10
// Green: SW[3:0] = , SW[7:4] = ,   11    8   5
// Finish: SW[3:0] = , SW[7:4] = ,  11    4   3   2   1   0

reg [31:0] dds_phase;

always @(negedge AUD_DACLRCK or negedge DLY_RST)
    if (!DLY_RST) dds_phase <= 0;
    else dds_phase <= dds_phase + dds_incr;

wire [7:0] index = dds_phase[31:24];

 
sine_table sig1(
    .index(index),
    .signal(audio_outR)
);

    //audio_outR <= audio_inR;

//always @(posedge AUD_DACLRCK)
assign audio_outL = 15'h0000;


endmodule





module audio_clock (    
//    Audio Side
   output reg oAUD_BCK,
   output oAUD_LRCK,
//    Control Signals
   input iCLK_18_4,
   input iRST_N
);
/*                
*  Note: Reference clock seems to be 18 Mhz
*  Work it backward: 18 MHz /( 48 kHz *16 * 2 ) = 11.7185
*  The closest integer is 12, so actual sample rate is 46.875 kHz.
*/
parameter    REF_CLK        =    18432000;    // 18.432 MHz
parameter    SAMPLE_RATE    =    48000;        // 48 KHz
parameter    DATA_WIDTH    =    16;        // 16 Bits
parameter    CHANNEL_NUM    =    2;        // Dual Channel

//    Internal Registers and Wires
reg [3:0] BCK_DIV;
reg [8:0] LRCK_1X_DIV;
reg [7:0] LRCK_2X_DIV;
reg [6:0] LRCK_4X_DIV;
reg LRCK_1X;
reg LRCK_2X;
reg LRCK_4X;

//  AUD_BCK Generator
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
    if(!iRST_N)
    begin
      BCK_DIV <= 4'h0;
      oAUD_BCK <= 1'b0;
    end
    else
    begin
      // REF_CLK/SAMPLE_RATE = 384, 384/(DATA_WIDTH*CHANNEL_NUM) = 12
      //  12/2 - 1 = 5
      if (BCK_DIV >= REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1 )
      begin
        BCK_DIV     <= 4'h0;
        oAUD_BCK <= ~oAUD_BCK;
      end
      else BCK_DIV <= BCK_DIV+1'b1;
    end
end
//
//  AUD_LRCK Generator
//    oAUD_LRCK is high for left and low for right channel
//
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        LRCK_1X_DIV    <=    0;
        LRCK_2X_DIV    <=    0;
        LRCK_4X_DIV    <=    0;
        LRCK_1X        <=    0;
        LRCK_2X        <=    0;
        LRCK_4X        <=    0;
    end
    else
    begin
        //LRCK 1X
        if(LRCK_1X_DIV >= REF_CLK/(SAMPLE_RATE*2)-1 )
        begin
            LRCK_1X_DIV <=    0;
            LRCK_1X    <= ~LRCK_1X;
        end
        else LRCK_1X_DIV <= LRCK_1X_DIV+1'b1;
        // LRCK 2X
        if(LRCK_2X_DIV >= REF_CLK/(SAMPLE_RATE*4)-1 )
        begin
            LRCK_2X_DIV <= 0;
            LRCK_2X    <= ~LRCK_2X;
        end
        else LRCK_2X_DIV <= LRCK_2X_DIV+1'b1;        
        // LRCK 4X
        if(LRCK_4X_DIV >= REF_CLK/(SAMPLE_RATE*8)-1 )
        begin
            LRCK_4X_DIV <= 0;
            LRCK_4X    <= ~LRCK_4X;
        end
        else LRCK_4X_DIV <= LRCK_4X_DIV+1'b1;        
    end
end
assign    oAUD_LRCK = LRCK_1X;

endmodule





module audio_converter (
    // Audio side
    input AUD_BCK,    // Audio bit clock
    input AUD_LRCK,   // left-right clock
    input AUD_ADCDAT,
    output AUD_DATA,
    // Controller side
    input iRST_N,  // reset
    input [15:0] AUD_outL,
    input [15:0] AUD_outR,
    output reg[15:0] AUD_inL,
    output reg[15:0] AUD_inR
);


//    16 Bits - MSB First
// Clocks in the ADC input
// and sets up the output bit selector

	reg [3:0] SEL_Cont;
	always@(negedge AUD_BCK or negedge iRST_N)
	begin
		 if(!iRST_N) SEL_Cont <= 4'h0;
		 else
		 begin
			 SEL_Cont <= SEL_Cont+1'b1; //4 bit counter, so it wraps at 16
			 if (AUD_LRCK) AUD_inL[~(SEL_Cont)] <= AUD_ADCDAT;
			 else AUD_inR[~(SEL_Cont)] <= AUD_ADCDAT;
		 end
	end

	// output the DAC bit-stream
	assign AUD_DATA = (AUD_LRCK)? AUD_outL[~SEL_Cont]: AUD_outR[~SEL_Cont] ;

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




module I2C_AV_Config (    //    Host Side
                        iCLK,
                        iRST_N,
                        //    I2C Side
                        I2C_SCLK,
                        I2C_SDAT    );
//    Host Side
input        iCLK;
input        iRST_N;
//    I2C Side
output        I2C_SCLK;
inout        I2C_SDAT;
//    Internal Registers/Wires
reg    [15:0]    mI2C_CLK_DIV;
reg    [23:0]    mI2C_DATA;
reg            mI2C_CTRL_CLK;
reg            mI2C_GO;
wire        mI2C_END;
wire        mI2C_ACK;
reg    [15:0]    LUT_DATA;
reg    [5:0]    LUT_INDEX;
reg    [3:0]    mSetup_ST;

//    Clock Setting
parameter    CLK_Freq    =    50000000;    //    50    MHz
parameter    I2C_Freq    =    20000;        //    20    KHz
//    LUT Data Number
parameter    LUT_SIZE    =    51;
//    Audio Data Index
parameter    Dummy_DATA    =    0;
parameter    SET_LIN_L    =    1;
parameter    SET_LIN_R    =    2;
parameter    SET_HEAD_L    =    3;
parameter    SET_HEAD_R    =    4;
parameter    A_PATH_CTRL    =    5;
parameter    D_PATH_CTRL    =    6;
parameter    POWER_ON    =    7;
parameter    SET_FORMAT    =    8;
parameter    SAMPLE_CTRL    =    9;
parameter    SET_ACTIVE    =    10;
//    Video Data Index
parameter    SET_VIDEO    =    11;

/////////////////////    I2C Control Clock    ////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        mI2C_CTRL_CLK    <=    0;
        mI2C_CLK_DIV    <=    0;
    end
    else
    begin
        if( mI2C_CLK_DIV    < (CLK_Freq/I2C_Freq) )
        mI2C_CLK_DIV    <=    mI2C_CLK_DIV+1'b1;
        else
        begin
            mI2C_CLK_DIV    <=    0;
            mI2C_CTRL_CLK    <=    ~mI2C_CTRL_CLK;
        end
    end
end
////////////////////////////////////////////////////////////////////
I2C_Controller     u0    (    .CLOCK(mI2C_CTRL_CLK),        //    Controller Work Clock
                        .I2C_SCLK(I2C_SCLK),        //    I2C CLOCK
                              .I2C_SDAT(I2C_SDAT),        //    I2C DATA
                        .I2C_DATA(mI2C_DATA),        //    DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
                        .GO(mI2C_GO),                  //    GO transfor
                        .END(mI2C_END),                //    END transfor 
                        .ACK(mI2C_ACK),                //    ACK
                        .RESET(iRST_N)    );
////////////////////////////////////////////////////////////////////
//////////////////////    Config Control    ////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        LUT_INDEX    <=    0;
        mSetup_ST    <=    0;
        mI2C_GO        <=    0;
    end
    else
    begin
        if(LUT_INDEX<LUT_SIZE)
        begin
            case(mSetup_ST)
            0:    begin
                    if(LUT_INDEX<SET_VIDEO)
                    mI2C_DATA    <=    {8'h34,LUT_DATA};
                    else
                    mI2C_DATA    <=    {8'h40,LUT_DATA};
                    mI2C_GO        <=    1;
                    mSetup_ST    <=    1;
                end
            1:    begin
                    if(mI2C_END)
                    begin
                        if(!mI2C_ACK)
                        mSetup_ST    <=    2;
                        else
                        mSetup_ST    <=    0;                            
                        mI2C_GO        <=    0;
                    end
                end
            2:    begin
                    LUT_INDEX    <=    LUT_INDEX+1'b1;
                    mSetup_ST    <=    0;
                end
            endcase
        end
    end
end
////////////////////////////////////////////////////////////////////
/////////////////////    Config Data LUT      //////////////////////////    
always
begin
    case(LUT_INDEX)
    //    Audio Config Data
    Dummy_DATA    :    LUT_DATA    <=    16'h0000;
    SET_LIN_L    :    LUT_DATA    <=    16'h001A; // L-line, moderately high gain
    SET_LIN_R    :    LUT_DATA    <=    16'h021A; // R-line, modernately high gain
    SET_HEAD_L    :    LUT_DATA    <=    16'h047A; // L-phone out, high volume
    SET_HEAD_R    :    LUT_DATA    <=    16'h067A; // R-phone out, high volume (7B max volume)
    A_PATH_CTRL    :    LUT_DATA    <=    16'h0812; // Line->ADC, DAC on, no bypass or sidetone
    D_PATH_CTRL    :    LUT_DATA    <=    16'h0A06; // deemph to 48kHz
    POWER_ON    :    LUT_DATA    <=    16'h0C00; // all on 
    SET_FORMAT    :    LUT_DATA    <=    16'h0E01; //MSB first left-justified, slave mode
    SAMPLE_CTRL    :    LUT_DATA    <=    16'h1002; //MSB first left-justified, slave mode
    SET_ACTIVE    :    LUT_DATA    <=    16'h1201; //Activate
    //    Video Config Data
    SET_VIDEO+0    :    LUT_DATA    <=    16'h1500;
    SET_VIDEO+1    :    LUT_DATA    <=    16'h1741;
    SET_VIDEO+2    :    LUT_DATA    <=    16'h3a16;
    SET_VIDEO+3    :    LUT_DATA    <=    16'h5004;
    SET_VIDEO+4    :    LUT_DATA    <=    16'hc305;
    SET_VIDEO+5    :    LUT_DATA    <=    16'hc480;
    SET_VIDEO+6    :    LUT_DATA    <=    16'h0e80;
    SET_VIDEO+7    :    LUT_DATA    <=    16'h5020;
    SET_VIDEO+8    :    LUT_DATA    <=    16'h5218;
    SET_VIDEO+9    :    LUT_DATA    <=    16'h58ed;
    SET_VIDEO+10:    LUT_DATA    <=    16'h77c5;
    SET_VIDEO+11:    LUT_DATA    <=    16'h7c93;
    SET_VIDEO+12:    LUT_DATA    <=    16'h7d00;
    SET_VIDEO+13:    LUT_DATA    <=    16'hd048;
    SET_VIDEO+14:    LUT_DATA    <=    16'hd5a0;
    SET_VIDEO+15:    LUT_DATA    <=    16'hd7ea;
    SET_VIDEO+16:    LUT_DATA    <=    16'he43e;
    SET_VIDEO+17:    LUT_DATA    <=    16'hea0f;
    SET_VIDEO+18:    LUT_DATA    <=    16'h3112;
    SET_VIDEO+19:    LUT_DATA    <=    16'h3281;
    SET_VIDEO+20:    LUT_DATA    <=    16'h3384;
    SET_VIDEO+21:    LUT_DATA    <=    16'h37A0;
    SET_VIDEO+22:    LUT_DATA    <=    16'he580;
    SET_VIDEO+23:    LUT_DATA    <=    16'he603;
    SET_VIDEO+24:    LUT_DATA    <=    16'he785;
    SET_VIDEO+25:    LUT_DATA    <=    16'h5000;
    SET_VIDEO+26:    LUT_DATA    <=    16'h5100;
    SET_VIDEO+27:    LUT_DATA    <=    16'h0050;
    SET_VIDEO+28:    LUT_DATA    <=    16'h1000;
    SET_VIDEO+29:    LUT_DATA    <=    16'h0402;
    SET_VIDEO+30:    LUT_DATA    <=    16'h0860;
    SET_VIDEO+31:    LUT_DATA    <=    16'h0a18;
    SET_VIDEO+32:    LUT_DATA    <=    16'h1100;
    SET_VIDEO+33:    LUT_DATA    <=    16'h2b00;
    SET_VIDEO+34:    LUT_DATA    <=    16'h2c8c;
    SET_VIDEO+35:    LUT_DATA    <=    16'h2df2;
    SET_VIDEO+36:    LUT_DATA    <=    16'h2eee;
    SET_VIDEO+37:    LUT_DATA    <=    16'h2ff4;
    SET_VIDEO+38:    LUT_DATA    <=    16'h30d2;
    SET_VIDEO+39:    LUT_DATA    <=    16'h0e05;
    default:        LUT_DATA    <=    16'h0000;
    endcase
end
////////////////////////////////////////////////////////////////////
endmodule




// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altrea Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:i2c controller
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Joe Yang          :| 05/07/10  :|      Initial Revision
// --------------------------------------------------------------------
module I2C_Controller (
    CLOCK,
    I2C_SCLK,//I2C CLOCK
     I2C_SDAT,//I2C DATA
    I2C_DATA,//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
    GO,      //GO transfor
    END,     //END transfor 
    W_R,     //W_R
    ACK,      //ACK
    RESET,
    //TEST
    SD_COUNTER,
    SDO
);
    input  CLOCK;
    input  [23:0]I2C_DATA;    
    input  GO;
    input  RESET;    
    input  W_R;
     inout  I2C_SDAT;    
    output I2C_SCLK;
    output END;    
    output ACK;

//TEST
    output [5:0] SD_COUNTER;
    output SDO;


reg SDO;
reg SCLK;
reg END;
reg [23:0]SD;
reg [5:0]SD_COUNTER;

wire I2C_SCLK=SCLK | ( ((SD_COUNTER >= 4) & (SD_COUNTER <=30))? ~CLOCK :1'b0 );
wire I2C_SDAT=SDO?1'bz:1'b0 ;

reg ACK1,ACK2,ACK3;
wire ACK=ACK1 | ACK2 |ACK3;

//--I2C COUNTER
always @(negedge RESET or posedge CLOCK ) begin
if (!RESET) SD_COUNTER=6'b111111;
else begin
if (GO==0) 
    SD_COUNTER=0;
    else 
    if (SD_COUNTER < 6'b111111) SD_COUNTER=SD_COUNTER+1'b1;    
end
end
//----

always @(negedge RESET or  posedge CLOCK ) begin
if (!RESET) begin SCLK=1;SDO=1; ACK1=0;ACK2=0;ACK3=0; END=1; end
else
case (SD_COUNTER)
    6'd0  : begin ACK1=0 ;ACK2=0 ;ACK3=0 ; END=0; SDO=1; SCLK=1;end
    //start
    6'd1  : begin SD=I2C_DATA;SDO=0;end
    6'd2  : SCLK=0;
    //SLAVE ADDR
    6'd3  : SDO=SD[23];
    6'd4  : SDO=SD[22];
    6'd5  : SDO=SD[21];
    6'd6  : SDO=SD[20];
    6'd7  : SDO=SD[19];
    6'd8  : SDO=SD[18];
    6'd9  : SDO=SD[17];
    6'd10 : SDO=SD[16];    
    6'd11 : SDO=1'b1;//ACK

    //SUB ADDR
    6'd12  : begin SDO=SD[15]; ACK1=I2C_SDAT; end
    6'd13  : SDO=SD[14];
    6'd14  : SDO=SD[13];
    6'd15  : SDO=SD[12];
    6'd16  : SDO=SD[11];
    6'd17  : SDO=SD[10];
    6'd18  : SDO=SD[9];
    6'd19  : SDO=SD[8];
    6'd20  : SDO=1'b1;//ACK

    //DATA
    6'd21  : begin SDO=SD[7]; ACK2=I2C_SDAT; end
    6'd22  : SDO=SD[6];
    6'd23  : SDO=SD[5];
    6'd24  : SDO=SD[4];
    6'd25  : SDO=SD[3];
    6'd26  : SDO=SD[2];
    6'd27  : SDO=SD[1];
    6'd28  : SDO=SD[0];
    6'd29  : SDO=1'b1;//ACK

    
    //stop
    6'd30 : begin SDO=1'b0;    SCLK=1'b0; ACK3=I2C_SDAT; end    
    6'd31 : SCLK=1'b1; 
    6'd32 : begin SDO=1'b1; END=1; end 

endcase
end



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




//
// Sine Wave ROM Table
//
module sine_table(
	  input [7:0] index,
	  output [15:0] signal
	);
	parameter PERIOD = 256; // length of table

	assign signal = sine;
	reg [15:0] sine;
			  
	always@(index)begin
		case(index)
		 8'h00: sine = 16'h0000 ;
		 8'h01: sine = 16'h0192 ;
		 8'h02: sine = 16'h0323 ;
		 8'h03: sine = 16'h04b5 ;
		 8'h04: sine = 16'h0645 ;
		 8'h05: sine = 16'h07d5 ;
		 8'h06: sine = 16'h0963 ;
		 8'h07: sine = 16'h0af0 ;
		 8'h08: sine = 16'h0c7c ;
		 8'h09: sine = 16'h0e05 ;
		 8'h0a: sine = 16'h0f8c ;
		 8'h0b: sine = 16'h1111 ;
		 8'h0c: sine = 16'h1293 ;
		 8'h0d: sine = 16'h1413 ;
		 8'h0e: sine = 16'h158f ;
		 8'h0f: sine = 16'h1708 ;
		 8'h10: sine = 16'h187d ;
		 8'h11: sine = 16'h19ef ;
		 8'h12: sine = 16'h1b5c ;
		 8'h13: sine = 16'h1cc5 ;
		 8'h14: sine = 16'h1e2a ;
		 8'h15: sine = 16'h1f8b ;
		 8'h16: sine = 16'h20e6 ;
		 8'h17: sine = 16'h223c ;
		 8'h18: sine = 16'h238d ;
		 8'h19: sine = 16'h24d9 ;
		 8'h1a: sine = 16'h261f ;
		 8'h1b: sine = 16'h275f ;
		 8'h1c: sine = 16'h2899 ;
		 8'h1d: sine = 16'h29cc ;
		 8'h1e: sine = 16'h2afa ;
		 8'h1f: sine = 16'h2c20 ;
		 8'h20: sine = 16'h2d40 ;
		 8'h21: sine = 16'h2e59 ;
		 8'h22: sine = 16'h2f6b ;
		 8'h23: sine = 16'h3075 ;
		 8'h24: sine = 16'h3178 ;
		 8'h25: sine = 16'h3273 ;
		 8'h26: sine = 16'h3366 ;
		 8'h27: sine = 16'h3452 ;
		 8'h28: sine = 16'h3535 ;
		 8'h29: sine = 16'h3611 ;
		 8'h2a: sine = 16'h36e4 ;
		 8'h2b: sine = 16'h37ae ;
		 8'h2c: sine = 16'h3870 ;
		 8'h2d: sine = 16'h3929 ;
		 8'h2e: sine = 16'h39da ;
		 8'h2f: sine = 16'h3a81 ;
		 8'h30: sine = 16'h3b1f ;
		 8'h31: sine = 16'h3bb5 ;
		 8'h32: sine = 16'h3c41 ;
		 8'h33: sine = 16'h3cc4 ;
		 8'h34: sine = 16'h3d3d ;
		 8'h35: sine = 16'h3dad ;
		 8'h36: sine = 16'h3e14 ;
		 8'h37: sine = 16'h3e70 ;
		 8'h38: sine = 16'h3ec4 ;
		 8'h39: sine = 16'h3f0d ;
		 8'h3a: sine = 16'h3f4d ;
		 8'h3b: sine = 16'h3f83 ;
		 8'h3c: sine = 16'h3fb0 ;
		 8'h3d: sine = 16'h3fd2 ;
		 8'h3e: sine = 16'h3feb ;
		 8'h3f: sine = 16'h3ffa ;
		 8'h40: sine = 16'h3fff ;
		 8'h41: sine = 16'h3ffa ;
		 8'h42: sine = 16'h3feb ;
		 8'h43: sine = 16'h3fd2 ;
		 8'h44: sine = 16'h3fb0 ;
		 8'h45: sine = 16'h3f83 ;
		 8'h46: sine = 16'h3f4d ;
		 8'h47: sine = 16'h3f0d ;
		 8'h48: sine = 16'h3ec4 ;
		 8'h49: sine = 16'h3e70 ;
		 8'h4a: sine = 16'h3e14 ;
		 8'h4b: sine = 16'h3dad ;
		 8'h4c: sine = 16'h3d3d ;
		 8'h4d: sine = 16'h3cc4 ;
		 8'h4e: sine = 16'h3c41 ;
		 8'h4f: sine = 16'h3bb5 ;
		 8'h50: sine = 16'h3b1f ;
		 8'h51: sine = 16'h3a81 ;
		 8'h52: sine = 16'h39da ;
		 8'h53: sine = 16'h3929 ;
		 8'h54: sine = 16'h3870 ;
		 8'h55: sine = 16'h37ae ;
		 8'h56: sine = 16'h36e4 ;
		 8'h57: sine = 16'h3611 ;
		 8'h58: sine = 16'h3535 ;
		 8'h59: sine = 16'h3452 ;
		 8'h5a: sine = 16'h3366 ;
		 8'h5b: sine = 16'h3273 ;
		 8'h5c: sine = 16'h3178 ;
		 8'h5d: sine = 16'h3075 ;
		 8'h5e: sine = 16'h2f6b ;
		 8'h5f: sine = 16'h2e59 ;
		 8'h60: sine = 16'h2d40 ;
		 8'h61: sine = 16'h2c20 ;
		 8'h62: sine = 16'h2afa ;
		 8'h63: sine = 16'h29cc ;
		 8'h64: sine = 16'h2899 ;
		 8'h65: sine = 16'h275f ;
		 8'h66: sine = 16'h261f ;
		 8'h67: sine = 16'h24d9 ;
		 8'h68: sine = 16'h238d ;
		 8'h69: sine = 16'h223c ;
		 8'h6a: sine = 16'h20e6 ;
		 8'h6b: sine = 16'h1f8b ;
		 8'h6c: sine = 16'h1e2a ;
		 8'h6d: sine = 16'h1cc5 ;
		 8'h6e: sine = 16'h1b5c ;
		 8'h6f: sine = 16'h19ef ;
		 8'h70: sine = 16'h187d ;
		 8'h71: sine = 16'h1708 ;
		 8'h72: sine = 16'h158f ;
		 8'h73: sine = 16'h1413 ;
		 8'h74: sine = 16'h1293 ;
		 8'h75: sine = 16'h1111 ;
		 8'h76: sine = 16'h0f8c ;
		 8'h77: sine = 16'h0e05 ;
		 8'h78: sine = 16'h0c7c ;
		 8'h79: sine = 16'h0af0 ;
		 8'h7a: sine = 16'h0963 ;
		 8'h7b: sine = 16'h07d5 ;
		 8'h7c: sine = 16'h0645 ;
		 8'h7d: sine = 16'h04b5 ;
		 8'h7e: sine = 16'h0323 ;
		 8'h7f: sine = 16'h0192 ;
		 8'h80: sine = 16'h0000 ;
		 8'h81: sine = 16'hfe6e ;
		 8'h82: sine = 16'hfcdd ;
		 8'h83: sine = 16'hfb4b ;
		 8'h84: sine = 16'hf9bb ;
		 8'h85: sine = 16'hf82b ;
		 8'h86: sine = 16'hf69d ;
		 8'h87: sine = 16'hf510 ;
		 8'h88: sine = 16'hf384 ;
		 8'h89: sine = 16'hf1fb ;
		 8'h8a: sine = 16'hf074 ;
		 8'h8b: sine = 16'heeef ;
		 8'h8c: sine = 16'hed6d ;
		 8'h8d: sine = 16'hebed ;
		 8'h8e: sine = 16'hea71 ;
		 8'h8f: sine = 16'he8f8 ;
		 8'h90: sine = 16'he783 ;
		 8'h91: sine = 16'he611 ;
		 8'h92: sine = 16'he4a4 ;
		 8'h93: sine = 16'he33b ;
		 8'h94: sine = 16'he1d6 ;
		 8'h95: sine = 16'he075 ;
		 8'h96: sine = 16'hdf1a ;
		 8'h97: sine = 16'hddc4 ;
		 8'h98: sine = 16'hdc73 ;
		 8'h99: sine = 16'hdb27 ;
		 8'h9a: sine = 16'hd9e1 ;
		 8'h9b: sine = 16'hd8a1 ;
		 8'h9c: sine = 16'hd767 ;
		 8'h9d: sine = 16'hd634 ;
		 8'h9e: sine = 16'hd506 ;
		 8'h9f: sine = 16'hd3e0 ;
		 8'ha0: sine = 16'hd2c0 ;
		 8'ha1: sine = 16'hd1a7 ;
		 8'ha2: sine = 16'hd095 ;
		 8'ha3: sine = 16'hcf8b ;
		 8'ha4: sine = 16'hce88 ;
		 8'ha5: sine = 16'hcd8d ;
		 8'ha6: sine = 16'hcc9a ;
		 8'ha7: sine = 16'hcbae ;
		 8'ha8: sine = 16'hcacb ;
		 8'ha9: sine = 16'hc9ef ;
		 8'haa: sine = 16'hc91c ;
		 8'hab: sine = 16'hc852 ;
		 8'hac: sine = 16'hc790 ;
		 8'had: sine = 16'hc6d7 ;
		 8'hae: sine = 16'hc626 ;
		 8'haf: sine = 16'hc57f ;
		 8'hb0: sine = 16'hc4e1 ;
		 8'hb1: sine = 16'hc44b ;
		 8'hb2: sine = 16'hc3bf ;
		 8'hb3: sine = 16'hc33c ;
		 8'hb4: sine = 16'hc2c3 ;
		 8'hb5: sine = 16'hc253 ;
		 8'hb6: sine = 16'hc1ec ;
		 8'hb7: sine = 16'hc190 ;
		 8'hb8: sine = 16'hc13c ;
		 8'hb9: sine = 16'hc0f3 ;
		 8'hba: sine = 16'hc0b3 ;
		 8'hbb: sine = 16'hc07d ;
		 8'hbc: sine = 16'hc050 ;
		 8'hbd: sine = 16'hc02e ;
		 8'hbe: sine = 16'hc015 ;
		 8'hbf: sine = 16'hc006 ;
		 8'hc0: sine = 16'hc001 ;
		 8'hc1: sine = 16'hc006 ;
		 8'hc2: sine = 16'hc015 ;
		 8'hc3: sine = 16'hc02e ;
		 8'hc4: sine = 16'hc050 ;
		 8'hc5: sine = 16'hc07d ;
		 8'hc6: sine = 16'hc0b3 ;
		 8'hc7: sine = 16'hc0f3 ;
		 8'hc8: sine = 16'hc13c ;
		 8'hc9: sine = 16'hc190 ;
		 8'hca: sine = 16'hc1ec ;
		 8'hcb: sine = 16'hc253 ;
		 8'hcc: sine = 16'hc2c3 ;
		 8'hcd: sine = 16'hc33c ;
		 8'hce: sine = 16'hc3bf ;
		 8'hcf: sine = 16'hc44b ;
		 8'hd0: sine = 16'hc4e1 ;
		 8'hd1: sine = 16'hc57f ;
		 8'hd2: sine = 16'hc626 ;
		 8'hd3: sine = 16'hc6d7 ;
		 8'hd4: sine = 16'hc790 ;
		 8'hd5: sine = 16'hc852 ;
		 8'hd6: sine = 16'hc91c ;
		 8'hd7: sine = 16'hc9ef ;
		 8'hd8: sine = 16'hcacb ;
		 8'hd9: sine = 16'hcbae ;
		 8'hda: sine = 16'hcc9a ;
		 8'hdb: sine = 16'hcd8d ;
		 8'hdc: sine = 16'hce88 ;
		 8'hdd: sine = 16'hcf8b ;
		 8'hde: sine = 16'hd095 ;
		 8'hdf: sine = 16'hd1a7 ;
		 8'he0: sine = 16'hd2c0 ;
		 8'he1: sine = 16'hd3e0 ;
		 8'he2: sine = 16'hd506 ;
		 8'he3: sine = 16'hd634 ;
		 8'he4: sine = 16'hd767 ;
		 8'he5: sine = 16'hd8a1 ;
		 8'he6: sine = 16'hd9e1 ;
		 8'he7: sine = 16'hdb27 ;
		 8'he8: sine = 16'hdc73 ;
		 8'he9: sine = 16'hddc4 ;
		 8'hea: sine = 16'hdf1a ;
		 8'heb: sine = 16'he075 ;
		 8'hec: sine = 16'he1d6 ;
		 8'hed: sine = 16'he33b ;
		 8'hee: sine = 16'he4a4 ;
		 8'hef: sine = 16'he611 ;
		 8'hf0: sine = 16'he783 ;
		 8'hf1: sine = 16'he8f8 ;
		 8'hf2: sine = 16'hea71 ;
		 8'hf3: sine = 16'hebed ;
		 8'hf4: sine = 16'hed6d ;
		 8'hf5: sine = 16'heeef ;
		 8'hf6: sine = 16'hf074 ;
		 8'hf7: sine = 16'hf1fb ;
		 8'hf8: sine = 16'hf384 ;
		 8'hf9: sine = 16'hf510 ;
		 8'hfa: sine = 16'hf69d ;
		 8'hfb: sine = 16'hf82b ;
		 8'hfc: sine = 16'hf9bb ;
		 8'hfd: sine = 16'hfb4b ;
		 8'hfe: sine = 16'hfcdd ;
		 8'hff: sine = 16'hfe6e ;
		 default: sine = 16'h0000;
		endcase
	end
endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module VGA_Audio_PLL (
    areset,
    inclk0,
    c0,
    c1,
    c2);

    input      areset;
    input      inclk0;
    output      c0;
    output      c1;
    output      c2;

    wire [5:0] sub_wire0;
    wire [0:0] sub_wire6 = 1'h0;
    wire [2:2] sub_wire3 = sub_wire0[2:2];
    wire [1:1] sub_wire2 = sub_wire0[1:1];
    wire [0:0] sub_wire1 = sub_wire0[0:0];
    wire  c0 = sub_wire1;
    wire  c1 = sub_wire2;
    wire  c2 = sub_wire3;
    wire  sub_wire4 = inclk0;
    wire [1:0] sub_wire5 = {sub_wire6, sub_wire4};

    altpll    altpll_component (
                .inclk (sub_wire5),
                .areset (areset),
                .clk (sub_wire0),
                .activeclock (),
                .clkbad (),
                .clkena ({6{1'b1}}),
                .clkloss (),
                .clkswitch (1'b0),
                .enable0 (),
                .enable1 (),
                .extclk (),
                .extclkena ({4{1'b1}}),
                .fbin (1'b1),
                .locked (),
                .pfdena (1'b1),
                .pllena (1'b1),
                .scanaclr (1'b0),
                .scanclk (1'b0),
                .scandata (1'b0),
                .scandataout (),
                .scandone (),
                .scanread (1'b0),
                .scanwrite (1'b0),
                .sclkout0 (),
                .sclkout1 ());
    defparam
        altpll_component.clk0_divide_by = 15,
        altpll_component.clk0_duty_cycle = 50,
        altpll_component.clk0_multiply_by = 14,
        altpll_component.clk0_phase_shift = "0",
        altpll_component.clk1_divide_by = 3,
        altpll_component.clk1_duty_cycle = 50,
        altpll_component.clk1_multiply_by = 2,
        altpll_component.clk1_phase_shift = "0",
        altpll_component.clk2_divide_by = 15,
        altpll_component.clk2_duty_cycle = 50,
        altpll_component.clk2_multiply_by = 14,
        altpll_component.clk2_phase_shift = "-9921",
        altpll_component.compensate_clock = "CLK0",
        altpll_component.inclk0_input_frequency = 37037,
        altpll_component.intended_device_family = "Cyclone II",
        altpll_component.lpm_type = "altpll",
        altpll_component.operation_mode = "NORMAL",
        altpll_component.pll_type = "FAST",
        altpll_component.port_activeclock = "PORT_UNUSED",
        altpll_component.port_areset = "PORT_USED",
        altpll_component.port_clkbad0 = "PORT_UNUSED",
        altpll_component.port_clkbad1 = "PORT_UNUSED",
        altpll_component.port_clkloss = "PORT_UNUSED",
        altpll_component.port_clkswitch = "PORT_UNUSED",
        altpll_component.port_fbin = "PORT_UNUSED",
        altpll_component.port_inclk0 = "PORT_USED",
        altpll_component.port_inclk1 = "PORT_UNUSED",
        altpll_component.port_locked = "PORT_UNUSED",
        altpll_component.port_pfdena = "PORT_UNUSED",
        altpll_component.port_pllena = "PORT_UNUSED",
        altpll_component.port_scanaclr = "PORT_UNUSED",
        altpll_component.port_scanclk = "PORT_UNUSED",
        altpll_component.port_scandata = "PORT_UNUSED",
        altpll_component.port_scandataout = "PORT_UNUSED",
        altpll_component.port_scandone = "PORT_UNUSED",
        altpll_component.port_scanread = "PORT_UNUSED",
        altpll_component.port_scanwrite = "PORT_UNUSED",
        altpll_component.port_clk0 = "PORT_USED",
        altpll_component.port_clk1 = "PORT_USED",
        altpll_component.port_clk2 = "PORT_USED",
        altpll_component.port_clk3 = "PORT_UNUSED",
        altpll_component.port_clk4 = "PORT_UNUSED",
        altpll_component.port_clk5 = "PORT_UNUSED",
        altpll_component.port_clkena0 = "PORT_UNUSED",
        altpll_component.port_clkena1 = "PORT_UNUSED",
        altpll_component.port_clkena2 = "PORT_UNUSED",
        altpll_component.port_clkena3 = "PORT_UNUSED",
        altpll_component.port_clkena4 = "PORT_UNUSED",
        altpll_component.port_clkena5 = "PORT_UNUSED",
        altpll_component.port_enable0 = "PORT_UNUSED",
        altpll_component.port_enable1 = "PORT_UNUSED",
        altpll_component.port_extclk0 = "PORT_UNUSED",
        altpll_component.port_extclk1 = "PORT_UNUSED",
        altpll_component.port_extclk2 = "PORT_UNUSED",
        altpll_component.port_extclk3 = "PORT_UNUSED",
        altpll_component.port_extclkena0 = "PORT_UNUSED",
        altpll_component.port_extclkena1 = "PORT_UNUSED",
        altpll_component.port_extclkena2 = "PORT_UNUSED",
        altpll_component.port_extclkena3 = "PORT_UNUSED",
        altpll_component.port_sclkout0 = "PORT_UNUSED",
        altpll_component.port_sclkout1 = "PORT_UNUSED";


endmodule
