module part3 (En, Clk, Clr, Q);
  input En, Clk, Clr;
  output [3:0] Q;

  wire [3:0] T, Qs;

  t_flipflop T0 (En, Clk, Clr, Qs[0]);
  assign T[0] = En & Qs[0];

  t_flipflop T1 (T[0], Clk, Clr, Qs[1]);
  assign T[1] = T[0] & Qs[1];

  t_flipflop T2 (T[1], Clk, Clr, Qs[2]);
  assign T[2] = T[1] & Qs[2];

  t_flipflop T3 (T[2], Clk, Clr, Qs[3]);
  assign T[3] = T[2] & Qs[3];

  assign Q = Qs;
endmodule

module t_flipflop (En, Clk, Clr, Q);
  input En, Clk, Clr;
  output reg Q;

  always @ (posedge Clk)
    if (Clr)
      Q = 0;
    else if (En)
      Q <= Q + 1;

endmodule
