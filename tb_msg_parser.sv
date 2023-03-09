`timescale 1ns / 1ps
module tb_msg_parser();

// Define parameters
localparam CLK_PERIOD = 10;
//localparam PROPAGATION_DELAY;
parameter TDATA_WIDTH = 64; //bits
parameter MAX_PKT_LENGTH = 256;
parameter MIN_PKT_LENGTH = 64;

//DUT Inputs
logic tb_clk;
logic tb_rst;
logic tb_tlast;
logic [TDATA_WIDTH-1:0] tb_tdata;
logic [7:0] tb_tkeep;
logic tb_tuser;
logic tb_tvalid;

//DUT outputs
logic tb_tready;
logic tb_msg_valid;
logic [15:0] tb_msg_length;
logic [MAX_PKT_LENGTH-1:0] tb_msg_data;
logic tb_msg_error;

//Test bench debug signals
integer tb_test_num;
string tb_test_case;

// Task for standard DUT reset procedure
task reset_dut;
  begin
    // Activate the reset
    tb_rst = 1'b0;

    // Maintain the reset for more than one cycle
    @(posedge tb_clk);
    @(posedge tb_clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge tb_clk);
    tb_rst = 1'b1;

    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    @(negedge tb_clk);
    @(negedge tb_clk);
  end
endtask
//add clkgen block
initial begin
	tb_clk = 'b0;
	tb_rst = 'b1;
end
initial forever #(CLK_PERIOD) tb_clk=~tb_clk;

//task to set input for msg_parser
task set_input;
  input m_tvalid;
  input m_tlast;
  input [TDATA_WIDTH-1:0] m_tdata;
  input [7:0] m_tkeep;
  input m_tuser;
  begin
    tb_tvalid = m_tvalid;
    tb_tdata = m_tdata;
    tb_tkeep = m_tkeep;
    tb_tuser = m_tuser;
    if (m_tlast == 1'b1) begin
	@(posedge tb_clk);
	tb_tlast = m_tlast;
	@(posedge tb_clk);
	tb_tlast = ~m_tlast;
    end
    else begin
	tb_tlast = m_tlast;
    end
    @(negedge tb_clk);
    @(posedge tb_clk);
  end
endtask
/*
Sample inputs:

tvalid,tlast,tdata,tkeep,terror
1,0,abcddcef_00080001,11111111,0
1,1,00000000_630d658d,00001111,0
1,0,045de506_000e0002,11111111,0
1,0,03889560_84130858,11111111,0
1,0,85468052_0008a5b0,11111111,0
1,1,00000000_d845a30c,00001111,0
1,0,62626262_00080008,11111111,0
1,0,6868000c_62626262,11111111,0
1,0,68686868_68686868,11111111,0
1,0,70707070_000a6868,11111111,0
1,0,000f7070_70707070,11111111,0
1,0,7a7a7a7a_7a7a7a7a,11111111,0
1,0,0e7a7a7a_7a7a7a7a,11111111,0
1,0,4d4d4d4d_4d4d4d00,11111111,0
1,0,114d4d4d_4d4d4d4d,11111111,0
1,0,38383838_38383800,11111111,0
1,0,38383838_38383838,11111111,0
1,0,31313131_000b3838,11111111,0
1,0,09313131_31313131,11111111,0
1,0,5a5a5a5a_5a5a5a00,11111111,0
1,1,00000000_00005a5a,00000011,0
*/

//DUT portmap
msg_parser
#(
  .MAX_MSG_BYTES(MAX_PKT_LENGTH/8)
)
DUT (
  .s_tready(tb_tready),
  .s_tvalid(tb_tvalid),
  .s_tlast(tb_tlast),
  .s_tdata(tb_tdata),
  .s_tkeep(tb_tkeep),
  .s_tuser(tb_tuser),
  .msg_valid(tb_msg_valid),
  .msg_length(tb_msg_length), 
  .msg_data(tb_msg_data),
  .msg_error(tb_msg_error),   // Output if issue with the message
  .clk(tb_clk),
  .rst(tb_rst)
);

//do some assertion checks here
//add logic to generate some of the signals like tvalid, tuser, tlast

//test bench main process
initial begin
	tb_test_case = "Initialization";
	tb_test_num = 0;
	tb_rst = 1'b1;
	@(posedge tb_clk);
	//*****************************************************************************
	// Power-on-Reset Test Case
	//*****************************************************************************
	tb_test_case = "Power-on-Reset";
	tb_test_num = tb_test_num + 1;
	
	set_input(1'b0, 1'b0, 64'h0, 8'b0, 1'b0);
	reset_dut();
	
	@(posedge tb_clk);
	//*****************************************************************************
	// First Data Packet
	//*****************************************************************************
	tb_test_case = "1st Packet";
	tb_test_num = tb_test_num + 1;
	set_input(1'b1, 1'b0, 64'habcddcef00080001, 8'b11111111, 1'b0);
	set_input(1'b1, 1'b1, 64'h00000000630d658d, 8'b00001111, 1'b0);

	//set tvalid to 0 here to seperate diff packet
	tb_tvalid = 1'b0;
	@(posedge tb_clk);
	//*****************************************************************************
	// Second Packet
	//*****************************************************************************
	tb_test_case = "2nd Packet";
	tb_test_num = tb_test_num + 1;
	set_input(1'b1, 1'b0, 64'h045de506000e0002, 8'b11111111, 1'b0);
	set_input(1'b1,1'b0,64'h0388956084130858,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h854680520008a5b0,8'b11111111,1'b0);
	set_input(1'b1,1'b1,64'h00000000d845a30c,8'b00001111,1'b0);

	tb_tvalid = 1'b0;
	@(posedge tb_clk);
	//*****************************************************************************
	// Third Packet: 1st Data Stream
	//*****************************************************************************
	tb_test_case = "3rd Packet";
	tb_test_num = tb_test_num + 1;
	set_input(1'b1,1'b0,64'h6262626200080008,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h6868000c62626262,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h6868686868686868,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h70707070000a6868,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h000f707070707070,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h7a7a7a7a7a7a7a7a,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h0e7a7a7a7a7a7a7a,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h4d4d4d4d4d4d4d00,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h114d4d4d4d4d4d4d,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h3838383838383800,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h3838383838383838,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h31313131000b3838,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h0931313131313131,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h5a5a5a5a5a5a5a00,8'b11111111,1'b0);
	set_input(1'b1,1'b0,64'h0000000000005a5a,8'b00000011,1'b0);


	tb_tvalid = 1'b0;
	@(posedge tb_clk);


	$stop;
	

end


endmodule
