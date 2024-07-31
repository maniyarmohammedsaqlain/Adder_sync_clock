interface adderclock_int;
  logic [7:0]a;
  logic [7:0]b;
  logic clk;
  logic [8:0]out;
endinterface

class transaction;
  rand logic[7:0]a;
  rand logic[7:0]b;
  
  rand logic clk;
  logic[8:0]out;
    
endclass

class generator;
  mailbox gen2drv;
  transaction trans;
  
  function new(mailbox gen2drv);
    this.gen2drv=gen2drv;
  endfunction
  
  task main();
    
      
        for(int i=0;i<10;i++)
          begin
            trans=new();
            
            assert(trans.randomize())
              $display("%t [GEN] GENERATED DATA OF A IS %d,B IS %d,CLK IS %d and ",$time,trans.a,trans.b,trans.clk);
            else
              $display("FAILED TO GENERATE");
            gen2drv.put(trans);
            #10;
          end
      
  endtask
endclass

class driver;
  transaction trans;
  mailbox gen2drv;
  virtual adderclock_int acif;
  function new(mailbox gen2drv);
    this.gen2drv=gen2drv;
  endfunction
  
  task main();
    forever
      begin
        gen2drv.get(trans);
        acif.a=trans.a;
        acif.b=trans.b;
        acif.clk=trans.clk;
        $display("%t VALUE SENT TO INTERFACE",$time);
        #10;
      end
  endtask
endclass
    
  
class monitor;
  transaction trans;
  virtual adderclock_int acif;
  mailbox mon2sco;
  
  function new(mailbox mon2sco);
    this.mon2sco=mon2sco;
  endfunction
  
  task main();
    repeat(10) 
      begin
        trans=new();
        trans.a=acif.a;
        trans.b=acif.b;
        trans.clk=acif.clk;
        trans.out=acif.out;
        $display("%t ---------------RECIEVED DATA FROM DUT OF A IS %d B IS %d CLK IS %d and OUT IS %d----------------",$time,trans.a,trans.b,trans.clk,trans.out);
        mon2sco.put(trans);
        #10;
      end
    
  endtask
endclass

class scoreboard;
  mailbox mon2sco;
  transaction trans;
  function new(mailbox mon2sco);
    this.mon2sco=mon2sco;
  endfunction
  
  task main();
    repeat(10)
      begin
        trans=new();
        mon2sco.get(trans);
          begin
            if(trans.a+trans.b==trans.out)
              $display("%t PASSED",$time);
            else
              $display("%t FAILED",$time);
            #10;
          end
      end
  endtask
endclass
       
            
  



module tb();
  mailbox gen2drv;
  mailbox mon2sco;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  adderclock_int acif();
  adderclock a1(.a(acif.a),.b(acif.b),.clk(acif.clk),.out(acif.out));
  initial
    begin
      gen2drv=new();
      mon2sco=new();
      gen=new(gen2drv);
      drv=new(gen2drv);
      mon=new(mon2sco);
      sco=new(mon2sco);
      drv.acif=acif;
      mon.acif=acif;
      fork
         #5 gen.main();
         #5 drv.main();
         #10 mon.main();
         #15 sco.main();
      join
    end
endmodule  
