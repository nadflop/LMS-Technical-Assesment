module msg_counter 
#(
  parameter DATA_BYTES = 8,
  parameter NUM_COUNT_BITS = 16
)
(
	input logic clk,
	input logic rst,
	input logic s_tvalid,
	input logic s_tready,
	output logic [NUM_COUNT_BITS-1:0] msg_length
);

	logic [NUM_COUNT_BITS-1:0] next_count;

	always_ff @ (posedge clk, negedge rst) begin
		if (!rst) begin
			msg_length <= 0;
		end
		else begin
			msg_length <= next_count;
		end
	end

	always_comb begin
		next_count = msg_length;
		if (s_tvalid && s_tready) begin
			next_count = msg_length + 1'b1;
		end 
	end

	
endmodule