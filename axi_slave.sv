module axi_slave (
	input logic clk,
	input logic rst,
	input logic upsizing,
	input logic s_tvalid,
	input logic s_tlast,
	output logic s_tready
);

//state register for AXI-ST slave FSM
typedef enum bit [1:0] {IDLE, SEND_STREAM} stateType;
stateType axi_current_state;
stateType axi_next_state;

//delay the s_tready by one clock cycle
logic s_tready_next = 1'b0;

//state assignments for AXI Slave interface
always_ff @(posedge clk) begin
  if (!rst) begin
    axi_current_state <= IDLE;
    s_tready <= 1'b0;
  end
  else begin
    axi_current_state <= axi_next_state;
    s_tready <= s_tready_next;
  end
end

//next state logic for AXI Slave interface
always_comb begin
  axi_next_state = axi_current_state;
  case(axi_current_state)
    IDLE: begin
      if (s_tvalid && s_tready) begin
        axi_next_state = SEND_STREAM;
      end
      else begin
        axi_next_state = axi_current_state;
      end
    end
    SEND_STREAM: begin
      if (s_tvalid && s_tready) begin
        axi_next_state = axi_current_state;
      end
      else begin
        axi_next_state = IDLE;
      end
    end
  endcase
end

//output logic for AXI-ST Slave interface
always_comb begin
  s_tready_next = 1'b0;
  case(axi_current_state)
    IDLE: begin
      s_tready_next = 1'b1;
      if (s_tvalid && s_tready) begin
      	if (s_tlast) begin
		      s_tready_next = 1'b0;
      	end
      	else begin
      		s_tready_next = 1'b1;
      	end
      end
    end
    SEND_STREAM: begin
      s_tready_next = 1'b1;
      if (s_tvalid && s_tready) begin
      	if (s_tlast) begin
		      s_tready_next = 1'b0;
      	end
      	else begin
      		s_tready_next = 1'b1;
      	end
      end
    end
  endcase
end

endmodule
