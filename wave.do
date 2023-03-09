onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Test Info} -radix decimal /tb_msg_parser/tb_test_num
add wave -noupdate -expand -group {Test Info} /tb_msg_parser/tb_test_case
add wave -noupdate /tb_msg_parser/DUT/clk
add wave -noupdate /tb_msg_parser/DUT/rst
add wave -noupdate -expand -group handshake /tb_msg_parser/DUT/s_tready
add wave -noupdate -expand -group handshake /tb_msg_parser/DUT/AXIS/s_tready_next
add wave -noupdate -expand -group handshake /tb_msg_parser/DUT/s_tvalid
add wave -noupdate -expand -group Data_in /tb_msg_parser/DUT/s_tlast
add wave -noupdate -expand -group Data_in /tb_msg_parser/DUT/s_tuser
add wave -noupdate -expand -group Data_in -radix binary /tb_msg_parser/DUT/s_tkeep
add wave -noupdate -expand -group Data_in /tb_msg_parser/DUT/s_tdata
add wave -noupdate -expand -group Data_out /tb_msg_parser/DUT/msg_data
add wave -noupdate -expand -group Data_out /tb_msg_parser/DUT/msg_valid
add wave -noupdate -expand -group Data_out -radix decimal /tb_msg_parser/DUT/msg_length
add wave -noupdate -expand -group Data_out /tb_msg_parser/DUT/msg_error
add wave -noupdate -expand -group {AXI Slave State} /tb_msg_parser/DUT/AXIS/axi_current_state
add wave -noupdate -expand -group {AXI Slave State} /tb_msg_parser/DUT/AXIS/axi_next_state
add wave -noupdate -expand -group {Data Buffer State} /tb_msg_parser/DUT/CTRL/data_ctrl_current_state
add wave -noupdate -expand -group {Data Buffer State} /tb_msg_parser/DUT/CTRL/data_ctrl_next_state
add wave -noupdate -radix hexadecimal /tb_msg_parser/DUT/CTRL/msg_temp
add wave -noupdate /tb_msg_parser/DUT/CTRL/msg_temp_sync
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {168438 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 265
configure wave -valuecolwidth 139
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {426816 ps}
