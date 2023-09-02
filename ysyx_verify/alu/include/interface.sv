//filename: interface.sv

`ifndef INTERFACE__SV
`define INTERFACE__SV

interface  in_if(input clk, input rstn);// input interface
  logic  [63:0]    in1       ;
  logic  [63:0]    in2       ;
  logic  [2:0]     op        ;
  logic            in_valid  ;
  logic            in_ready  ;

  clocking drv_ck @(posedge clk);  //driver clocking block
    output  in1, in2, op, in_valid;
    input   in_ready;
  endclocking

  clocking mnt_ck @(posedge clk);  // monitor clocking block
    input  in1, in2, op, in_valid, in_ready;
  endclocking
endinterface

interface out_if(input clk, input rstn);  // output interface
  logic  [63:0]    res       ;
  logic            out_valid ;
  logic            out_ready ;

  clocking drv_ck @(posedge clk);  // driver clocking block
    input   res, out_valid;
    output  out_ready;
  endclocking

  clocking mnt_ck @(posedge clk);  // monitor clocking block
    input  res, out_valid, out_ready;
  endclocking
endinterface

`endif