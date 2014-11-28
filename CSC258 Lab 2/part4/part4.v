module part4 (SW, LEDG, LEDR, HEX1, HEX0);
	input [17:0] SW;
	output [8:0] LEDR, LEDG;
	output [0:6] HEX1, HEX0;

	assign LEDR[8:0] = SW[8:0];

	wire e1, e2;

	comparator C0 (SW[3:0], e1);
	comparator C1 (SW[7:4], e2);

	assign LEDG[8] = e1 | e2;

	wire c1, c2, c3;
	wire [4:0] S;

	full_adder FA0(SW[0], SW[4], SW[8], LEDG[0], c1);
	full_adder FA1(SW[1], SW[5], c1, LEDG[1], c2);
	full_adder FA2(SW[2], SW[6], c2, LEDG[2], c3);
	full_adder FA3(SW[3], SW[7], c3, LEDG[3], LEDG[4]);
  
	assign LEDG[4:0] = S[4:0];

	wire z;
	wire [3:0] A, M;

	comparator9 C2 (S[4:0], z);
	circuitA AA (S[3:0], A);
	mux_4bit_2to1 M0 (z, S[3:0], A, M);
	circuitB BB (z, HEX1);
	b2d_7seg S0 (M, HEX0);

endmodule

module full_adder(sum,cout,a,b,cin);
	output sum, cout;
	input a,b,cin;
	assign sum = a^b^cin;
	assign cout = (a&b)|(cin&(a|b));
	
endmodule

module b2d_7seg (SW, HEX0);
	input [3:0] SW;
	output [0:6] HEX0;

	assign HEX0[0]=(~SW[3] & ~SW[2] & ~SW[1] &  SW[0])|(~SW[3] &  SW[2] & ~SW[1] & ~SW[0]);
	assign HEX0[1]=(~SW[3] &  SW[2] & ~SW[1] &  SW[0])|(~SW[3] &  SW[2] &  SW[1] & ~SW[0]);
	assign HEX0[2]=(~SW[3] & ~SW[2] &  SW[1] & ~SW[0]);
	assign HEX0[3]=(~SW[3] & ~SW[2] & ~SW[1] &  SW[0])|(~SW[3] &  SW[2] & ~SW[1] & ~SW[0])|
						(~SW[3] &  SW[2] & SW[1] & SW[0])|(SW[3] & ~SW[2] & ~SW[1] & SW[0]);
	assign HEX0[4]=~((~SW[2] & ~SW[0]) | (SW[1] & ~SW[0]));
	assign HEX0[5]=(~SW[3] & ~SW[2] & ~SW[1] &  SW[0])|(~SW[3] & ~SW[2] &  SW[1] & ~SW[0])|
						(~SW[3] & ~SW[2] & SW[1] & SW[0])|(~SW[3] & SW[2] & SW[1] & SW[0]);
	assign HEX0[6]=(~SW[3] & ~SW[2] & ~SW[1] &  SW[0])|(~SW[3] & ~SW[2] & ~SW[1] & ~SW[0])|
						(~SW[3] &  SW[2] & SW[1] & SW[0]);
endmodule

module comparator (V, z);
	input [3:0] V;
	output z;

	assign z = (V[3] & (V[2] | V[1]));
endmodule

module comparator9 (V, z);
	input [4:0] V;
	output z;

	assign z = V[4] | ((V[3] & V[2]) | (V[3] & V[1]));
endmodule

module circuitA (V, A);
	input [3:0] V;
	output [3:0] A;

	assign A[0] = V[0];
	assign A[1] = ~V[1];
	assign A[2] = (~V[3] & ~V[1]) | (V[2] & V[1]);
	assign A[3] = (~V[3] & V[1]);
endmodule

module circuitB (z, HEX1);
	input z;
	output [0:6] HEX1;

	assign HEX1[0] = z;
	assign HEX1[1:2] = 2'b00;
	assign HEX1[3:5] = {3{z}};
	assign HEX1[6] = 1;
endmodule

module mux_4bit_2to1 (s, U, V, M);

	input s;
	input [3:0] U, V;
	output [3:0] M;

	assign M = ({4{~s}} & U) | ({4{s}} & V);
endmodule

