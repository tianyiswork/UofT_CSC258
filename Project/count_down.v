module count_down(A, clock_50, display_0, display_1, time_out);
 input [1:0] A;
 input clock_50;
 output [6:0] display_0, display_1;
 output time_out;
 wire [4:0] Q, digits, tens;
 wire del_1sec;
 
 delay_1s delay1(clock_50, del_1sec);
 
// reg [4:0] number;
// wire reset;
// 
// always @ (posedge del_1sec, posedge reset)
// begin
//  if (reset) 
//  begin
//   number = 30;
//  end
//  else
//  begin
//   number = number -1;
//  end
// end
// 
 t_flipflop tff0(~A[1], del_1sec, ~A[0], Q[0]);
 t_flipflop tff1((~A[1] & Q[0]), del_1sec, ~A[0], Q[1]);
 t_flipflop tff2((~A[1] & Q[0] & Q[1]), del_1sec, ~A[0], Q[2]);
 t_flipflop tff3((~A[1] & Q[0] & Q[1] & Q[2]), del_1sec, ~A[0], Q[3]);
 t_flipflop tff4((~A[1] & Q[0] & Q[1] & Q[2]& Q[3]), del_1sec, ~A[0], Q[4]);
 
 bin_to_decimal con1(Q, digits, tens);
 

 dec_7seg dec1(digits, display_0);





 dec_7seg dec2((5'b00011 - tens), display_1);

assign time_out = ((display_1 == 7'b1000000) & (display_0 == 7'b1000000));




// dec_7seg dec1(digits, HEX0);
// dec_7seg dec2(tens, HEX1);
endmodule

module delay_1s(Clk, delay);
 input Clk;
 output reg delay;
 
 reg [25:0] count;
 
 always @ (posedge Clk)
  begin
  if (count==26'd49_999_999)
   begin
    count <= 26'd0;
    delay <= 1;
   end
  else
   begin
    count <= count+1;
    delay <= 0;
   end
  end
endmodule

module t_flipflop(t, Clk, rst, Q);
 input t, Clk, rst;
 output reg Q;
 always @ (posedge Clk)
  begin
  if (~rst)
   Q <= 1'b0;
  else if (t)
   Q <= Q+1;
  end
endmodule

module bin_to_decimal (bin, dec_digit, dec_ten);
 input[4:0] bin;
 output [4:0] dec_digit;
 output [4:0] dec_ten;

 assign dec_digit = (bin< 5'b00001)? 5'b00000:
       (bin< 5'b01010)? (5'b01010 - bin) :
       (bin< 5'b01011)? 5'b00000:
       (bin< 5'b10100)? (5'b10100 - bin):
       (bin< 5'b10101)? 5'b00000:
       (bin< 5'b11110)? (5'b11110 - bin):
       (bin< 5'b11111)? 5'b00000: 5'b00000;    
       
 assign dec_ten = (bin< 5'b00001)? 5'b00000:
       (bin< 5'b01011)? 5'b00001: 
      (bin< 5'b10101)? 5'b00010:
       (bin< 5'b11110)? 5'b00011: 
      (bin< 5'b11111)? 5'b00011: 5'b00000;
           
// assign dec_digit = (bin< 5'b01010)? 5'b00000 :




//       (bin< 5'b10100)? (bin - 5'b01010):
//       (bin< 5'b11110)? (bin - 5'b10100):
//       (bin< 5'b11111)? (bin - 5'b11101): 5'b00000;
//       
// assign dec_ten = (bin< 5'b01010)? 5'b00000: 
//       (bin< 5'b10100)? 5'b00001:
//       (bin< 5'b11110)? 5'b00010: 
//       (bin< 5'b11111)? 5'b00011: 5'b00000;
endmodule


module dec_7seg (C, Display);
 input [3:0] C;
 output [6:0]Display;
 
 assign Display = (C[3:0]==4'b0000)? 7'b1000000:
       (C[3:0]==4'b0001)? 7'b1111001:
       (C[3:0]==4'b0010)? 7'b0100100:
       (C[3:0]==4'b0011)? 7'b0110000:
       (C[3:0]==4'b0100)? 7'b0011001:
       (C[3:0]==4'b0101)? 7'b0010010:
       (C[3:0]==4'b0110)? 7'b0000010:
       (C[3:0]==4'b0111)? 7'b1111000:
       (C[3:0]==4'b1000)? 7'b0000000:
       (C[3:0]==4'b1001)? 7'b0010000: 7'b1111111;
endmodule

