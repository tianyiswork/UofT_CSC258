module part1 (SW, LEDG, LEDR);
	input [8:0] SW;
	output [8:0] LEDR;
	output [4:0] LEDG;
	
	wire x;
	assign x = SW[8:0];
	assign LEDR = SW;

	wire c1, c2, c3;

	full_adder FA0(SW[0], SW[4], SW[8], LEDG[0], c1);
	full_adder FA1(SW[1], SW[5], c1, LEDG[1], c2);
	full_adder FA2(SW[2], SW[6], c2, LEDG[2], c3);
	full_adder FA3(SW[3], SW[7], c3, LEDG[3], LEDG[4]);
endmodule

module full_adder(sum,cout,a,b,cin);
	output sum, cout;
	input a,b,cin;
	wire [3:0]sum;
	wire cout;
	assign {cout, sum} = a+b;
endmodule

