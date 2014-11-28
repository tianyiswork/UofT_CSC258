module part3 (SW, HEX0, HEX1, HEX2, HEX3);
  input [17:0] SW;
  output [0:6] HEX0, HEX1, HEX2, HEX3;

  wire z;
  wire [3:0] M, A;
  assign A[3] = 0;

  comparator C0 (SW[3:0], z);
  circuitA A0 (SW[3:0], A[2:0]);
  mux_4bit_2to1 M0 (z, SW[3:0], A, M);
  circuitB B0 (z, HEX1);
  b2d_7seg S0 (M, HEX0);
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

module circuitA (V, A);
  input [2:0] V;
  output [2:0] A;

  assign A[0] = V[0];
  assign A[1] = ~V[1];
  assign A[2] = (V[2] & V[1]);
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

