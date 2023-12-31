//----------------------------------------------------------//
//change log 2017-08-20 fix read pointer and write pointer 
//----------------------------------------------------------//
module slave_fifo (
input                       clk_i,                  // Clock input 
input                       rstn_i,                 // low level effective 

input                       chx_valid_i,            // Data is valid From outside ---->From Outside
input [31:0]                chx_data_i,             // Data input                 ---->From outside
input                       a2sx_ack_i,             // arbiter read ready         ---->From Arbiter
input                       slvx_en_i,              // Write enable To FIFO       ---->From Register

output reg                  chx_ready_o,            // Ready to accept data       ---->To outside
output reg [31:0]           slvx_data_o,            // Data Output                ---->To Arbiter
output [5:0]                margin_o,               // Data margin                ---->To Registers

output reg                  slvx_val_o,             // read acknowledge Keep to handshake with Arbiter ----> To Arbiter
output reg                  slvx_req_o 
);

//------------------------------Internal variables-------------------//
reg [5:0] w_pointer_r;  // write
reg [5:0] r_pointer_r;  // read
reg [31:0] mem [0:31];  // FIFO 32bits width and 32 deepth

//-----------------------------Variable assignments------------------//
wire full_s, empty_s, r_en_s;
wire [5:0] data_cnt_s;
assign full_s = w_pointer_r[5];
assign empty_s = (w_pointer_r == r_pointer_r);
assign data_cnt_s = (6'd32 - (w_pointer_r - r_pointer_r));

assign margin_o = data_cnt_s;
assign r_en_s = a2sx_ack_i;

//-----------Code Start---------------------------------------------//
always @ (*) //ready signal
begin
  if (!full_s && slvx_en_i) chx_ready_o = 1'b1;//If FIFO is not full and also enabled it is ready to accept data
  else chx_ready_o = 1'b0;
end

always @ (*) //reset signal
begin
  if (!rstn_i) slvx_req_o = 1'b0;
  else if (!empty_s) slvx_req_o = 1'b1;
  else slvx_req_o = 1'b0;
end

//write pointer increment
always @ (posedge clk_i or negedge rstn_i)
begin : WRITE_POINTER
  if (!rstn_i) begin
    w_pointer_r <= 6'b0000;
  end else
  if (chx_valid_i && chx_ready_o) begin
    w_pointer_r <= w_pointer_r + 6'b0001;
  end
end

//read pointer increment
always @ (posedge clk_i or negedge rstn_i)
begin : READ_POINTER
  if (!rstn_i) begin
    r_pointer_r <= 6'b0000;
  end else 
  if (r_en_s && (!empty_s)) begin
    r_pointer_r <= r_pointer_r + 6'b0001;
  end
end

//data output is vaild 
always @ (posedge clk_i or negedge rstn_i)
begin
  if (!rstn_i) slvx_val_o <= 1'b0;
  else if (r_en_s && (!empty_s))
    slvx_val_o <= 1'b1;
  else slvx_val_o <= 1'b0;
end

// Memory Read Block 
always  @ (posedge clk_i )
begin : READ_DATA 
  if (rstn_i && r_en_s && (!empty_s)) begin
    slvx_data_o <= mem[r_pointer_r[4:0]];
  end
end

// Memory Write Block 
always @ (posedge clk_i)
begin : MEM_WRITE
	if (rstn_i && chx_valid_i && chx_ready_o && slvx_en_i) 
  begin
	  mem[w_pointer_r[4:0]] <= chx_data_i;
	end
end

endmodule 
