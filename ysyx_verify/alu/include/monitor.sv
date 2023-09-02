`ifndef MONITOR__SV
`define MONITOR__SV

class alu_monitor;

  local string name ;
  virtual in_if  inif;
  virtual out_if outif;
  mailbox #(in_trans)   mntin_mb ;
  mailbox #(out_trans) mntout_mb ;

  function new(string name = "monitor");
    this.name = name;
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    if(inif == null || outif == null)
      $fatal();//("[INTF FATAL]: interface is null in monitor");
    else begin
      this.inif  =  inif  ;
      this.outif = outif  ;
    end
  endfunction

  task run();
    fork
      in_run();
      out_run();
    join
  endtask

  task in_run();
    forever begin
      in_trans trans;
      trans = new();
      @(posedge inif.clk iff(inif.mnt_ck.in_ready && inif.mnt_ck.in_valid));
      trans.in1 = inif.mnt_ck.in1;
      trans.in2 = inif.mnt_ck.in2;
      trans.op  = inif.mnt_ck.op ;
      this.mntin_mb.put(trans);
    end
  endtask

  task out_run();
    forever begin
      out_trans trans;
      trans = new();
      @(posedge outif.clk iff(outif.mnt_ck.out_ready && outif.mnt_ck.out_valid));
      trans.res = outif.mnt_ck.res;
      this.mntout_mb.put(trans);
    end
  endtask

endclass

`endif

