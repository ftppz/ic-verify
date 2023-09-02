//trans.sv

`ifndef TRANS__SV
`define TRANS__SV


class in_trans;
  rand bit  [63:0]  in1  ;
  rand bit  [63:0]  in2  ;
  rand bit  [ 2:0]  op   ;

  rand int  nidles  ;
  bit          rsp  ;

  constraint cnstrnt{
    nidles inside {[0:200]};
    op inside {3'b000, 3'b001, 3'b110, 3'b111, 3'b010};
  };
  
endclass


class out_trans;
  bit  [63:0]  res  ;

/*
  rand int  nidles  ;
  bit          rsp  ;

  constraint cnstrnt{
    nidles inside {[0:200]};
  };
  */
  
endclass

`endif
