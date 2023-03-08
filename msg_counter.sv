module msg_counter 
#(
  parameter NUM_COUNT_BITS = 16
)
(
	input logic clk,
	input logic rst,
	input logic s_tvalid,
	input logic s_tready,
	input logic count_en,
	input logic clear, 
	input logic [NUM_COUNT_BITS*2-1:0] rollover_val,
	output logic [NUM_COUNT_BITS-1:0] msg_length,
	output logic rollover_flag
);

	logic [NUM_COUNT_BITS-1:0] next_count;
	logic flag;

	always_ff @ (posedge clk, negedge rst) begin
		if (!rst) begin
			msg_length <= 0;
			rollover_flag <= 0;
		end
		else begin
			msg_length <= next_count;
			rollover_flag <= flag;
		end
	end

	//counter logic
	always_comb begin
		next_count = msg_length;
		flag = rollover_flag;
		if (clear) begin
			next_count = 0;
			flag = 0;
		end
		//TODO: want to increment when in state STORE
		if (s_tvalid && s_tready && count_en) begin //if handshake happens, start the count
			if (rollover_flag == 1'b1) begin 
				next_count = 0;
			end
			else begin
				next_count = msg_length + 1'b1;
			end
			if ((msg_length + 1 == rollover_val)) begin
				flag = 1'b1;
			end
			else begin
				flag = 1'b0;
			end
		end 
	end

	
endmodule
