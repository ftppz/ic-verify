// base_test.sv

`ifndef BASE_TEST__SV
`define BASE_TEST__SV

class base_test;

  protected string name;
  local int timeout = 20;

  alu_generator generator;
  alu_env       env      ;

  function new(string name = "base_test");
    this.name = name;
    this.generator = new({name, ".generator"});
    this.env       = new({name, ".environment"});
  endfunction

  function void do_config();
    this.env.inreq_mb = this.generator.inreq_mb;
    this.env.inrsp_mb = this.generator.inrsp_mb;
    this.env.do_config();
    rpt_pkg::logname = {this.name, "_ckeck.log"};
    rpt_pkg::clean_log();
    $display("$s instantiated and connected objects", this.name);
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    this.env.set_interface(inif, outif);
  endfunction

  virtual task run();
    fork
      this.env.run();
    join_none
    rpt_pkg::rpt_msg("[TEST]",
      $sformatf("=====================%s AT TIME %0t STARTED=====================", this.name, $time),
      rpt_pkg::INFO,
      rpt_pkg::HIGH);
    fork
      this.do_data();
      this.do_watchdog();
    join_any
    rpt_pkg::rpt_msg("TEST",
      $sformatf("=====================%s AT TIME %0t FINISHED=====================", this.name, $time),
      rpt_pkg::INFO,
      rpt_pkg::HIGH);
    this.do_report(); 
    $finish();
  endtask

  virtual task do_watchdog();
  rpt_pkg::rpt_msg("[TEST]",
    $sformatf("=====================%s AT TIME %0t WATCHDOG GUARDING=====================", this.name, $time),
    rpt_pkg::INFO,
    rpt_pkg::HIGH
  );
  #(this.timeout * 1ms);
  rpt_pkg::rpt_msg("[TEST]",
    $sformatf("=====================%s AT TIME %0t WATCHDOG BARKING=====================", this.name, $time),
    rpt_pkg::INFO,
    rpt_pkg::HIGH
  );
  endtask


  virtual function void do_report();
    this.env.do_report();
    rpt_pkg::do_report();
  endfunction


  virtual task do_data();
  endtask

endclass

class op_test extends base_test;

  function new(string name = "op_test");
    super.new(name);
  endfunction

  virtual task do_data();
      generator.start(10000);
	  #10us;
  endtask
  
endclass

`endif

