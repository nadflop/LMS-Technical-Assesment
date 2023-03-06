module msg_controller #(
  parameter MAX_MSG_BYTES = 32, //data width
  parameter DATA_BYTES = 8,
  parameter TKEEP_WIDTH = 8
)
(
	input logic clk,
	input logic rst,
	input logic s_tvalid,
	input logic s_tready,
	input logic s_tlast,
	input logic s_tuser,
	input logic [TKEEP_WIDTH-1:0] s_tkeep,
	input logic [8*DATA_BYTES-1:0] s_tdata,
  input logic upsizing,
	output logic [8*MAX_MSG_BYTES-1:0] msg_data,
	output logic msg_valid,
	output logic msg_error
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
logic handshake = s_tvalid && s_tready;
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