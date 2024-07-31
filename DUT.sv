module adderclock(a,b,clk,out);
  input [7:0]a;
  input [7:0]b;
  input clk;
  output reg [8:0]out;
  always@(posedge clk)
    out=a+b;
endmodule
