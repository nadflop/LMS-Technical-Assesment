`timescale 1ns / 1ps
module msg_parser #(
  parameter MAX_MSG_BYTES = 32,
  parameter DATA_BYTES = 8
)(
  output logic        s_tready,
  input  logic        s_tvalid,
  input  logic        s_tlast,
  input  logic [8*DATA_BYTES-1:0] s_tdata,
  input  logic [7:0]  s_tkeep,
  input  logic        s_tuser, // Used as an error input signal, valid on tlast

  output logic                       msg_valid,   // High for one clock to output a message
  output logic [15:0]                msg_length,  // Length of the message
  output logic [8*MAX_MSG_BYTES-1:0] msg_data,    // Data with the LSB on [0]
  output logic                       msg_error,   // Output if issue with the message

  input  logic clk,
  input  logic rst
);

//state register
typedef enum bit [2:0] {IDLE, MODIFY_DATA, WRITE} stateType;
stateType current_state;
stateType next_state;

//find out if output bus is wider
parameter upsizing = MAX_MSG_BYTES > DATA_BYTES;

//TODO: add counter logic and maybe set the data here (since data needs to be set on clk cycle)
always_ff @(posedge clk, negedge rst) begin
  if (!rst) begin
    current_state <= IDLE;
  end
  else begin
    current_state <= next_state;
  end
end

//logic for AXI slave FSM
always_comb begin
  next_state = current_state;
  case(current_state)
    IDLE: begin
      if (s_tvalid && s_tready) begin
        if (upsizing) begin
          next_state = MODIFY_DATA;
        end
        else begin
          next_state = WRITE;
        end
      end
      else begin
        next_state = current_state;
      end
    end
    MODIFY_DATA: begin
      if (s_tvalid && s_tready) begin
        if (!s_tlast) begin
          next_state = current_state;
        end
        else begin
          next_state = WRITE;
        end
      end
      else begin
        next_state = current_state;
      end
    end
    WRITE: begin
      if (s_tvalid && s_tready) begin
        if (!s_tlast) begin
          next_state = current_state;
        end
        else begin
          next_state = IDLE;
        end
      end
      else begin
        next_state = IDLE;
      end
    end
  endcase
end

//combinational logic to generate tready signal
//TODO: data buffer logic with tkeep and upsizing
always_comb begin
  case(current_state)
    IDLE: begin
      s_tready = 1'b1;
    end
    MODIFY_DATA: begin
      if (s_tlast) begin
        s_tready = 1'b0;
      end
      else begin
        s_tready = 1'b1;
      end
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