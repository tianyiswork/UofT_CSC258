module part4 (SW, LEDR, HEX3, HEX2, HEX1, HEX0);
	input [17:0] SW;
   output [17:0] LEDR;
   output [6:0] HEX3, HEX2, HEX1, HEX0;

	wire [7:0] p;
   multiplier M0 (SW[11:8], SW[3:0], p);
  
	assign LEDR = p;

	hex_7seg H0 (SW[3:0], HEX0);
   hex_7seg H1 (SW[11:8], HEX1);
	hex_7seg H2 (p[3:0], HEX2);
	hex_7seg H3 (p[7:4], HEX3);
endmodule

// implements a 4-bit by 4-bit multiplier with 8-bit result
module multiplier (A, B, P);
   input [3:0] A, B;
   output [7:0] P;
 
   wire c01, c02, c03, c04;
   wire s02, s03, s04;

   wire c12, c13, c14, c15;
   wire s13, s14, s15;

   wire c23, c24, c25, c26;

   assign P[0] = A[0] & B[0];

   fulladder F01 (A[1] & B[0], A[0] & B[1], 0, P[1], c01);
   fulladder F02 (A[2] & B[0], A[1] & B[1], c01, s02, c02);
   fulladder F03 (A[3] & B[0], A[2] & B[1], c02, s03, c03);
   fulladder F04 (0, A[3] & B[1], c03, s04, c04);

   fulladder F12 (s02, A[0] & B[2], 0, P[2], c12);
   fulladder F13 (s03, A[1] & B[2], c12, s13, c13);
   fulladder F14 (s04, A[2] & B[2], c13, s14, c14);
   fulladder F15 (c04, A[3] & B[2], c14, s15, c15);

   fulladder F23 (s13, A[0] & B[3], 0, P[3], c23);
   fulladder F24 (s14, A[1] & B[3], c23, P[4], c24);
   fulladder F25 (s15, A[2] & B[3], c24, P[5], c25);
   fulladder F26 (c15, A[3] & B[3], c25, P[6], P[7]);
endmodule

module fulladder (a, b, ci, s, co);
   input a, b, ci;
   output co, s;
 
   wire d;

   assign d = a ^ b;
   assign s = d ^ ci;
   assign co = (b & ~d) | (d & ci);
endmodule

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

