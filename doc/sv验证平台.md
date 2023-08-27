三脚猫验证学习计划-第二课: SystemVerilog验证平台

**验证平台概述**
&emsp;验证的目的是确保DUT(Design Under Test, 即需要验证的设计模块)的功能与预期的功能一致.  
&emsp;为了保证能够成功流片, 就必须要在DUT的RTL代码完成之后, 对其功能进行充分的验证测试.  
&emsp;然而随着芯片功能日益复杂, 为了保证DUT验证的充分性, 对DUT所需要施加的激励种类也越来越多, 因此仅使用传统的施加定向测试激励的方法无法满足当下的验证需求, 需要使用能够自动产生激励的验证平台去完成验证工作.  
&emsp;验证平台能够大大减小验证的工作量, 缩短验证周期.  
&emsp;验证平台有一个非常重要的特点, 就是验证代码的高效性.高效主要体现在以下几个方面: 1. 施加不同测试激励需要修改的代码要尽可能少.2. 随着DUT版本迭代或者功能增加, 验证工作内容会随之改变, 但需要修改的代码要尽可能少.
因此为了能够写出高效的验证代码, 需要搭建SV验证平台.高效代码的编写原则之一是清晰划分功能, 并分模块实现.验证平台需要实现以下功能:
1. 产生测试激励
2. 将激励发送到设计的输入中
3. 监测设计的输出
4. 自动检测输出的结果是否正确
5. 记录项目的验证进度

验证平台应该按照隔离的观念, 分为硬件DUT, 软件验证环境, 和处于信号媒介的接口interface. 验证平台的硬件DUT由IC设计工程师提供, 接口由Interface模块负责, 软件验证环境根据功能可划分为以下几个模块:Transaction, Driver, Monitor, Agent, Scoreboard, Environment, Reference, Coverage .这些模块都对应着的功能.
1. Interface模块负责连接验证平台与DUT.验证平台一般不直接驱动DUT, 因这不利于代码的修改维护.一般会将DUT的输入输出信号封装成一个接口模块, 验证平台会驱动接口模块, 然后接口模块控制着DUT的输入输出.
2. Transaction模块负责生成测试激励所需的信息, 并发送给Driver模块.
3. Driver模块负责接受来自Transaction的信息, 并转化为激励信号, 按照特定的时序驱动Interface.
4. Monitor模块负责监测DUT的输入和输出, 并将输入信号打包发送给Reference模块, 将输出信号打包发送给Scoreboard模块
5. Reference模块负责接收来自Monitor监测到的输入信号, 并且进行处理后生成输出信号, 并打包发送给Socreboard模块
6. Scoreboard模块负责接收来自Monitor监测到的输出信号, 以及来自Reference模块的输出信号, 将二者进行比对, 以验证结果是否正确.
7. Coverage模块负责从Interface模块采样信号, 以记录哪些功能已经过验证, 哪些功能尚未被验证过.

对于软件验证环境, 需要经历建立阶段(build), 连接阶段(connect), 产生激励阶段(generate)和发送激励阶段(transfer).

**案例代码**
&emsp;接下来以一个ALU模块的验证为案例, 详细讲解验证平台的搭建过程, 并且会展示各个验证组件的具体代码.
**DUT**
&emsp;本实验目的在于了解验证平台的搭建过程, 可以不关心DUT的RTL代码, 但是需要对DUT的基本功能有所了解.本次实验的DUT采用了一个ALU模块, 该模块能够实现64位加, 减, 与, 或, 异或这五种逻辑运算, 操作码分别对应于000, 001, 110, 111, 010.对ALU设计感兴趣的同学可以参考胡伟武老师的《计算机体系结构基础》第八章内容.
&emsp;现如今许多验证工作都需要基于事务级建模, 因此本课内容带领进行事务级建模初探.ALU模块的输入输出信号会使用握手信号进行同步传输, 握手协议与AXI4保持一致.
ALU模块的代码如下所示:
```SystemVerilog
module alu(
  input   wire  [63:0]    in1       ,
  input   wire  [63:0]    in2       ,
  input   wire  [2:0]     op        ,
  input   wire            in_valid  ,
  output  wire            in_ready  ,

  output  reg   [63:0]    res       ,
  output  reg             out_valid ,
  input   wire            out_ready ,
  input   wire            clk       ,
  input   wire            rstn      
);

  parameter  OP_ADD = 3'b000;
  parameter  OP_SUB = 3'b001;
  parameter  OP_XOR = 3'b010;

  parameter  OP_AND = 3'b110;
  parameter  OP_OR  = 3'b111;


  wire  [63:0]  adder_in1 = in1;
  wire  [63:0]  adder_in2 = ( op==OP_SUB ) ? (~in2) : in2;
  wire          cin       = (op==OP_SUB) ;

  wire  [63:0]  p  =  adder_in1 | adder_in2 ;
  wire  [63:0]  g  =  adder_in1 & adder_in2 ;

  wire  [63:0]  c;
  wire  [63:0]  sum;

  carry64 carry64_inst(
    .p  (p),
    .g  (g),
    .cin(cin),
    .c  (c),
    .P  ( ),
    .G  ( )
  );

  wire  [63:0]  carry_in =  (op[2:1]==2'b01) ? 64'b0 : c ;

  genvar i;
  generate
    for(i=0; i<64; i=i+1) begin
      single_adder single_adder_inst(
        .a  (adder_in1[i]),
        .b  (adder_in2[i]),
        .cin(carry_in[i] ),
        .s  (sum[i]      )
      );
    end
  endgenerate

  wire  [63:0]  result = ( {64{(op[2]==1'b0)}} & sum )  |
                         ( {64{(op==OP_AND )}} & g   )  |
                         ( {64{(op==OP_OR  )}} & p   )  ;

  always@(posedge clk) begin
    if(!rstn)
      res <= 64'b0;
    else if(in_valid && in_ready)
      res <= result;
  end

  always@(posedge clk) begin
    if(!rstn)
      out_valid <= 1'b0;
    else if(in_valid && in_ready)
      out_valid <= 1'b1;
    else if(out_valid && out_ready)
      out_valid <= 1'b0;
  end

  assign in_ready = ~(out_valid & !out_ready) ;

endmodule



module carry64(
  input   wire    [63:0]  p   ,
  input   wire    [63:0]  g   ,
  input   wire            cin ,
  output  wire    [63:0]  c   ,
  output  wire            P   ,
  output  wire            G   
);

  assign  c[0] = cin ;
  wire  [15:0]  P_1 ;
  wire  [15:0]  G_1 ;
  wire  [3:0]   P_2 ;
  wire  [3:0]   G_2 ;

  genvar i;
  generate
    for(i=0; i<16; i=i+1) begin
      carry4 carry4_inst(
        .p  (p[i*4+3:i*4]) ,
        .g  (g[i*4+3:i*4]) ,
        .cin(c[i*4]) ,
        .c  (c[i*4+3:i*4+1]) ,
        .P  (P_1[i]) ,
        .G  (G_1[i]) 
      );
    end
  endgenerate

  generate
    for(i=0; i<4; i=i+1) begin
      carry4 carry4_inst(
        .p  (P_1[i*4+3:i*4]) ,
        .g  (G_1[i*4+3:i*4]) ,
        .cin(c[i*16] ) ,
        .c  ({c[i*16+12],c[i*16+8],c[i*16+4]}) ,
        .P  (P_2[i]  ) ,
        .G  (G_2[i]  ) 
      );
    end
  endgenerate

  carry4 carry4_inst(
    .p  (P_2)  ,
    .g  (G_2)  ,
    .cin(c[0]) ,
    .c  ({c[48],c[32],c[16]})  ,
    .P  (P  )  ,
    .G  (G  )  
  );

endmodule

module carry4(
  input   wire    [3:0]   p   ,
  input   wire    [3:0]   g   ,
  input   wire            cin ,
  output  wire    [3:1]   c   ,
  output  wire            P   ,
  output  wire            G   
);

  assign  {c[1]} = (cin & p[0]) | g[0] ;
  assign  {c[2]} = (cin & p[0] & p[1]) | (g[0] & p[1]) | g[1] ;
  assign  {c[3]} = (cin & p[0] & p[1] & p[2]) | (g[0] & p[1] & p[2]) | (g[1] & p[2]) | g[2] ;

  assign  P =  p[0] & p[1] & p[2] & p[3] ;
  assign  G = (g[0] & p[1] & p[2] & p[3]) | (g[1] & p[2] & p[3]) | (g[2] & p[3]) | g[3] ;

endmodule

module single_adder(
  input   wire  a   ,
  input   wire  b   ,
  input   wire  cin ,
  output  wire  s
);

  assign s = (a & b & cin) | (a & ~b & ~cin) | (~a & b & ~cin) | (~a & ~b & cin) ;

endmodule
```

**接口--interface**
&emsp;接口模块作为DUT与测试平台之间的桥梁, 一方面可以规定信号的方向, 减少代码的出错概率.
&emsp;另一方面接口模块将输入输出信号封装在一起, 便于代码的维护.
interface模块代码如下
```SystemVerilog
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
```

&emsp;interface中, clocking时钟块的时序描述, 书本上的解释较为晦涩难理解, 建议初学者根据本例代码, 对照仿真软件输出的波形进行理解.时钟块(clocking-endclocking)拥有modport的全部功能, 并且还可控制同步信号的时序, 因此时钟块更常用.我们将DUT的输入端口和输出端口封装成两个接口, 分别负责两种事务.输入端口负责发送一个操作码和两个操作数给DUT, 输出端口负责接收DUT的计算结果.
&emsp;drv_ck代表驱动模块的时钟块, 会与驱动模块相连.
&emsp;mnt_ck代表监视器模块的时钟块, 监视器必须监视的是DUT的输入输出信号, 因此接口模块需要提供与监视器相关的信号接口.
时钟块内的信号方向是相对于软件验证环境的.因此drv_ck时钟块需要发送给DUT的信号为output方向, 需要从DUT接收的信号为input.而mnt_ck时钟块负责对DUT上的信号进行采样, 因此均为input方向.

**事务--transaction**
&emsp;事务可以理解为由多个数据组成的一个数据包, 目前基于事务的验证非常广泛, 也更符合人类的思维方式, 因此有利于提高编写代码的效率.每完成一次握手意味着完成一次事务传递.在本案例中, DUT输入端口每次事务需要传递两个操作数和一个操作码, 分别为in1, in2和op.DUT输出端口每次事务需要传递一个结果数据, 为in1与in2进行op运算后的结果, 用res表示.代码如下所示.
```SystemVerilog
//trans.sv

`ifndef TRANS__SV
`define TRANS__SV


class in_trans;
  rand bit  [63:0]  in1  = 0;
  rand bit  [63:0]  in2  = 0;
  rand bit  [ 2:0]  op   = 0;

  rand int  nidles  ;  //握手信号等待的时钟周期个数
  bit          rsp  ;

  constraint cnstrnt{
    nidles inside {[0:200]};
  };
  
endclass


class out_trans;
  bit  [63:0]  res = 0;
  
endclass

`endif
```

**生成器--generator**
&emsp;generator负责产生DUT输入端口所需要的事务, 代码如下所示.产生的事务通过邮箱传递给driver, 由driver驱动DUT.代码中使用了两个邮箱, 目的是让generator的产生事务与driver的驱动事务这两个动作进行同步, 即generator产生了一个事务并发送给driver之后, 等driver完成了对该事务的驱动, generator才会再产生新的事务.具体的同步原理, 以及mailbox的使用, 可参阅绿皮书7.6节.
```SystemVerilog
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
        else $fatal("[RAND FAIL]: intrans rand failure!");
      this.inreq_mb.put(intrans);
      this.inrsp_mb.get(intrans);
      assert(intrans.rsp)
        else $error("[RSP ERR]: %0tns intrans response error", $time);
    end
  endtask

endclass

`endif
```

**驱动器--driver**
&emsp;driver负责接收generator发送的事务, 然后通过interface将信号施加到DUT的输入引脚上.driver还负责处理握手信号.本例中握手信号处理方式如下: 
1.随机等待0~200个时钟周期之后将in_valid拉高, 当采样到in_ready为高之后再将in_valid拉低, 如此循环.
2.out_ready初始值为0, 当DUT的输出端口数据有效时(即out_valid=1时), 随机等待0~200个时钟周期之后, 将out_ready拉高一个时钟周期后再拉低, 如此循环.
```SystemVerilog
//driver.sv

`ifndef DRIVER__SV
`define DRIVER__SV

class alu_driver;

  local string name;

  rand int nidles;

  constraint cstrnt{
    nidles inside {[0:200]};
  };

  virtual   in_if  inif  ;
  virtual  out_if outif  ;

  mailbox #( in_trans)   inreq_mb;
  mailbox #( in_trans)   inrsp_mb;

  function new(string name = "driver");
    this.name = name;
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    if(inif == null || outif == null)
      $error({name, " : if is null!"});
    else begin
      this.inif = inif;
      this.outif = outif;
    end
  endfunction

  task run();
    fork
      this.in_drive();
      this.out_drive();
      this.in_reset();
      this.out_reset();
    join
  endtask

  task  in_drive();
    @(posedge inif.rstn);
    forever begin
      in_trans req;
      inreq_mb.get(req);
      repeat(req.nidles) @(posedge inif.clk);
      inif.drv_ck.in_valid <= 1'b1;
      inif.drv_ck.in1      <= req.in1;
      inif.drv_ck.in2      <= req.in2;
      inif.drv_ck.op       <= req.op ;
      @(posedge inif.clk iff (inif.in_ready === 1'b1));
      fork begin
        //@(posedge inif.clk);
        inif.drv_ck.in_valid <= 1'b0;
        inif.drv_ck.in1   <=  'b0;
        inif.drv_ck.in2   <=  'b0;
        inif.drv_ck.op    <=  'b0;
      end
      join_none
      req.rsp = 1;
      inrsp_mb.put(req);
    end
  endtask

  task out_drive();
    @(posedge outif.rstn);
    forever begin
      @(posedge outif.clk);
	  outif.drv_ck.out_ready <= 1'b0;
	  wait(outif.out_valid === 1'b1);
      assert(this.randomize())
        else $fatal({name," : RAND FAIL"});
      repeat(this.nidles) @(posedge outif.clk);
      outif.drv_ck.out_ready <= 1'b1;
    end
  endtask

  task in_reset();
    forever begin
      @(posedge inif.clk iff(!inif.rstn));
      inif.drv_ck.in_valid <= 1'b0;
      inif.drv_ck.in1      <=  'b0;
      inif.drv_ck.in2      <=  'b0;
      inif.drv_ck.op       <=  'b0;
    end
  endtask

  task out_reset();
    forever begin
      @(posedge outif.clk iff(!outif.rstn));
      outif.drv_ck.out_ready <= 1'b0;
    end
  endtask
  
endclass

`endif
```


**监视器--monitor**
&emsp;monitor负责监测DUT输入端口和输出端口的信号值.当DUT的输入端口完成一次握手时, monitor会将输入端口的采样信号打包成事务, 使用邮箱传递给参考模型(参考模型的相关代码会在后文介绍).当DUT的输出端口完成一次握手时, monitor会将输出端口的采样信号打包成事务, 使用邮箱传递给记分板(计分板的相关代码会在后文介绍).
```SystemVerilog
`ifndef MONITOR__SV
`define MONITOR__SV

class alu_monitor;

  local string name ;
  virtual in_if  inif;
  virtual out_if outif;
  mailbox #(in_trans)   mntin_mb ;
  mailbox #(out_trans) mntout_mb ;

  function new(string name = "monitor");
    this.name = name;
  endfunction

  function void set_interface(virtual in_if inif, virtual out_if outif);
    if(inif == null || outif == null)
      $fatal("[INTF FATAL]: interface is null in monitor");
    else begin
      this.inif  =  inif  ;
      this.outif = outif  ;
    end
  endfunction

  task run();
    fork
      in_run();
      out_run();
    join
  endtask

  task in_run();
    forever begin
      in_trans trans;
      trans = new();
      @(posedge inif.clk iff(inif.mnt_ck.in_ready && inif.mnt_ck.in_valid));
      trans.in1 = inif.mnt_ck.in1;
      trans.in2 = inif.mnt_ck.in2;
      trans.op  = inif.mnt_ck.op ;
      this.mntin_mb.put(trans);
    end
  endtask

  task out_run();
    forever begin
      out_trans trans;
      trans = new();
      @(posedge outif.clk iff(outif.mnt_ck.out_ready && outif.mnt_ck.out_valid));
      trans.res = outif.mnt_ck.res;
      this.mntout_mb.put(trans);
    end
  endtask

endclass

`endif
```

**参考模型--refmod**
&emsp;refmod负责接收monitor采集到的DUT输入端口的信号, 将其进行计算后生成正确结果, 打包发送给计分板.值得注意的是, refmod需要实现与DUT相同的功能, 但是参考模型与DUT两者的实现方式是有本质区别的.refmod的关注点在于, 当给定DUT的输入信号之后, DUT的输出应该是什么, 因此refmod是使用软件算法实现的, 没有时序的概念.而DUT是使用硬件描述语言实现的, 是可以映射成具体电路的, 因此有时序的概念.
```SystemVerilog
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
```

**计分板--scoreboard**
&emsp;scoreboard, 计分板, 又称为检查器, checker.该模块会接收两路数据, 一路是来自monitor采集到的DUT输出端口的数据, 另一路是refmod生成的数据.checker负责将两路数据进行比较, 若数据相等则说明DUT的实现没有问题.若数据不相等则必定至少有一方是错误的, 就需要检查代码以修正错误.代码块中的rpt_pkg是一个封装的package, 用于输出验证报告信息的通用模板, 会在后文介绍.
```SystemVerilog
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
```

**覆盖率--coverage**
&emsp;该模块会从接口信号进行采样, 以记录验证的功能覆盖率情况, 代码如下所示.此次示例为了简单起见, 只展示了op信号的覆盖率监测情况.
```SystemVerilog
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
```

到此为止, 软件验证环境的基本模块已经编写完成, 接下来需要对一些模块进行封装.封装后的验证平台框架图如下图所示:


**代理层--agent**
&emsp;driver和monitor模块的代码高度相似, 因为这两个模块处理的是同一种协议的事务, 在同样一套既定的规则下做着不同的事情.由于二者的相似性, 通常将这两个模块封装在一起, 并称其为代理.
```SystemVerilog
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
```

**环境层--environment**
&emsp;agent, checker, refmod, coverage这些模块, 随着验证工作向前推进, 这些模块的代码需要改动的比较少, 因此可将其封装在一起, 称其为环境.这些模块中的run任务内部都是无限循环, 因此可以自动完成工作, 不需要额外的控制, 因此封装在一起更合理.generator模块控制着仿真验证的开始和结束, 并且通过简单地修改代码就能生成不同的激励, 因此generator模块代码通常不放入环境层, 而是放入更高的base_test层, 以便于更好的控制验证平台.
```SystemVerilog
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
```

**测试层--base_test**
&emsp;测试层比较简单, 就是将环境层和generator封装在一起, 并且输出一些的调式信息.watchdog看门狗任务可用于限制仿真时间.需要注意的是, base_test一般不进行任何操作, 是为了扩展不同的测试用例而准备的.当需要编写不同测试用例时, 只需要在do_data任务中进行编写即可.本例仅提供了一个测试用例, 读者可自行编写更多的测试用例.
```SystemVerilog
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
```

**输出报告的相关代码--rpt_pkg**
```SystemVerilog
package rpt_pkg;

typedef enum {INFO, WARNING, ERROR, FATAL} report_t;
typedef enum {LOW, MEDIUM, HIGH, TOP} severity_t;
typedef enum {LOG, STOP, EXIT} action_t;

static severity_t svrt = LOW;
static string logname = "report.log";
static int info_count = 0;
static int warning_count = 0;
static int error_count = 0;
static int fatal_count = 0;

function void rpt_msg(string src, string i, report_t r=INFO, severity_t s=LOW, action_t a=LOG);
  integer logf;
  string msg;
  case(r)
    INFO: info_count++;
    WARNING: warning_count++;
    ERROR: error_count++;
    FATAL: fatal_count++;
  endcase
  if(s >= svrt) begin
    msg = $sformatf("@%0t [%s] %s : %s", $time, r, src, i);
    logf = $fopen(logname, "a+");
    $display(msg);
    $fwrite(logf, $sformatf("%s\n", msg));
    $fclose(logf);
    if(a == STOP) begin
      $stop();
    end
    else if(a == EXIT) begin
      $finish();
    end
  end
endfunction

function void do_report();
  string s;
  s = "\n---------------------------------------------------------------\n";
  s = {s, "REPORT SUMMARY\n"}; 
  s = {s, $sformatf("info count: %0d \n", info_count)}; 
  s = {s, $sformatf("warning count: %0d \n", warning_count)}; 
  s = {s, $sformatf("error count: %0d \n", error_count)}; 
  s = {s, $sformatf("fatal count: %0d \n", fatal_count)}; 
  s = {s, "---------------------------------------------------------------\n"};
  rpt_msg("[REPORT]", s, rpt_pkg::INFO, rpt_pkg::TOP);
endfunction

function void clean_log();
  integer logf;
  logf = $fopen(logname, "w");
  $fclose(logf);
endfunction

endpackage
```

**封装层--alu_pkg**
```SystemVerilog
// alu_pkg.sv
package alu_pkg;

  import rpt_pkg::*;

  `include "trans.sv"

  `include "generator.sv"

  `include "driver.sv"

  `include "monitor.sv"

  `include "agent.sv"
  
  `include "refmod.sv"

  `include "checker.sv"

  `include "coverage.sv"

  `include "env.sv"
  
  `include "base_test.sv"
  
endpackage:alu_pkg
```

**验证平台--testbench**
&emsp;验证平台的代码比较简单, 主要完成以下工作:实例化接口, 实例化DUT, 产生时钟和复位信号, 创建测试用例.与创建测试用例相关的代码在最后一个initial-begin-end代码块中, 本例只提供了op_test这一个测试用例, 而当编写了多个测试用例时, 可以让命令行附加不同的参数来运行不同的测试用例.
```SystemVerilog
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
```

**实战训练**
```bash
cd alu
make sim
```
跳转ysyx-verify/alu文件  


查看输出信息如下图所示.
第一项是计分板(checker)的输出信息, 一共验证了10000次, 错误0次.
第二项是功能覆盖率模块的输出信息, 显示总覆盖率达到了100%, op_group的覆盖率达到了100%.
第三项是报告总结, 显示了在仿真过程中, 一共输出了10005条一般信息, 0警告, 0错误, 0致命错误.
