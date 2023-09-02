//driver.sv
`ifndef DRIVER__SV
`define DRIVER__SV

class alu_driver;

  local string name;

  rand int nidles;

  constraint cstrnt{
    nidles inside {[0:200]};
  };

  virtual   in_if  inif  ;
  virtual  out_if outif  ;

  mailbox #( in_trans)   inreq_mb;
  mailbox #( in_trans)   inrsp_mb;

  function new(string name = "driver");
    this.name = name;
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    if(inif == null || outif == null)
      $error({name, " : if is null!"});
    else begin
      this.inif = inif;
      this.outif = outif;
    end
  endfunction

  task run();
    fork
      this.in_drive();
      this.out_drive();
      this.in_reset();
      this.out_reset();
    join
  endtask

  task  in_drive();
    @(posedge inif.rstn);
    forever begin
      in_trans req;
      inreq_mb.get(req);
      repeat(req.nidles) @(posedge inif.clk);
      inif.drv_ck.in_valid <= 1'b1;
      inif.drv_ck.in1      <= req.in1;
      inif.drv_ck.in2      <= req.in2;
      inif.drv_ck.op       <= req.op ;
      @(posedge inif.clk iff (inif.in_ready === 1'b1));
      fork begin
        //@(posedge inif.clk);
        inif.drv_ck.in_valid <= 1'b0;
        inif.drv_ck.in1   <=  'b0;
        inif.drv_ck.in2   <=  'b0;
        inif.drv_ck.op    <=  'b0;
      end
      join_none
      req.rsp = 1;
      inrsp_mb.put(req);
    end
  endtask

  task out_drive();
    @(posedge outif.rstn);
    forever begin
      @(posedge outif.clk);
	  outif.drv_ck.out_ready <= 1'b0;
	  wait(outif.out_valid === 1'b1);
      assert(this.randomize())
        else $fatal({name," : RAND FAIL"});
      repeat(this.nidles) @(posedge outif.clk);
      outif.drv_ck.out_ready <= 1'b1;
    end
  endtask

  task in_reset();
    forever begin
      @(posedge inif.clk iff(!inif.rstn));
      inif.drv_ck.in_valid <= 1'b0;
      inif.drv_ck.in1      <=  'b0;
      inif.drv_ck.in2      <=  'b0;
      inif.drv_ck.op       <=  'b0;
    end
  endtask

  task out_reset();
    forever begin
      @(posedge outif.clk iff(!outif.rstn));
      outif.drv_ck.out_ready <= 1'b0;
    end
  endtask
  
endclass

`endif
