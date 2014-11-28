module part2 (SW, LEDR, LEDG);

	input [17:0] SW; 
	output [17:0] LEDR; 
	output [7:0] LEDG; 
	
	wire X, Y, S, M;
	assign X = SW[7:0];
	assign S = SW[17];
	assign Y = SW[15:8];
	assign LEDR = SW;
	assign M = LEDG[7:0];
	assign M = (~S & X)|(S & Y);
	
endmodule