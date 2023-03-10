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
//assumption: when upsizing, pad extra bits with '0' MSB
//assumption: tlast && tuser can be asserted anytime
//state: idle/wait, store, error
//error: set msg_error
typedef enum bit [2:0] {WAIT, ERROR, STORE} dataStateType;
dataStateType data_ctrl_current_state;
dataStateType data_ctrl_next_state;

logic [8*MAX_MSG_BYTES-1:0] msg_temp = '0;
logic msg_valid_temp = 1'b0; //delay the msg_valid signal by one clk cycle
integer i;

//state assignments for Data Controller, msg_valid signal
always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    data_ctrl_current_state <= WAIT;
    msg_data <= '0;
    msg_valid <= '0;
  end
  else begin
    data_ctrl_current_state <= data_ctrl_next_state;
    msg_data <= msg_temp;
    msg_valid <= msg_valid_temp;
  end
end

//next state logic for Data Controller
always_comb begin
  data_ctrl_next_state = data_ctrl_current_state;
  case(data_ctrl_current_state)
    WAIT: begin
      if (s_tvalid && s_tready) begin
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
    ERROR: begin
      //stay in this state until we get a new valid data
      if (s_tvalid && s_tready) begin
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
  endcase
end

//output logic for Data Controller
always_comb begin
  msg_temp = msg_data;
  msg_valid_temp = 1'b0;
  msg_error = 1'b0;
  case(data_ctrl_current_state)
    WAIT: begin
      msg_valid_temp = 1'b0;
      if (s_tvalid && s_tready) begin
	      if (!(s_tlast && s_tuser)) begin
		      msg_valid_temp = 1'b1;
	      end
	      for (i = 0; i < TKEEP_WIDTH-1; i = i + 1) begin
		      if (s_tkeep[i] == 1'b1) begin //keep the byte
        	  msg_temp[(8*i+7)+:8] = s_tdata[(8*i+7) +: 8]; 
		      end
		      else begin
			      msg_temp[(8*i+7)+:8] = '0;
		      end
        end
        if (upsizing) begin
          //set the remaining MSB bits to 0
          msg_temp[8*MAX_MSG_BYTES-1:8*(TKEEP_WIDTH-1)+7] = '0;
        end
      end
    end
    STORE: begin
      msg_valid_temp = 1'b1;
      if (s_tvalid && s_tready) begin
	      if (s_tlast && s_tuser) begin
		      msg_valid_temp = 1'b1;
	      end
	      for (i = 0; i < TKEEP_WIDTH-1; i = i + 1) begin 
		      if (s_tkeep[i] == 1'b1) begin //keep the byte
        		msg_temp[(8*i+7)+:8] = s_tdata[(8*i+7) +: 8]; 
		      end
		      else begin
			      msg_temp[(8*i+7)+:8] = '0;
		      end
      	end
      	if (upsizing) begin
        	//set the remaining MSB bits to 0
        	msg_temp[8*MAX_MSG_BYTES-1:8*(TKEEP_WIDTH-1)+7] = '0;
      	end
      end
    end
    ERROR: begin
      msg_error = 1'b1;
    end
  endcase
end

endmodule
