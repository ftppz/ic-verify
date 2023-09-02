//  refmod.sv

`ifndef REFMOD__SV
`define REFMOD__SV

class alu_refmod;  // reference model

  local string name;

  mailbox #(in_trans)    mntin_mb;
  mailbox #(out_trans)  refmod_mb;

  function new(string name = "refmod");
    this.name = name;
    this.mntin_mb  = new();
    this.refmod_mb = new();
  endfunction

  task run();
    in_trans  intrans ;
    out_trans outtrans;
    forever begin
      outtrans = new();
      this.mntin_mb.get(intrans);
      case (intrans.op)
        3'b000  :  outtrans.res = ( intrans.in1 + intrans.in2 ) ;
        3'b001  :  outtrans.res = ( intrans.in1 - intrans.in2 ) ;
        3'b010  :  outtrans.res = ( intrans.in1 ^ intrans.in2 ) ;
        3'b110  :  outtrans.res = ( intrans.in1 & intrans.in2 ) ;
        3'b111  :  outtrans.res = ( intrans.in1 | intrans.in2 ) ;
        default :  outtrans.res = 0 ;
      endcase
      this.refmod_mb.put(outtrans);
    end
  endtask
  
endclass

`endif

