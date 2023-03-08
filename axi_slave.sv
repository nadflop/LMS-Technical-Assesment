module axi_slave (
	input logic clk,
	input logic rst,
	input logic upsizing,
	input logic s_tvalid,
	input logic s_tlast,
	output logic s_tready,
	output logic clear_msg_count
);

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
      if (s_tvalid && s_tready) begin
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
      if (s_tvalid && s_tready) begin
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
      if (s_tvalid && s_tready) begin
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

endmodule
