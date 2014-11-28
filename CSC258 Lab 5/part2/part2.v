module part2(SW, KEY, LEDR, HEX0, HEX1, HEX2);
   input [17:0] SW;
	input [3:0] KEY;
   output [17:0] LEDR;
	output [6:0] HEX0, HEX1, HEX2;
	
	accumulator acm (SW[8:0], LEDR[7:0], LEDR[8], KEY[0], KEY[1]);
endmodule

module accumulator (A, out , overflow, clk, clr);
	input [8:0] A;
	input clk, clr;
	output [7:0]out;
   reg [7:0] accum;
	output reg overflow;
	assign out= accum;
	//reg [7:0] accum2;
	//reg [7:0] overflow;
				
	always @ (posedge clk) begin
		{overflow, accum} = accum + A;
	end
endmodule
