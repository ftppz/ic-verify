// checker.sv

`ifndef CHECKER__SV
`define CHECKER__SV


class alu_checker;

  local string name;

  local int err_count;
  local int total_count;

  mailbox #(out_trans)  refmod_mb;
  mailbox #(out_trans)  mntout_mb;

  function new(string name = "checker");
    this.name = name;
    this.mntout_mb = new();
    this.err_count   = 0;
    this.total_count = 0;
  endfunction

  function void do_config();
  endfunction

  task run();
    forever begin
      out_trans real_trans;
	  out_trans refe_trans;
	  this.mntout_mb.get(real_trans);
      this.refmod_mb.get(refe_trans);
	  this.total_count++;

      if(real_trans.res != refe_trans.res) begin
        this.err_count++;
        rpt_pkg::rpt_msg("[CMPFAIL]",
          $sformatf("%0tns %0dth times check but fauled, right: %h, wrong: %h\n", $time, this.total_count, refe_trans.res, real_trans.res),
          rpt_pkg::ERROR,
          rpt_pkg::TOP  ,
          rpt_pkg::LOG );
      end else begin
        rpt_pkg::rpt_msg("[CMPSUCD]",
          $sformatf("%0tns %0dth times check and succeed\n", $time, this.total_count ),
          rpt_pkg::INFO ,
          rpt_pkg::HIGH);
      end
    end
  endtask

  function void do_report();
    string s;
    s = "\n---------------------------------------------------------------\n";
    s = {s, "CHECKER SUMMARY \n"};
    s = {s, $sformatf("total check count: %0d \n", this.total_count)} ;
    s = {s, $sformatf("total error count: %0d \n", this.err_count  )} ;
    s = {s, "---------------------------------------------------------------\n"};
    rpt_pkg::rpt_msg($sformatf("[%s]",this.name), s, rpt_pkg::INFO, rpt_pkg::TOP);
  endfunction

endclass

`endif
