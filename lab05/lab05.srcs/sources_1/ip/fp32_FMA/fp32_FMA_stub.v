// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (lin64) Build 2405991 Thu Dec  6 23:36:41 MST 2018
// Date        : Wed Mar 31 06:40:48 2021
// Host        : A07 running 64-bit Debian GNU/Linux 10 (buster)
// Command     : write_verilog -force -mode synth_stub
//               /csehome/baneling100/lab05/lab05.srcs/sources_1/ip/fp32_FMA/fp32_FMA_stub.v
// Design      : fp32_FMA
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "floating_point_v7_1_7,Vivado 2018.3" *)
module fp32_FMA(aclk, aresetn, s_axis_a_tvalid, s_axis_a_tdata, 
  s_axis_b_tvalid, s_axis_b_tdata, s_axis_c_tvalid, s_axis_c_tdata, m_axis_result_tvalid, 
  m_axis_result_tdata)
/* synthesis syn_black_box black_box_pad_pin="aclk,aresetn,s_axis_a_tvalid,s_axis_a_tdata[31:0],s_axis_b_tvalid,s_axis_b_tdata[31:0],s_axis_c_tvalid,s_axis_c_tdata[31:0],m_axis_result_tvalid,m_axis_result_tdata[31:0]" */;
  input aclk;
  input aresetn;
  input s_axis_a_tvalid;
  input [31:0]s_axis_a_tdata;
  input s_axis_b_tvalid;
  input [31:0]s_axis_b_tdata;
  input s_axis_c_tvalid;
  input [31:0]s_axis_c_tdata;
  output m_axis_result_tvalid;
  output [31:0]m_axis_result_tdata;
endmodule
