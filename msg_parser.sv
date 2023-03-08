`timescale 1ns / 1ps
module msg_parser #(
  parameter MAX_MSG_BYTES = 32, //data width
  parameter DATA_BYTES = 8,
  parameter TKEEP_WIDTH = 8
)(
  //inputs, outputs from AXI Slave interface
  output logic        s_tready,
  input  logic        s_tvalid,
  input  logic        s_tlast,
  input  logic [8*DATA_BYTES-1:0] s_tdata,
  input  logic [TKEEP_WIDTH-1:0]  s_tkeep,
  input  logic        s_tuser, // Used as an error input signal, valid on tlast
  //outputs from Data Buffer
  output logic                       msg_valid,   // High for one clock to output a message
  output logic [15:0]                msg_length,  // Length of the message
  output logic [8*MAX_MSG_BYTES-1:0] msg_data,    // Data with the LSB on [0]
  output logic                       msg_error,   // Output if issue with the message
  input  logic clk,
  input  logic rst
);

//variables used by both blocks//
parameter upsizing = MAX_MSG_BYTES > DATA_BYTES;
logic clear_msg_count;

//=====================AXI-ST SLAVE LOGIC=====================//

axi_slave
AXIS(
  .clk(clk),
  .rst(rst),
  .upsizing(upsizing),
  .s_tvalid(s_tvalid),
	.s_tlast(s_tlast),
	.s_tready(s_tready),
	.clear_msg_count(clear_msg_count)
);

//=====================DATA BUFFER LOGIC=====================//
logic msg_full; //tdata is ready to be copy to msg_data?
logic count_en; //signal to start count if msg is storing

//Data Counter
msg_counter
COUNTER(
  .clk(clk),
	.rst(rst),
	.s_tvalid(s_tvalid),
  .s_tready(s_tready),
	.count_en(count_en),
	.clear(clear_msg_count), 
	.rollover_val(MAX_MSG_BYTES/2),
	.msg_length(msg_length),
	.rollover_flag(msg_full)
);

msg_controller
#(
  .MAX_MSG_BYTES(MAX_MSG_BYTES)
)
CTRL(
  .clk(clk),
	.rst(rst),
	.s_tvalid(s_tvalid),
	.s_tready(s_tready),
	.s_tlast(s_tlast),
	.s_tuser(s_tuser),
	.s_tkeep(s_tkeep),
	.s_tdata(s_tdata),
  .upsizing(upsizing),
  .msg_full(msg_full),
	.msg_data(msg_data),
	.msg_valid(msg_valid),
	.msg_error(msg_error),
	.count_en(count_en)
);

endmodule
