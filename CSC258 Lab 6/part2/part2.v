module part2(KEY, SW, LEDG, LEDR);
   input [1:0] SW;
   input [1:0] KEY;
   output [1:0] LEDG;
   output [8:0] LEDR;
	
	assign LEDG[0] = ((Q == 4'b1111) | (Q == 4'b1010)) ? 1'b1 : 1'b0;
   
	wire [3:0] Q;
	
	d_flip_flop dff3 (((SW[1]) | (Q[2] & Q[0])), KEY[0], SW[0], Q[3]);
   d_flip_flop dff2 (((~Q[3] & SW[1]) | (Q[1] & Q[0]) | (SW[1] & Q[2] & Q[1])), KEY[0], SW[0], Q[2]);
   d_flip_flop dff1 (((~Q[2] & SW[1]) | (Q[0])), KEY[0], SW[0], Q[1]);
   d_flip_flop dff0 (~SW[1], KEY[0], SW[0], Q[0]);
	convert con1 (Q, LEDR[8:0]);
endmodule

module d_flip_flop (D, Clk, Rst, Q);
	input D, Clk, Rst;
	output reg Q;
	always @ (posedge Clk or negedge Rst)
		begin
			if (~Rst)
				Q <= 1'b1;
			else
				Q = D;
		end
endmodule

// convert a 4-bit input to the state code
module convert (x, y);
	input [3:0] x;
	output [8:0] y;
	assign y = (x[3:0] == 4'b0000 )? 9'b000000001: // state A
					(x[3:0] == 4'b0001 )? 9'b000000010: // state B
					(x[3:0] == 4'b0011 )? 9'b000000100: // state C
               (x[3:0] == 4'b0111 )? 9'b000001000: // state D
               (x[3:0] == 4'b1111 )? 9'b000010000: // state E
               (x[3:0] == 4'b1110 )? 9'b000100000: // state F
               (x[3:0] == 4'b1100 )? 9'b001000000: // state G
               (x[3:0] == 4'b1000 )? 9'b010000000: // state H
               (x[3:0] == 4'b1010 )? 9'b100000000: 9'b111111111; // state I
endmodule
