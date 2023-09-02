`ifndef COVERAGE__SV
`define COVERAGE__SV

class alu_coverage;
  local virtual in_if inif;
  local string name;

  covergroup  op_group;
    op: coverpoint inif.op{
      bins  op_add = {3'b000};
      bins  op_sub = {3'b001};
      bins  op_and = {3'b110};
      bins  op_or  = {3'b111};
      bins  op_xor = {3'b010};
    }
  endgroup

  function new(string name="coverage");
    this.name = name;
    this.op_group = new();
  endfunction

  task run();
    fork
      this.op_sample();
    join
  endtask

  task op_sample();
    forever begin
      @(posedge inif.clk iff inif.rstn);
      if(inif.in_valid && inif.in_ready)
        this.op_group.sample();
    end
  endtask

  virtual function void set_interface(virtual in_if inif);
    if(inif == null)
      $error("[error]:coverage interface is NULL!!!");
    else
      this.inif = inif;
  endfunction

  function void do_report();
    string s;
    s = "\n---------------------------------------------------------------\n";
    s = {s, "COVERAGE SUMMARY \n"}; 
    s = {s, $sformatf("total coverage: %.1f \n", $get_coverage())}; 
    s = {s, $sformatf("op_group coverage: %.1f \n", this.op_group.get_coverage())}; 
    s = {s, "---------------------------------------------------------------\n"};
    rpt_pkg::rpt_msg($sformatf("[%s]",this.name), s, rpt_pkg::INFO, rpt_pkg::TOP);
  endfunction

endclass

`endif

