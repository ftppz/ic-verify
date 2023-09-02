// env.sv

`ifndef ENV__SV
`define ENV__SV

class alu_env;

  protected string name;

  alu_agent         agent;
  alu_checker       check;
  alu_refmod       refmod;
  alu_coverage   coverage;

  mailbox #(in_trans)  inreq_mb;
  mailbox #(in_trans)  inrsp_mb;
  mailbox #(out_trans) mntout_mb;
  mailbox #(in_trans)  mntin_mb;

  function new(string name = "environment");
    this.name = name;
    this.agent  = new({name, ".agent" });
    this.check  = new({name, ".check" });
	this.refmod = new({name, ".refmod"});
    this.coverage = new();
  endfunction

  function void do_config();
    this.check.refmod_mb = this.refmod.refmod_mb;
    this.mntin_mb  = this.refmod.mntin_mb ;
	this.mntout_mb = this.check.mntout_mb;
    this.agent.inreq_mb = this.inreq_mb;
    this.agent.inrsp_mb = this.inrsp_mb;
    this.agent.mntout_mb= this.mntout_mb;
    this.agent.mntin_mb = this.mntin_mb;
    this.agent.do_config();
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    this.agent.set_interface(inif, outif);
    this.coverage.set_interface(inif);
  endfunction

  task run();
    fork
      this.agent.run();
      this.check.run();
	  this.refmod.run();
      this.coverage.run();
    join
  endtask

  virtual function void do_report();
    this.check.do_report();
    this.coverage.do_report();
  endfunction

endclass

`endif
