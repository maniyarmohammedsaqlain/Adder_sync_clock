interface inter;
  logic clk;
  logic rst;
  logic [3:0]in1;
  logic [3:0]in2;
  logic [4:0]out;
endinterface


class transaction;
  rand bit[3:0]in1;
  rand bit[3:0]in2;
  bit clk;
  bit rst;
  bit [4:0]out;
  
  function void display(string name,bit clk=0,bit rst=1);
    $display("[%s] Value of in1:%d in2:%d clk:%d rst:%d out:%d",name,in1,in2,clk,rst,out);
  endfunction
endclass

class generator;
  transaction trans;
  mailbox gen2drv;
  int count;
  event done;
  function new(mailbox gen2drv,event done);
    this.gen2drv=gen2drv;
    this.done=done;
  endfunction
  
  task run();
    begin
      repeat(count)
        begin
          trans=new();
          trans.randomize();
          trans.display("GEN");
          gen2drv.put(trans);
          #1;
          ->done;
          #45;
        end
    end
  endtask
endclass

class driver;
  transaction trans;
  mailbox gen2drv;
  event done;
  event mon_done; 
  virtual inter inf;
  
  function new(mailbox gen2drv, virtual inter inf, event done, event mon_done);
    this.gen2drv = gen2drv;
    this.inf = inf;
    this.done = done;
    this.mon_done = mon_done;
  endfunction
  
  task reset();
    begin
      inf.rst <= 0;
      @(posedge inf.clk);
      inf.rst <= 1;
      $display("DUT RESET DONE");
    end
  endtask
  
  task run();
    forever
      begin
        @(done);              
        @(posedge inf.clk);   
        trans = new();
        gen2drv.get(trans);
        inf.in1 = trans.in1;
        inf.in2 = trans.in2;
        inf.rst = 1;
        trans.display("DRV", inf.rst, inf.clk);
        
        #1;                   
        -> mon_done;          
        #10;
      end
  endtask
endclass



class monitor;
  transaction trans;
  mailbox mon2scb;
  event mon_done;       
  virtual inter inf;
  
  function new(mailbox mon2scb, virtual inter inf, event mon_done);
    this.mon2scb = mon2scb;
    this.inf = inf;
    this.mon_done = mon_done;
  endfunction
  
  task run();
    forever
      begin
        @(mon_done);          
        @(posedge inf.clk);
        #1;
        trans = new();
        trans.in1 = inf.in1;
        trans.in2 = inf.in2;
        trans.rst = inf.rst;
        trans.clk = inf.clk;
        trans.out = inf.out;
        trans.display("MON", inf.rst, inf.clk);
        mon2scb.put(trans);
        #10;
      end
  endtask
endclass

class scoreboard;
  mailbox mon2scb;
  transaction trans;
  function new(mailbox mon2scb);
    this.mon2scb=mon2scb;
  endfunction
  
  task run();
    forever
      begin
        mon2scb.get(trans);
        if((trans.in1+trans.in2==trans.out))
          begin
          	$display("MATCHED");
        	$display("---------------------------------------------------------------------------------------------------------------------------");
          end
        else
          $display("FAILED");
      end
  endtask
endclass
        

class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;
  mailbox gen2drv;
  mailbox mon2scb;
  event done;
  event mon_done;   

  function new(virtual inter inf);
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv, done);
    gen.count = 10;
    drv = new(gen2drv, inf, done, mon_done); 
    mon = new(mon2scb, inf, mon_done);
    scb=new(mon2scb);
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test;
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join
  endtask
  
  task run();
    begin
      pre_test();
      test();
    end
  endtask
endclass

  
  
module tb;
  environment env;
  inter inf();
  
  adder add(inf.clk,inf.rst,inf.in1,inf.in2,inf.out);
  
  initial
    begin
      inf.clk=0;
    end
  always
    #10 inf.clk=~inf.clk;
  
  initial
    begin
      env=new(inf);
      env.run();
    end
  
  initial
    begin
      #1000;
      $finish();
    end
  
    
  
endmodule
    
