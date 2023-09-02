//  generator.sv

`ifndef  GENERATOR__SV
`define  GENERATOR__SV

class alu_generator;
  
  local string name = "generator";

  mailbox  #(in_trans)   inreq_mb ;
  mailbox  #(in_trans)   inrsp_mb ;

  function new(string name = "generator");
    this.name = name;
    this.inreq_mb  = new(); 
    this.inrsp_mb  = new();
  endfunction

  task start(int n);
    repeat (n) begin
      in_trans  intrans;
      intrans = new();
      assert(intrans.randomize())
        else $fatal();//("[RAND FAIL]: intrans rand failure!");
      this.inreq_mb.put(intrans);
      this.inrsp_mb.get(intrans);
      assert(intrans.rsp)
        else $error("[RSP ERR]: %0tns intrans response error", $time);
    end
  endtask

endclass

`endif
