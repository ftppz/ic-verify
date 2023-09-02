
`include "interface.sv"


module tb;
  logic  clk ;
  logic  rstn;

  in_if inif(.*);
  out_if outif(.*);

alu dut(
  .in1       ( inif.in1        ) ,
  .in2       ( inif.in2        ) ,
  .op        ( inif.op         ) ,
  .in_valid  ( inif.in_valid   ) ,
  .in_ready  ( inif.in_ready   ) ,
  .res       ( outif.res       ) ,
  .out_valid ( outif.out_valid ) ,
  .out_ready ( outif.out_ready ) ,
  .clk       ( clk             ) ,
  .rstn      ( rstn            ) 
);

import alu_pkg::*;

initial begin
  clk <= 0;
  forever begin
    #5 clk <= ~clk;
  end
end

initial begin
  rstn <= 0;
  repeat(10) @(posedge clk);
  rstn <= 1;
end

/*
initial begin
  $vcdpluson(0, tb);
end
*/

op_test t1;
base_test tests[string];
string name;

initial begin
  t1 = new();
  tests["op_test"] = t1;
  if($value$plusargs("TESTNAME=%s", name)) begin
    if(tests.exists(name)) begin
      tests[name].set_interface(inif, outif);
      tests[name].do_config();
      tests[name].run();
    end else begin
      $fatal("ERRTEST, test name %s is invalid, please specify a valid name!", name);
    end
  end
  else begin
    $display("No runtime option +TESTNAME=xxx is configured, and run default test op_test");
    tests["op_test"].set_interface(inif, outif);
    tests["op_test"].do_config();
    tests["op_test"].run();
  end
end

endmodule
