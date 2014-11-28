module part7 (SW, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, KEY);
   input [3:0] KEY;
   input [17:0] SW;
   output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
  
   wire [15:0] Q;

   flipflop F0 (~KEY[1], SW[0], Q[0], ~KEY[0]);
   flipflop F1 (~KEY[1], SW[1], Q[1], ~KEY[0]);
   flipflop F2 (~KEY[1], SW[2], Q[2], ~KEY[0]);
   flipflop F3 (~KEY[1], SW[3], Q[3], ~KEY[0]);
   flipflop F4 (~KEY[1], SW[4], Q[4], ~KEY[0]);
   flipflop F5 (~KEY[1], SW[5], Q[5], ~KEY[0]);
   flipflop F6 (~KEY[1], SW[6], Q[6], ~KEY[0]);
   flipflop F7 (~KEY[1], SW[7], Q[7], ~KEY[0]);
   flipflop F8 (~KEY[1], SW[8], Q[8], ~KEY[0]);
   flipflop F9 (~KEY[1], SW[9], Q[9], ~KEY[0]);
   flipflop F10 (~KEY[1], SW[10], Q[10], ~KEY[0]);
   flipflop F11 (~KEY[1], SW[11], Q[11], ~KEY[0]);
   flipflop F12 (~KEY[1], SW[12], Q[12], ~KEY[0]);
   flipflop F13 (~KEY[1], SW[13], Q[13], ~KEY[0]);
   flipflop F14 (~KEY[1], SW[14], Q[14], ~KEY[0]);
   flipflop F15 (~KEY[1], SW[15], Q[15], ~KEY[0]);
   
   hex_ssd H0 (SW[3:0], HEX0);
   hex_ssd H1 (SW[7:4], HEX1);
   hex_ssd H2 (SW[11:8], HEX2);
   hex_ssd H3 (SW[15:12], HEX3);
   hex_ssd H4 (Q[3:0], HEX4);
   hex_ssd H5 (Q[7:4], HEX5);
   hex_ssd H6 (Q[11:8], HEX6);
   hex_ssd H7 (Q[15:12], HEX7);
endmodule

module D_latch (Clk, D, Q, Clr);
   input D, Clk, Clr;
   output reg Q;
   always @ (posedge Clk)
     if (Clk)
       Q = D;
 	else
     if (Clr)
       Q = 0;
endmodule

module flipflop (Clk, D, Q, Clr);
   input Clk, D, Clr;
   output Q;
   
   wire Qm;
   D_latch D0 (~Clk, D, Qm, Clr);
   D_latch D1 (Clk, Qm, Q, Clr);
endmodule

module hex_ssd (BIN, SSD);
   output reg [6:0] SSD;
   input [3:0] BIN;
 
   always @(BIN)
     case(BIN)
       4'h0: SSD = ~7'b0111111;
		 4'h1: SSD = ~7'b0000110;
		 4'h2: SSD = ~7'b1011011;
		 4'h3: SSD = ~7'b1001111;
		 4'h4: SSD = ~7'b1100110;
		 4'h5: SSD = ~7'b1101101;
		 4'h6: SSD = ~7'b1111101;
		 4'h7: SSD = ~7'b0000111;
		 4'h8: SSD = ~7'b1111111;
		 4'h9: SSD = ~7'b1100111;
		 4'hA: SSD = ~7'b1110111;
		 4'hB: SSD = ~7'b1111100;
		 4'hC: SSD = ~7'b0111001;
		 4'hD: SSD = ~7'b1011110;
		 4'hE: SSD = ~7'b1111001;
		 4'hF: SSD = ~7'b1110001;
		 default: SSD = ~7'b1111001;
	  endcase
endmodule
