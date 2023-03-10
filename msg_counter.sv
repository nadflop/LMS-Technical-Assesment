module msg_counter 
#(
  parameter NUM_COUNT_BITS = 16,
  parameter TKEEP_WIDTH = 8
)
(
	input logic clk,
	input logic rst,
	input logic s_tvalid,
	input logic s_tready,
	input logic s_tlast,
	input logic [TKEEP_WIDTH-1:0] s_tkeep, //8 bits length
	input logic msg_valid,
	output logic [NUM_COUNT_BITS-1:0] msg_length //assuming length here is in byte
);

	logic [NUM_COUNT_BITS-1:0] next_count;
	integer i;

	always_ff @ (posedge clk, negedge rst) begin
		if (!rst) begin
			msg_length <= '0;
		end
		else begin
			msg_length <= next_count;
		end
	end

	//counter logic
	always_comb begin
		next_count = msg_length;
		if (s_tvalid && s_tready) begin //if handshake happens, start the count
			next_count = '0;
			for (i = 0; i < TKEEP_WIDTH; i = i + 1) begin
				if (s_tkeep[i]) begin
					next_count = next_count + 1'b1;
				end
			end
		end 
	end

	
endmodule
