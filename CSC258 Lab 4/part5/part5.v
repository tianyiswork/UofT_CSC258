module part5 (KEY, HEX0);
	input [1:0] KEY;
	output [6:0] HEX0;
	//	wire [3:0] Q, digits, tens;
	reg [0:3] Q = 4'b1111;
	always @ (posedge KEY[0])
		Q <= {Q[3]^Q[2], Q[0:2]};
		// Display the 4-bit number in a decimal format.
		hex_7seg dec0 (Q, HEX0);
		//	// Instantiate four D flip-flops.
		//	d_flip_flop dff0 ((Q[2] ^ Q[3]), KEY[0], KEY[1], Q[0]);
		//	d_flip_flop dff1 (Q[0], KEY[0], KEY[1], Q[1]);
		//	d_flip_flop dff2 (Q[1], KEY[0], KEY[1], Q[2]);
		//	d_flip_flop dff3 (Q[2], KEY[0], KEY[1], Q[3]);
		//	Convert from binary to decimal.
		//	bin_to_decimal con1 (Q, digits, tens);
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
						  (C[3:0] == 4'b1010 )? 7'b0001000: // A
						  (C[3:0] == 4'b1011 )? 7'b0000011: // B
						  (C[3:0] == 4'b1100 )? 7'b1000110: // C
						  (C[3:0] == 4'b1101 )? 7'b0100001: // D
						  (C[3:0] == 4'b1110 )? 7'b0000110: // E
						  (C[3:0] == 4'b1111 )? 7'b0001110:7'b1111111; // F
endmodule
