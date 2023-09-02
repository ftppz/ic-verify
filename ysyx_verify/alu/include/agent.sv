// agent.sv

`ifndef AGENT__SV
`define AGENT__SV

class alu_agent;

  local string name;

  alu_driver   driver  ;
  alu_monitor  monitor ;

  virtual  in_if  inif ;
  virtual out_if outif ;

  mailbox #(in_trans)   inreq_mb;
  mailbox #(in_trans)   inrsp_mb;
  mailbox #(out_trans) mntout_mb;
  mailbox #(in_trans)   mntin_mb;

  function new(string name = "agent");
    this.name   = name;
    this.driver = new({name,".driver "});
    this.monitor= new({name,".monitor"});
  endfunction

  function void do_config();
    this.driver.inreq_mb   = this.inreq_mb  ;
    this.driver.inrsp_mb   = this.inrsp_mb  ;
    this.monitor.mntin_mb  = this.mntin_mb  ;
    this.monitor.mntout_mb = this.mntout_mb ;
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    this.inif = inif;
    driver.set_interface(inif, outif);
    monitor.set_interface(inif, outif);
  endfunction

  task run();
    fork
      driver.run();
      monitor.run();
    join
  endtask

endclass

`endif

