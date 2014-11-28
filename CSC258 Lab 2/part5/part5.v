module part5 (SW, LEDR, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
	input [15:0] SW;
	output [15:0] LEDR;
	output [0:6] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

	assign LEDR[15:0] = SW[15:0];

	reg [4:0] T1, T0;
	reg [3:0] Z1, Z0, S2, S1, S0;
	reg c2, c1;

	always begin
		T0 = SW[3:0] + SW[11:8];
		if (T0 > 9) begin
			Z0 = 10;
			c1 = 1;
		end else begin
			Z0 = 0;
			c1 = 0;
		end
		S0 = T0 - Z0;

		T1 = SW[7:4] + SW[15:12] + c1;
		if (T1 > 9) begin
			Z1 = 10;
			c2 = 1;
		end else begin
			Z1 = 0;
			c2 = 0;
		end
		S1 = T1 - Z1;
		S2 = c2;
	end

	b2d_7seg H0 (S0, HEX0);
	b2d_7seg H1 (S1, HEX1);
	b2d_7seg H2 (S2, HEX2);
	assign HEX3 = 7'b1111111;
	b2d_7seg H4 (SW[3:0], HEX4);
	b2d_7seg H5 (SW[7:4], HEX5);
	b2d_7seg H6 (SW[11:8], HEX6);
	b2d_7seg H7 (SW[15:12], HEX7);
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


