// Copyright (C) 2022  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.


// Generated by Quartus Prime Version 21.1 (Build Build 850 06/23/2022)
// Created on Fri Apr 14 11:57:52 2023

axis_async_fifo #(
)
axis_async_fifo_inst
(
	.s_clk(s_clk_sig),	
	.s_rst(s_rst_sig),	
	.s_axis_tdata(s_axis_tdata_sig),	
	.s_axis_tkeep(s_axis_tkeep_sig),	
	.s_axis_tvalid(s_axis_tvalid_sig),	
	.s_axis_tready(s_axis_tready_sig),	
	.s_axis_tlast(s_axis_tlast_sig),	
	.s_axis_tid(s_axis_tid_sig),	
	.s_axis_tdest(s_axis_tdest_sig),	
	.s_axis_tuser(s_axis_tuser_sig),	
	.m_clk(m_clk_sig),	
	.m_rst(m_rst_sig),	
	.m_axis_tdata(m_axis_tdata_sig),	
	.m_axis_tkeep(m_axis_tkeep_sig),	
	.m_axis_tvalid(m_axis_tvalid_sig),	
	.m_axis_tready(m_axis_tready_sig),	
	.m_axis_tlast(m_axis_tlast_sig),	
	.m_axis_tid(m_axis_tid_sig),	
	.m_axis_tdest(m_axis_tdest_sig),	
	.m_axis_tuser(m_axis_tuser_sig),	
	.s_status_overflow(s_status_overflow_sig),	
	.s_status_bad_frame(s_status_bad_frame_sig),	
	.s_status_good_frame(s_status_good_frame_sig),	
	.m_status_overflow(m_status_overflow_sig),	
	.m_status_bad_frame(m_status_bad_frame_sig),	
	.m_status_good_frame(m_status_good_frame_sig)
);

 
