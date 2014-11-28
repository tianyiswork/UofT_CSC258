module part2 (SW, KEY, HEX1, HEX0);
		input [1:0] SW;
		input [1:0] KEY;
		output [6:0] HEX1, HEX0;
		
		wire [3:0] Q, digits, tens;
		t_flip_flop tff1 (SW[1], KEY[0], SW[0], Q[0]);
		t_flip_flop tff2 ((SW[1] & Q[0]), KEY[0], SW[0], Q[1]);
		t_flip_flop tff3 ((SW[1] & Q[0] & Q[1]), KEY[0], SW[0], Q[2]);
		t_flip_flop tff4 ((SW[1] & Q[0] & Q[1] & Q[2]), KEY[0], SW[0], Q[3]);

		// Convert from binary to decimal.
		bin_to_decimal con1 (Q, digits, tens);
		// Display the 4-bit number in a decimal format.
		dec_7seg dec1 (digits, HEX0);
		dec_7seg dec2 (tens, HEX1);
endmodule


module t_flip_flop (T, Clk, Rst, Q);
   input T, Clk, Rst;
   output reg Q;
	always @ (posedge Clk)
   begin
      if (~Rst)
         Q = 1'b0;
                        
      else if (T)
         Q = ~Q;
end
endmodule

module bin_to_decimal (bin, dec_digit, dec_ten);
   input [3:0] bin;
   output [3:0] dec_digit, dec_ten;
	assign dec_digit = (bin < 4'b1010) ? bin : (bin - 4'b1010);
   assign dec_ten = (bin < 4'b1010) ? 4'b0000 : 4'b0001;
endmodule

module dec_7seg (C, Display);
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
						  (C[3:0] == 4'b1001 )? 7'b0010000: 7'b1111111; // 9
endmodule
