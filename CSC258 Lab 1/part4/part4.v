module part4(HEX0, SW);
	input[0:2]SW;
	output[0:6]HEX0;
	wire [0:6] H0;
	
	assign H0[0] = (~SW[0] & ~SW[1] & SW[2])| (~SW[0] & SW[1] & ~SW[2])| (~SW[0] & SW[1] & SW[2]);
	assign H0[1] = (~SW[0] & ~SW[1] & ~SW[2])|(~SW[0] & ~SW[1] & SW[2])|(~SW[0] & SW[1] & ~SW[2])|
						(~SW[0] & SW[1] & SW[2])|(SW[0] & ~SW[1] & ~SW[2]);
	assign H0[2] = (~SW[0] & ~SW[1] & ~SW[2])|(~SW[0] & ~SW[1] & SW[2])|(SW[0] & ~SW[1] & ~SW[2]);
	assign H0[3] = (SW[0] & ~SW[1] & ~SW[2]);
	assign H0[4] = (~SW[0] & ~SW[1] & ~SW[2])|(~SW[0] & ~SW[1] & SW[2])|(~SW[0] & SW[1] & ~SW[2])|
						(~SW[0] & SW[1] & SW[2]);
	assign H0[5] = (~SW[0] & ~SW[1] & ~SW[2])|(~SW[0] & ~SW[1] & SW[2])|(~SW[0] & SW[1] & ~SW[2])|
						(~SW[0] & SW[1] & SW[2])|(SW[0] & ~SW[1] & ~SW[2]);
	assign H0[6] = (~SW[0] & ~SW[1] & ~SW[2])|(~SW[0] & ~SW[1] & SW[2])|(~SW[0] & SW[1] & ~SW[2])|
						(~SW[0] & SW[1] & SW[2])|(SW[0] & ~SW[1] & ~SW[2]);
	
	assign HEX0 = ~H0;
endmodule

