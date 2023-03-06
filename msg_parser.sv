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
logic handshake = s_tvalid && s_tready;
logic clear_msg_count;

//=====================AXI-ST SLAVE LOGIC=====================//
//state register for AXI-ST slave FSM
typedef enum bit [2:0] {IDLE, MODIFY_DATA, WRITE} stateType;
stateType axi_current_state;
stateType axi_next_state;

//state assignments for AXI Slave interface
always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    axi_current_state <= IDLE;
  end
  else begin
    axi_current_state <= axi_next_state;
  end
end

//next state logic for AXI Slave interface
always_comb begin
  axi_next_state = axi_current_state;
  case(axi_current_state)
    IDLE: begin
      if (handshake) begin
        if (upsizing) begin
          axi_next_state = MODIFY_DATA;
        end
        else begin
          axi_next_state = WRITE;
        end
      end
      else begin
        axi_next_state = axi_current_state;
      end
    end
    MODIFY_DATA: begin
      if (handshake) begin
        if (!s_tlast) begin
          axi_next_state = axi_current_state;
        end
        else begin
          axi_next_state = WRITE;
        end
      end
      else begin
        axi_next_state = axi_current_state;
      end
    end
    WRITE: begin
      if (handshake) begin
        if (!s_tlast) begin
          axi_next_state = axi_current_state;
        end
        else begin
          axi_next_state = IDLE;
        end
      end
      else begin
        axi_next_state = IDLE;
      end
    end
  endcase
end

//output logic for AXI-ST Slave interface
always_comb begin
  clear_msg_count = 1'b0;
  s_tready = 1'b0;
  case(axi_current_state)
    IDLE: begin
      s_tready = 1'b1;
      clear_msg_count = 1'b1;
    end
    MODIFY_DATA: begin
      s_tready = 1'b1;
    end 
    WRITE: begin
      if (s_tlast) begin
        s_tready = 1'b0;
      end
      else begin
        s_tready = 1'b1;
      end
    end
  endcase
end

//=====================DATA BUFFER LOGIC=====================//
logic msg_ready; //tdata is ready to be copy to msg_data?

//Data Counter
msg_counter
PKCT(
  .clk(clk),
	.rst(rst),
	.count_enable(handshake),
	.clear(clear_msg_count), 
	.rollover_val(DATA_BYTES*8),
	.msg_length(msg_length),
	.rollover_flag(msg_ready)
);

//Data Controller
//assumption: when upsizing, pad extra bits with '0'
//assumption: tlast && tuser can be asserted anytime
//state: idle/wait, read, store
//idle/wait: output is all 0 or empty? should it retain prev val?
//read: do the tkeep processing here (use for loop & if statement)
//store: set msg_valid
//error: tuser && tlast, set msg_error
typedef enum bit [2:0] {WAIT, ERROR, STORE} dataStateType;
dataStateType data_ctrl_current_state;
dataStateType data_ctrl_next_state;

logic [8*MAX_MSG_BYTES-1:0] msg_temp = '0;
integer i;

//state assignments for Data Controller
always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    data_ctrl_current_state <= WAIT;
    msg_data <= '0;
  end
  else begin
    data_ctrl_current_state <= data_ctrl_next_state;
    msg_data <= msg_temp;
  end
end

//next state logic for Data Controller
always_comb begin
  data_ctrl_next_state = data_ctrl_current_state;
  case(data_ctrl_current_state)
    WAIT: begin
      if (handshake) begin
        if (s_tlast && s_tuser) begin
          data_ctrl_next_state = ERROR;
        end
        else begin
          data_ctrl_next_state = STORE;
        end
      end
      else begin
        data_ctrl_next_state = data_ctrl_current_state;
      end
    end
    STORE: begin
      if (s_tlast && s_tuser) begin
        data_ctrl_next_state = ERROR;
      end
      else begin
        data_ctrl_next_state = WAIT;
      end
    end
    ERROR:
      data_ctrl_next_state =  WAIT;
  endcase
end

//output logic for Data Controller
always_comb begin
  msg_temp = msg_data;
  msg_valid = 1'b0;
  msg_error = 1'b0;
  case(data_ctrl_current_state)
    WAIT: begin
    end
    STORE: begin
      msg_valid = 1'b1; 
      for (i = 0; i < TKEEP_WIDTH; i = i + 1) begin
        // {TKEEP_WIDTH{s_tkeep[i]}} ^~ s_tdata[(8i+7):8i]  
        msg_temp[(8*i+7)+:8] = {TKEEP_WIDTH{s_tkeep[i]}} ^~ s_tdata[(8*i+7) +: 8]; 
      end
      //msg_temp[8*MAX_MSG_BYTES]
      if (upsizing) begin
        //set the remaining MSB bits to 0
        msg_temp[8*MAX_MSG_BYTES-1:8*(TKEEP_WIDTH-1)+7] = '0;
      end
    end
    ERROR: begin
      msg_error = 1'b1;
      msg_temp = '0;
    end
  endcase
end

endmodule