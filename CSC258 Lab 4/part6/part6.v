module part6 (CLOCK_50, KEY, HEX3, HEX2, HEX1, HEX0);
	input [1:0] KEY;
	input CLOCK_50;
	output [6:0] HEX3, HEX2, HEX1, HEX0;
	// initial seed value
	reg [0:15] Q = 16'b1000_0000_0000_0000;
	// Instantiate a 1 sec clock.
	delay_1s delay1 (CLOCK_50, del_1sec);
	// actual random number generator
	always @ (posedge del_1sec or posedge KEY[0])
		begin
			if (KEY[0])
				Q <= 16'b1000_0000_0000_0000;
			else
				Q <= {(((Q[15]^Q[13])^Q[12])^Q[10]), Q[0:14]};
		end
	// Display the 16-bit number in a decimal format using 4 displays.
	hex_7seg hex0 (Q[12:15], HEX0);
   hex_7seg hex1 (Q[8:11], HEX1);
   hex_7seg hex2 (Q[4:7], HEX2);
   hex_7seg hex3 (Q[0:3], HEX3);
endmodule

// A one second counter.
module delay_1s (Clk, delay);
	input Clk;
	output reg delay;
	reg [25:0] count;
	always @ (posedge Clk)
		begin
			if (count == 26'd49_999_999)
         //if (count == 26'd6)   // for simulation purposes.
				begin
					count <= 26'd0;
               delay <= 1;
				end
			else
				begin
					count <= count + 1;
					delay <= 0;
				end
		end
endmodule

// Hexidecimal display.
module hex_7seg (C, Display);
	input [3:0] C;
	output [6:0] Display;
	assign Display = (C[3:0] == 4'b0000 )? 7'b1000000: // 0
						  (C[3:0] == 4'b0001 )? 7'b1111001: // 1
						  (C[3:0] == 4'b0010 )? 7'b0100100: // 2
						  (C[3:0] == 4'b0011 )? 7'b0110000: // 3
						  (C[3:0] == 4'b0100 )? 7'b0011001: // 4
						  (C[3:0] == 4'b0101 )? 7'b0010010: // 5
						  (C[3:0] == 4'b0110 )? 7'b0000010: // 6
						  (C[3:0] == 4'b0111 )? 7'b1111000: // 7
						  (C[3:0] == 4'b1000 )? 7'b0000000: // 8
						  (C[3:0] == 4'b1001 )? 7'b0010000: // 9
						  (C[3:0] == 4'b1010 )? 7'b0001000:	// A
						  (C[3:0] == 4'b1011 )? 7'b0000011: // B
						  (C[3:0] == 4'b1100 )? 7'b1000110: // C
						  (C[3:0] == 4'b1101 )? 7'b0100001: // D
						  (C[3:0] == 4'b1110 )? 7'b0000110: // E
						  (C[3:0] == 4'b1111 )? 7'b0001110:7'b1111111; // F
endmodule