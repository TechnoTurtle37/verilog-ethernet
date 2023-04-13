/*

Copyright (c) 2020 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA core logic
 */
module fpga_core #
(
    parameter TARGET = "GENERIC"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       clk90,
	input  wire       CLK_50,
    input  wire       clk_dram_c,
    input  wire       clk_dram,
    input  wire       pll_locked_dram, 
    input  wire       rst,

    /*
     * GPIO
     */
    input  wire [3:0]  btn,
    input  wire [17:0] sw,
    output wire [8:0]  ledg,
    output wire [17:0] ledr,
    output wire [6:0]  hex0,
    output wire [6:0]  hex1,
    output wire [6:0]  hex2,
    output wire [6:0]  hex3,
    output wire [6:0]  hex4,
    output wire [6:0]  hex5,
    output wire [6:0]  hex6,
    output wire [6:0]  hex7,
    output wire [35:0] gpio,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire         phy0_rx_clk,
    input  wire [3:0]   phy0_rxd,
    input  wire         phy0_rx_ctl,
    output wire         phy0_tx_clk,
    output wire [3:0]   phy0_txd,
    output wire         phy0_tx_ctl,
    output wire         phy0_reset_n,
    input  wire         phy0_int_n,

    input  wire         phy1_rx_clk,
    input  wire [3:0]   phy1_rxd,
    input  wire         phy1_rx_ctl,
    output wire         phy1_tx_clk,
    output wire [3:0]   phy1_txd,
    output wire         phy1_tx_ctl,
    output wire         phy1_reset_n,
    input  wire         phy1_int_n,
	 
	output wire		    uart_tx,
	input wire 		    uart_rx,

    output wire [12:0]  dram_addr,
    output wire [1:0]   dram_bank,
    output wire         dram_cas_n,
    output wire         dram_ras_n,
    output wire         dram_cke,
    output wire         dram_clk,
    output wire         dram_cs_n,
    inout wire  [31:0]  dram_dq,
    output wire [3:0]   dram_dqm,
    output wire         dram_we_n

);

reg [63:0]  debug;

// AXI between MAC and Ethernet modules
wire [7:0]  rx0_axis_tdata;
wire        rx0_axis_tvalid;
wire        rx0_axis_tready;
wire        rx0_axis_tlast;
wire        rx0_axis_tuser;

wire [7:0]  tx0_axis_tdata;
wire        tx0_axis_tvalid;
wire        tx0_axis_tready;
wire        tx0_axis_tlast;
wire        tx0_axis_tuser;

wire [7:0]  rx1_axis_tdata;
wire        rx1_axis_tvalid;
wire        rx1_axis_tready;
wire        rx1_axis_tlast;
wire        rx1_axis_tuser;

wire [7:0]  tx1_axis_tdata;
wire        tx1_axis_tvalid;
wire        tx1_axis_tready;
wire        tx1_axis_tlast;
wire        tx1_axis_tuser;

wire [7:0]  rx0_axis_tap_tdata;
wire        rx0_axis_tap_tvalid;
wire        rx0_axis_tap_tready;
wire        rx0_axis_tap_tlast;
wire        rx0_axis_tap_tuser;

wire [7:0]  rx1_axis_tap_tdata;
wire        rx1_axis_tap_tvalid;
wire        rx1_axis_tap_tready;
wire        rx1_axis_tap_tlast;
wire        rx1_axis_tap_tuser;

// Ethernet frame between Ethernet modules and UDP stack
wire        rx0_eth_hdr_ready;
wire        rx0_eth_hdr_valid;
wire [47:0] rx0_eth_dest_mac;
wire [47:0] rx0_eth_src_mac;
wire [15:0] rx0_eth_type;
wire [7:0]  rx0_eth_payload_axis_tdata;
wire        rx0_eth_payload_axis_tvalid;
wire        rx0_eth_payload_axis_tready;
wire        rx0_eth_payload_axis_tlast;
wire        rx0_eth_payload_axis_tuser;

wire        rx1_eth_hdr_ready;
wire        rx1_eth_hdr_valid;
wire [47:0] rx1_eth_dest_mac;
wire [47:0] rx1_eth_src_mac;
wire [15:0] rx1_eth_type;
wire [7:0]  rx1_eth_payload_axis_tdata;
wire        rx1_eth_payload_axis_tvalid;
wire        rx1_eth_payload_axis_tready;
wire        rx1_eth_payload_axis_tlast;
wire        rx1_eth_payload_axis_tuser;

// IP frame connections
wire        rx_ip0_hdr_valid;
wire        rx_ip0_hdr_ready;
wire [47:0] rx_ip0_eth_dest_mac;
wire [47:0] rx_ip0_eth_src_mac;
wire [15:0] rx_ip0_eth_type;
wire [3:0]  rx_ip0_version;
wire [3:0]  rx_ip0_ihl;
wire [5:0]  rx_ip0_dscp;
wire [1:0]  rx_ip0_ecn;
wire [15:0] rx_ip0_length;
wire [15:0] rx_ip0_identification;
wire [2:0]  rx_ip0_flags;
wire [12:0] rx_ip0_fragment_offset;
wire [7:0]  rx_ip0_ttl;
wire [7:0]  rx_ip0_protocol;
wire [15:0] rx_ip0_header_checksum;
wire [31:0] rx_ip0_source_ip;
wire [31:0] rx_ip0_dest_ip;
wire [7:0]  rx_ip0_payload_axis_tdata;
wire        rx_ip0_payload_axis_tvalid;
wire        rx_ip0_payload_axis_tready;
wire        rx_ip0_payload_axis_tlast;
wire        rx_ip0_payload_axis_tuser;

wire        rx_ip1_hdr_valid;
wire        rx_ip1_hdr_ready;
wire [47:0] rx_ip1_eth_dest_mac;
wire [47:0] rx_ip1_eth_src_mac;
wire [15:0] rx_ip1_eth_type;
wire [3:0]  rx_ip1_version;
wire [3:0]  rx_ip1_ihl;
wire [5:0]  rx_ip1_dscp;
wire [1:0]  rx_ip1_ecn;
wire [15:0] rx_ip1_length;
wire [15:0] rx_ip1_identification;
wire [2:0]  rx_ip1_flags;
wire [12:0] rx_ip1_fragment_offset;
wire [7:0]  rx_ip1_ttl;
wire [7:0]  rx_ip1_protocol;
wire [15:0] rx_ip1_header_checksum;
wire [31:0] rx_ip1_source_ip;
wire [31:0] rx_ip1_dest_ip;
wire [7:0]  rx_ip1_payload_axis_tdata;
wire        rx_ip1_payload_axis_tvalid;
wire        rx_ip1_payload_axis_tready;
wire        rx_ip1_payload_axis_tlast;
wire        rx_ip1_payload_axis_tuser;

// UDP frame connections
wire        rx_udp0_hdr_valid;
wire        rx_udp0_hdr_ready;
wire [47:0] rx_udp0_eth_dest_mac;
wire [47:0] rx_udp0_eth_src_mac;
wire [15:0] rx_udp0_eth_type;
wire [3:0]  rx_udp0_ip_version;
wire [3:0]  rx_udp0_ip_ihl;
wire [5:0]  rx_udp0_ip_dscp;
wire [1:0]  rx_udp0_ip_ecn;
wire [15:0] rx_udp0_ip_length;
wire [15:0] rx_udp0_ip_identification;
wire [2:0]  rx_udp0_ip_flags;
wire [12:0] rx_udp0_ip_fragment_offset;
wire [7:0]  rx_udp0_ip_ttl;
wire [7:0]  rx_udp0_ip_protocol;
wire [15:0] rx_udp0_ip_header_checksum;
wire [31:0] rx_udp0_ip_source_ip;
wire [31:0] rx_udp0_ip_dest_ip;
wire [15:0] rx_udp0_source_port;
wire [15:0] rx_udp0_dest_port;
wire [15:0] rx_udp0_length;
wire [15:0] rx_udp0_checksum;
wire [7:0]  rx_udp0_payload_axis_tdata;
wire        rx_udp0_payload_axis_tvalid;
wire        rx_udp0_payload_axis_tready;
wire        rx_udp0_payload_axis_tlast;
wire        rx_udp0_payload_axis_tuser;

wire        rx_udp1_hdr_valid;
wire        rx_udp1_hdr_ready;
wire [47:0] rx_udp1_eth_dest_mac;
wire [47:0] rx_udp1_eth_src_mac;
wire [15:0] rx_udp1_eth_type;
wire [3:0]  rx_udp1_ip_version;
wire [3:0]  rx_udp1_ip_ihl;
wire [5:0]  rx_udp1_ip_dscp;
wire [1:0]  rx_udp1_ip_ecn;
wire [15:0] rx_udp1_ip_length;
wire [15:0] rx_udp1_ip_identification;
wire [2:0]  rx_udp1_ip_flags;
wire [12:0] rx_udp1_ip_fragment_offset;
wire [7:0]  rx_udp1_ip_ttl;
wire [7:0]  rx_udp1_ip_protocol;
wire [15:0] rx_udp1_ip_header_checksum;
wire [31:0] rx_udp1_ip_source_ip;
wire [31:0] rx_udp1_ip_dest_ip;
wire [15:0] rx_udp1_source_port;
wire [15:0] rx_udp1_dest_port;
wire [15:0] rx_udp1_length;
wire [15:0] rx_udp1_checksum;
wire [7:0]  rx_udp1_payload_axis_tdata;
wire        rx_udp1_payload_axis_tvalid;
wire        rx_udp1_payload_axis_tready;
wire        rx_udp1_payload_axis_tlast;
wire        rx_udp1_payload_axis_tuser;

wire            dns0_valid;
wire            dns0_ready;
wire [31:0]     dns0_source_ip;
wire [31:0]     dns0_dest_ip;
wire [15:0]     dns0_length;
wire [4095:0]   dns0_pkt;

wire [15:0]     hdr_id;//output[15:0]hdr_id_sig
wire            hdr_qr;//outputhdr_qr_sig
wire [3:0]      hdr_opcode;//output[3:0]hdr_opcode_sig
wire            hdr_aa;//outputhdr_aa_sig
wire            hdr_tc;//outputhdr_tc_sig
wire            hdr_rd;//outputhdr_rd_sig
wire            hdr_ra;//outputhdr_ra_sig
wire [2:0]      hdr_z;//output[2:0]hdr_z_sig
wire [3:0]      hdr_rcode;//output[3:0]hdr_rcode_sig
wire [15:0]     hdr_qdcount;//output[15:0]hdr_qdcount_sig
wire [15:0]     hdr_ancount;//output[15:0]hdr_ancount_sig
wire [15:0]     hdr_nscount;//output[15:0]hdr_nscount_sig
wire [15:0]     hdr_arcount;//output[15:0]hdr_arcount_sig
wire [252:0]    qry_name;//output[252:0]qry_name_sig
wire [15:0]     qry_type;//output[15:0]qry_type_sig
wire [15:0]     qry_class;//output[15:0]qry_class_sig
wire [255:0]    ans_name;//output[255:0]ans_name_sig
wire [15:0]     ans_type;//output[15:0]ans_type_sig
wire [15:0]     ans_class;//output[15:0]ans_class_sig
wire [31:0]     ans_ttl;//output[31:0]ans_ttl_sig
wire [15:0]     ans_datalen;//output[15:0]ans_datalen_sig
wire [31:0]     ans_addr;//output[31:0]ans_addr_sig


wire [7:0]  rx_fifo_udp_payload_axis_tdata;
wire        rx_fifo_udp_payload_axis_tvalid;
wire        rx_fifo_udp_payload_axis_tready;
wire        rx_fifo_udp_payload_axis_tlast;
wire        rx_fifo_udp_payload_axis_tuser;

wire [7:0]  tx_fifo_udp_payload_axis_tdata;
wire        tx_fifo_udp_payload_axis_tvalid;
wire        tx_fifo_udp_payload_axis_tready;
wire        tx_fifo_udp_payload_axis_tlast;
wire        tx_fifo_udp_payload_axis_tuser;

wire [23:0] s_axis_config_tdata;
wire        s_axis_config_tvalid;






//assign led = sw;

assign phy0_reset_n = ~rst;
assign phy1_reset_n = ~rst;

assign tx1_axis_tdata = rx0_axis_tdata;
assign tx0_axis_tdata = rx1_axis_tdata;
assign tx1_axis_tvalid = rx0_axis_tvalid;
assign rx1_axis_tready = tx0_axis_tready;
assign tx0_axis_tvalid = rx1_axis_tvalid;
assign rx0_axis_tready = tx1_axis_tready;
assign tx1_axis_tlast = rx0_axis_tlast;
assign tx0_axis_tlast = rx1_axis_tlast;

// reg[7:0] cnt;
// reg out;
// always @(*) begin
//     if (rst) begin
//         debug <= 64'b0;
//         cnt <= 4'd0;
//     end
//     else begin 
//         debug <= {rx_udp0_dest_port, rx_udp0_eth_src_mac};
//         out <= debug[cnt];
//         cnt <= cnt + 1;
//     end
// end




// transmitter uart_transmitter(
//     .clk(clk),
//     .reset(rst),
//     .transmit(1'b1),
//     .data(rx0_eth_src_mac[7:0]),
//     .TxD(uart_tx)
// );




assign gpio = 0;

// eth_mac_1g_rgmii_fifo #(
//     .TARGET(TARGET),
//     .USE_CLK90("TRUE"),
//     .ENABLE_PADDING(1),
//     .MIN_FRAME_LENGTH(64),
//     .TX_FIFO_DEPTH(4096),
//     .TX_FRAME_FIFO(1),
//     .RX_FIFO_DEPTH(4096),
//     .RX_FRAME_FIFO(1)
// )
// eth_mac_inst0 (
//     .gtx_clk(clk),
//     .gtx_clk90(clk90),
//     .gtx_rst(rst),
//     .logic_clk(clk),
//     .logic_rst(rst),

//     .tx_axis_tdata(tx0_axis_tdata),
//     .tx_axis_tvalid(tx0_axis_tvalid),
//     .tx_axis_tready(tx0_axis_tready),
//     .tx_axis_tlast(tx0_axis_tlast),
//     .tx_axis_tuser(tx0_axis_tuser),

//     .rx_axis_tdata(rx0_axis_tdata),
//     .rx_axis_tvalid(rx0_axis_tvalid),
//     .rx_axis_tready(rx0_axis_tready),
//     .rx_axis_tlast(rx0_axis_tlast),
//     .rx_axis_tuser(rx0_axis_tuser),

//     .rgmii_rx_clk(phy0_rx_clk),
//     .rgmii_rxd(phy0_rxd),
//     .rgmii_rx_ctl(phy0_rx_ctl),
//     .rgmii_tx_clk(phy0_tx_clk),
//     .rgmii_txd(phy0_txd),
//     .rgmii_tx_ctl(phy0_tx_ctl),
    
//     .tx_fifo_overflow(),
//     .tx_fifo_bad_frame(),
//     .tx_fifo_good_frame(),
//     .rx_error_bad_frame(),
//     .rx_error_bad_fcs(),
//     .rx_fifo_overflow(),
//     .rx_fifo_bad_frame(),
//     .rx_fifo_good_frame(),
//     .speed(),

//     .ifg_delay(12)
// );

// eth_mac_1g_rgmii_fifo #(
//     .TARGET(TARGET),
//     .USE_CLK90("TRUE"),
//     .ENABLE_PADDING(1),
//     .MIN_FRAME_LENGTH(64),
//     .TX_FIFO_DEPTH(4096),
//     .TX_FRAME_FIFO(1),
//     .RX_FIFO_DEPTH(4096),
//     .RX_FRAME_FIFO(1)
// )
// eth_mac_inst1 (
//     .gtx_clk(clk),
//     .gtx_clk90(clk90),
//     .gtx_rst(rst),
//     .logic_clk(clk),
//     .logic_rst(rst),

//     .tx_axis_tdata(tx1_axis_tdata),
//     .tx_axis_tvalid(tx1_axis_tvalid),
//     .tx_axis_tready(tx1_axis_tready),
//     .tx_axis_tlast(tx1_axis_tlast),
//     .tx_axis_tuser(tx1_axis_tuser),

//     .rx_axis_tdata(rx1_axis_tdata),
//     .rx_axis_tvalid(rx1_axis_tvalid),
//     .rx_axis_tready(rx1_axis_tready),
//     .rx_axis_tlast(rx1_axis_tlast),
//     .rx_axis_tuser(rx1_axis_tuser),

//     .rgmii_rx_clk(phy1_rx_clk),
//     .rgmii_rxd(phy1_rxd),
//     .rgmii_rx_ctl(phy1_rx_ctl),
//     .rgmii_tx_clk(phy1_tx_clk),
//     .rgmii_txd(phy1_txd),
//     .rgmii_tx_ctl(phy1_tx_ctl),
    
//     .tx_fifo_overflow(),
//     .tx_fifo_bad_frame(),
//     .tx_fifo_good_frame(),
//     .rx_error_bad_frame(),
//     .rx_error_bad_fcs(),
//     .rx_fifo_overflow(),
//     .rx_fifo_bad_frame(),
//     .rx_fifo_good_frame(),
//     .speed(),

//     .ifg_delay(12)
// );

// axis_tap
// axis_tap0 (

//     .clk(clk),
//     .rst(rst),
//     .tap_axis_tdata(rx0_axis_tdata),
//     .tap_axis_tvalid(rx0_axis_tvalid),
//     .tap_axis_tready(rx0_axis_tready),
//     .tap_axis_tlast(rx0_axis_tlast),
//     .tap_axis_tuser(rx0_axis_tuser),

//     .m_axis_tdata(rx0_axis_tap_tdata),
//     .m_axis_tvalid(rx0_axis_tap_tvalid),
//     .m_axis_tready(rx0_axis_tap_tready),
//     .m_axis_tlast(rx0_axis_tap_tlast),
//     .m_axis_tuser(rx0_axis_tap_tuser)
// );

// axis_tap
// axis_tap1 (

//     .clk(clk),
//     .rst(rst),
//     .tap_axis_tdata(rx1_axis_tdata),
//     .tap_axis_tvalid(rx1_axis_tvalid),
//     .tap_axis_tready(rx1_axis_tready),
//     .tap_axis_tlast(rx1_axis_tlast),
//     .tap_axis_tuser(rx1_axis_tuser),

//     .m_axis_tdata(rx1_axis_tap_tdata),
//     .m_axis_tvalid(rx1_axis_tap_tvalid),
//     .m_axis_tready(rx1_axis_tap_tready),
//     .m_axis_tlast(rx1_axis_tap_tlast),
//     .m_axis_tuser(rx1_axis_tap_tuser)
// );

// eth_axis_rx

// eth_axis_rx0_inst (
//     .clk(clk),
//     .rst(rst),
//     // AXI input
//     .s_axis_tdata(rx0_axis_tap_tdata),
//     .s_axis_tvalid(rx0_axis_tap_tvalid),
//     .s_axis_tready(rx0_axis_tap_tready),
//     .s_axis_tlast(rx0_axis_tap_tlast),
//     .s_axis_tuser(rx0_axis_tap_tuser),
//     // Ethernet frame output
//     .m_eth_hdr_valid(rx0_eth_hdr_valid),
//     .m_eth_hdr_ready(rx0_eth_hdr_ready),
//     .m_eth_dest_mac(rx0_eth_dest_mac),
//     .m_eth_src_mac(rx0_eth_src_mac),
//     .m_eth_type(rx0_eth_type),
//     .m_eth_payload_axis_tdata(rx0_eth_payload_axis_tdata),
//     .m_eth_payload_axis_tvalid(rx0_eth_payload_axis_tvalid),
//     .m_eth_payload_axis_tready(rx0_eth_payload_axis_tready),
//     .m_eth_payload_axis_tlast(rx0_eth_payload_axis_tlast),
//     .m_eth_payload_axis_tuser(rx0_eth_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination()
// );

// eth_axis_rx
// eth_axis_rx1_inst (
//     .clk(clk),
//     .rst(rst),
//     // AXI input
//     .s_axis_tdata(rx1_axis_tap_tdata),
//     .s_axis_tvalid(rx1_axis_tap_tvalid),
//     .s_axis_tready(rx1_axis_tap_tready),
//     .s_axis_tlast(rx1_axis_tap_tlast),
//     .s_axis_tuser(rx1_axis_tap_tuser),
//     // Ethernet frame output
//     .m_eth_hdr_valid(rx1_eth_hdr_valid),
//     .m_eth_hdr_ready(rx1_eth_hdr_ready),
//     .m_eth_dest_mac(rx1_eth_dest_mac),
//     .m_eth_src_mac(rx1_eth_src_mac),
//     .m_eth_type(rx1_eth_type),
//     .m_eth_payload_axis_tdata(rx1_eth_payload_axis_tdata),
//     .m_eth_payload_axis_tvalid(rx1_eth_payload_axis_tvalid),
//     .m_eth_payload_axis_tready(rx1_eth_payload_axis_tready),
//     .m_eth_payload_axis_tlast(rx1_eth_payload_axis_tlast),
//     .m_eth_payload_axis_tuser(rx1_eth_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination()
// );

// ip_eth_rx
// ip0_eth_rx_inst (
//     .clk(clk),
//     .rst(rst),
//     // Ethernet frame input
//     .s_eth_hdr_valid(rx0_eth_hdr_valid),
//     .s_eth_hdr_ready(rx0_eth_hdr_ready),
//     .s_eth_dest_mac(rx0_eth_dest_mac),
//     .s_eth_src_mac(rx0_eth_src_mac),
//     .s_eth_type(rx0_eth_type),
//     .s_eth_payload_axis_tdata(rx0_eth_payload_axis_tdata),
//     .s_eth_payload_axis_tvalid(rx0_eth_payload_axis_tvalid),
//     .s_eth_payload_axis_tready(rx0_eth_payload_axis_tready),
//     .s_eth_payload_axis_tlast(rx0_eth_payload_axis_tlast),
//     .s_eth_payload_axis_tuser(rx0_eth_payload_axis_tuser),
//     // IP frame output
//     .m_ip_hdr_valid(rx_ip0_hdr_valid),
//     .m_ip_hdr_ready(rx_ip0_hdr_ready),
//     .m_eth_dest_mac(rx_ip0_eth_dest_mac),
//     .m_eth_src_mac(rx_ip0_eth_src_mac),
//     .m_eth_type(rx_ip0_eth_type),
//     .m_ip_version(rx_ip0_version),
//     .m_ip_ihl(rx_ip0_ihl),
//     .m_ip_dscp(rx_ip0_dscp),
//     .m_ip_ecn(rx_ip0_ecn),
//     .m_ip_length(rx_ip0_length),
//     .m_ip_identification(rx_ip0_identification),
//     .m_ip_flags(rx_ip0_flags),
//     .m_ip_fragment_offset(rx_ip0_fragment_offset),
//     .m_ip_ttl(rx_ip0_ttl),
//     .m_ip_protocol(rx_ip0_protocol),
//     .m_ip_header_checksum(rx_ip0_header_checksum),
//     .m_ip_source_ip(rx_ip0_source_ip),
//     .m_ip_dest_ip(rx_ip0_dest_ip),
//     .m_ip_payload_axis_tdata(rx_ip0_payload_axis_tdata),
//     .m_ip_payload_axis_tvalid(rx_ip0_payload_axis_tvalid),
//     .m_ip_payload_axis_tready(rx_ip0_payload_axis_tready),
//     .m_ip_payload_axis_tlast(rx_ip0_payload_axis_tlast),
//     .m_ip_payload_axis_tuser(rx_ip0_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination(),
//     .error_payload_early_termination(),
//     .error_invalid_header(),
//     .error_invalid_checksum()
// );

// ip_eth_rx
// ip1_eth_rx_inst (
//     .clk(clk),
//     .rst(rst),
//     // Ethernet frame input
//     .s_eth_hdr_valid(rx1_eth_hdr_valid),
//     .s_eth_hdr_ready(rx1_eth_hdr_ready),
//     .s_eth_dest_mac(rx1_eth_dest_mac),
//     .s_eth_src_mac(rx1_eth_src_mac),
//     .s_eth_type(rx1_eth_type),
//     .s_eth_payload_axis_tdata(rx1_eth_payload_axis_tdata),
//     .s_eth_payload_axis_tvalid(rx1_eth_payload_axis_tvalid),
//     .s_eth_payload_axis_tready(rx1_eth_payload_axis_tready),
//     .s_eth_payload_axis_tlast(rx1_eth_payload_axis_tlast),
//     .s_eth_payload_axis_tuser(rx1_eth_payload_axis_tuser),
//     // IP frame output
//     .m_ip_hdr_valid(rx_ip1_hdr_valid),
//     .m_ip_hdr_ready(rx_ip1_hdr_ready),
//     .m_eth_dest_mac(rx_ip1_eth_dest_mac),
//     .m_eth_src_mac(rx_ip1_eth_src_mac),
//     .m_eth_type(rx_ip1_eth_type),
//     .m_ip_version(rx_ip1_version),
//     .m_ip_ihl(rx_ip1_ihl),
//     .m_ip_dscp(rx_ip1_dscp),
//     .m_ip_ecn(rx_ip1_ecn),
//     .m_ip_length(rx_ip1_length),
//     .m_ip_identification(rx_ip1_identification),
//     .m_ip_flags(rx_ip1_flags),
//     .m_ip_fragment_offset(rx_ip1_fragment_offset),
//     .m_ip_ttl(rx_ip1_ttl),
//     .m_ip_protocol(rx_ip1_protocol),
//     .m_ip_header_checksum(rx_ip1_header_checksum),
//     .m_ip_source_ip(rx_ip1_source_ip),
//     .m_ip_dest_ip(rx_ip1_dest_ip),
//     .m_ip_payload_axis_tdata(rx_ip1_payload_axis_tdata),
//     .m_ip_payload_axis_tvalid(rx_ip1_payload_axis_tvalid),
//     .m_ip_payload_axis_tready(rx_ip1_payload_axis_tready),
//     .m_ip_payload_axis_tlast(rx_ip1_payload_axis_tlast),
//     .m_ip_payload_axis_tuser(rx_ip1_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination(),
//     .error_payload_early_termination(),
//     .error_invalid_header(),
//     .error_invalid_checksum()
// );

// udp_ip_rx
// udp0_ip_rx_inst (
//     .clk(clk),
//     .rst(rst),
//     // IP frame input
//     .s_ip_hdr_valid(rx_ip0_hdr_valid),
//     .s_ip_hdr_ready(rx_ip0_hdr_ready),
//     .s_eth_dest_mac(rx_ip0_eth_dest_mac),
//     .s_eth_src_mac(rx_ip0_eth_src_mac),
//     .s_eth_type(rx_ip0_eth_type),
//     .s_ip_version(rx_ip0_version),
//     .s_ip_ihl(rx_ip0_ihl),
//     .s_ip_dscp(rx_ip0_dscp),
//     .s_ip_ecn(rx_ip0_ecn),
//     .s_ip_length(rx_ip0_length),
//     .s_ip_identification(rx_ip0_identification),
//     .s_ip_flags(rx_ip0_flags),
//     .s_ip_fragment_offset(rx_ip0_fragment_offset),
//     .s_ip_ttl(rx_ip0_ttl),
//     .s_ip_protocol(rx_ip0_protocol),
//     .s_ip_header_checksum(rx_ip0_header_checksum),
//     .s_ip_source_ip(rx_ip0_source_ip),
//     .s_ip_dest_ip(rx_ip0_dest_ip),
//     .s_ip_payload_axis_tdata(rx_ip0_payload_axis_tdata),
//     .s_ip_payload_axis_tvalid(rx_ip0_payload_axis_tvalid),
//     .s_ip_payload_axis_tready(rx_ip0_payload_axis_tready),
//     .s_ip_payload_axis_tlast(rx_ip0_payload_axis_tlast),
//     .s_ip_payload_axis_tuser(rx_ip0_payload_axis_tuser),
//     // UDP frame output
//     .m_udp_hdr_valid(rx_udp0_hdr_valid),
//     .m_udp_hdr_ready(rx_udp0_hdr_ready),
//     .m_eth_dest_mac(rx_udp0_eth_dest_mac),
//     .m_eth_src_mac(rx_udp0_eth_src_mac),
//     .m_eth_type(rx_udp0_eth_type),
//     .m_ip_version(rx_udp0_ip_version),
//     .m_ip_ihl(rx_udp0_ip_ihl),
//     .m_ip_dscp(rx_udp0_ip_dscp),
//     .m_ip_ecn(rx_udp0_ip_ecn),
//     .m_ip_length(rx_udp0_ip_length),
//     .m_ip_identification(rx_udp0_ip_identification),
//     .m_ip_flags(rx_udp0_ip_flags),
//     .m_ip_fragment_offset(rx_udp0_ip_fragment_offset),
//     .m_ip_ttl(rx_udp0_ip_ttl),
//     .m_ip_protocol(rx_udp0_ip_protocol),
//     .m_ip_header_checksum(rx_udp0_ip_header_checksum),
//     .m_ip_source_ip(rx_udp0_ip_source_ip), //Needed
//     .m_ip_dest_ip(rx_udp0_ip_dest_ip),
//     .m_udp_source_port(rx_udp0_source_port),
//     .m_udp_dest_port(rx_udp0_dest_port), //Needs to be 53
//     .m_udp_length(rx_udp0_length), //Maybe
//     .m_udp_checksum(rx_udp0_checksum),
//     .m_udp_payload_axis_tdata(rx_udp0_payload_axis_tdata),
//     .m_udp_payload_axis_tvalid(rx_udp0_payload_axis_tvalid),
//     .m_udp_payload_axis_tready(rx_udp0_payload_axis_tready),
//     .m_udp_payload_axis_tlast(rx_udp0_payload_axis_tlast),
//     .m_udp_payload_axis_tuser(rx_udp0_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination(),
//     .error_payload_early_termination()
// );

// udp_ip_rx
// udp1_ip_rx_inst (
//     .clk(clk),
//     .rst(rst),
//     // IP frame input
//     .s_ip_hdr_valid(rx_ip1_hdr_valid),
//     .s_ip_hdr_ready(rx_ip1_hdr_ready),
//     .s_eth_dest_mac(rx_ip1_eth_dest_mac),
//     .s_eth_src_mac(rx_ip1_eth_src_mac),
//     .s_eth_type(rx_ip1_eth_type),
//     .s_ip_version(rx_ip1_version),
//     .s_ip_ihl(rx_ip1_ihl),
//     .s_ip_dscp(rx_ip1_dscp),
//     .s_ip_ecn(rx_ip1_ecn),
//     .s_ip_length(rx_ip1_length),
//     .s_ip_identification(rx_ip1_identification),
//     .s_ip_flags(rx_ip1_flags),
//     .s_ip_fragment_offset(rx_ip1_fragment_offset),
//     .s_ip_ttl(rx_ip1_ttl),
//     .s_ip_protocol(rx_ip1_protocol),
//     .s_ip_header_checksum(rx_ip1_header_checksum),
//     .s_ip_source_ip(rx_ip1_source_ip),
//     .s_ip_dest_ip(rx_ip1_dest_ip),
//     .s_ip_payload_axis_tdata(rx_ip1_payload_axis_tdata),
//     .s_ip_payload_axis_tvalid(rx_ip1_payload_axis_tvalid),
//     .s_ip_payload_axis_tready(rx_ip1_payload_axis_tready),
//     .s_ip_payload_axis_tlast(rx_ip1_payload_axis_tlast),
//     .s_ip_payload_axis_tuser(rx_ip1_payload_axis_tuser),
//     // UDP frame output
//     .m_udp_hdr_valid(rx_udp1_hdr_valid),
//     .m_udp_hdr_ready(rx_udp1_hdr_ready),
//     .m_eth_dest_mac(rx_udp1_eth_dest_mac),
//     .m_eth_src_mac(rx_udp1_eth_src_mac),
//     .m_eth_type(rx_udp1_eth_type),
//     .m_ip_version(rx_udp1_ip_version),
//     .m_ip_ihl(rx_udp1_ip_ihl),
//     .m_ip_dscp(rx_udp1_ip_dscp),
//     .m_ip_ecn(rx_udp1_ip_ecn),
//     .m_ip_length(rx_udp1_ip_length),
//     .m_ip_identification(rx_udp1_ip_identification),
//     .m_ip_flags(rx_udp1_ip_flags),
//     .m_ip_fragment_offset(rx_udp1_ip_fragment_offset),
//     .m_ip_ttl(rx_udp1_ip_ttl),
//     .m_ip_protocol(rx_udp1_ip_protocol),
//     .m_ip_header_checksum(rx_udp1_ip_header_checksum),
//     .m_ip_source_ip(rx_udp1_ip_source_ip),
//     .m_ip_dest_ip(rx_udp1_ip_dest_ip),
//     .m_udp_source_port(rx_udp1_source_port),
//     .m_udp_dest_port(rx_udp1_dest_port),
//     .m_udp_length(rx_udp1_length),
//     .m_udp_checksum(rx_udp1_checksum),
//     .m_udp_payload_axis_tdata(rx_udp1_payload_axis_tdata),
//     .m_udp_payload_axis_tvalid(rx_udp1_payload_axis_tvalid),
//     .m_udp_payload_axis_tready(rx_udp1_payload_axis_tready),
//     .m_udp_payload_axis_tlast(rx_udp1_payload_axis_tlast),
//     .m_udp_payload_axis_tuser(rx_udp1_payload_axis_tuser),
//     // Status signals
//     .busy(),
//     .error_header_early_termination(),
//     .error_payload_early_termination()
// );

// dns_ip_rx 
// dns0_ip_rx_inst
// (
// 	.clk(clk),	
// 	.rst(rst),	
// 	.s_udp_hdr_valid(rx_udp1_hdr_valid),	
// 	.s_udp_hdr_ready(rx_udp1_hdr_ready),
// 	.s_udp_source_port(rx_udp1_source_port),	
// 	.s_udp_dest_port(rx_udp1_dest_port),	
// 	.s_udp_source_ip(rx_udp1_ip_source_ip),	
// 	.s_udp_dest_ip(rx_udp1_ip_dest_ip),	
// 	.s_udp_length(rx_udp1_length),	
// 	.s_udp_payload_axis_tdata(rx_udp1_payload_axis_tdata),	
// 	.s_udp_payload_axis_tvalid(rx_udp1_payload_axis_tvalid),	
// 	.s_udp_payload_axis_tready(rx_udp1_payload_axis_tready),	
// 	.s_udp_payload_axis_tlast(rx_udp1_payload_axis_tlast),	
// 	.s_udp_payload_axis_tuser(rx_udp1_payload_axis_tuser),	
// 	.m_dns_valid(dns0_valid),	
// 	.m_dns_ready(dns0_ready),	
// 	.m_udp_src_ip(dns0_source_ip),	
// 	.m_udp_dst_ip(dns0_dest_ip),	
// 	.m_udp_length(dns0_length),	
// 	.m_dns_pkt(dns0_pkt)
// );


// axis_uart_v1_0
// axis_uart (

//     .aclk(clk),
//     .aresetn(!rst),
//     .s_axis_config_tdata(),
//     .s_axis_config_tvalid(),
//     .s_axis_config_tready(),

//     .s_axis_tdata(hdr_id[15:8]),
//     .s_axis_tvalid(1),
//     .s_axis_tready(),

//     .m_axis_tdata(),
//     .m_axis_tuser(),
//     .m_axis_tvalid(),
//     .m_axis_tready(),

//     .tx(uart_tx),
//     .rx(),
//     .rts(),
//     .cts()
// );

// analyzer 
// analyzer_inst
// (
// 	.rst(rst) ,	// input  rst
// 	.clk(clk) ,	// input  clk
// 	.pkt(dns0_pkt) ,	// input [4095:0] pkt
// 	.pkt_valid(dns0_valid) ,	// input  pkt_valid
// 	.pkt_ready(dns0_ready), 	// output  pkt_ready
//     .hdr_id(hdr_id) ,	// output [15:0] hdr_id
// 	.hdr_qr(hdr_qr) ,	// output  hdr_qr
// 	.hdr_opcode(hdr_opcode) ,	// output [3:0] hdr_opcode
// 	.hdr_aa(hdr_aa) ,	// output  hdr_aa
// 	.hdr_tc(hdr_tc) ,	// output  hdr_tc
// 	.hdr_rd(hdr_rd) ,	// output  hdr_rd
// 	.hdr_ra(hdr_ra) ,	// output  hdr_ra
// 	.hdr_z(hdr_z) ,	// output [2:0] hdr_z
// 	.hdr_rcode(hdr_rcode) ,	// output [3:0] hdr_rcode
// 	.hdr_qdcount(hdr_qdcount) ,	// output [15:0] hdr_qdcount
// 	.hdr_ancount(hdr_ancount) ,	// output [15:0] hdr_ancount
// 	.hdr_nscount(hdr_nscount) ,	// output [15:0] hdr_nscount
// 	.hdr_arcount(hdr_arcount) ,	// output [15:0] hdr_arcount
// 	.qry_name(qry_name) ,	// output [252:0] qry_name
// 	.qry_type(qry_type) ,	// output [15:0] qry_type
// 	.qry_class(qry_class) ,	// output [15:0] qry_class
// 	.ans_name(ans_name) ,	// output [255:0] ans_name
// 	.ans_type(ans_type) ,	// output [15:0] ans_type
// 	.ans_class(ans_class) ,	// output [15:0] ans_class
// 	.ans_ttl(ans_ttl) ,	// output [31:0] ans_ttl
// 	.ans_datalen(ans_datalen) ,	// output [15:0] ans_datalen
// 	.ans_addr(ans_addr) 	// output [31:0] ans_addr
// );

sdram_controller
sdram_ctl (

    .clk(clk_dram_c),
    .clk_dram(clk_dram),
    .rst(rst),
    .dll_locked(pll_locked_dram),

    .dram_addr(dram_addr),
    .dram_bank(dram_bank),
    .dram_cas_n(dram_cas_n),
    .dram_ras_n(dram_ras_n),
    .dram_cke(dram_cke),
    .dram_clk(dram_clk),
    .dram_cs_n(dram_cs_n),
    .dram_dq(dram_dq),
    .dram_dqm(dram_dqm),
    .dram_we_n(dram_we_n),

    .addr_i({sw[14:4], 14'b0}),
    .dat_i({28'b0,sw[3:0]}),
    .dat_o({28'b0,ledg[3:0]}),
    .we_i(sw[17]),
    .ack_o(ledg[7]),
    .stb_i(sw[16]),
    .cyc_i(sw[15])

);

// transmitter transmitter_inst( 
//     .clk(clk), 
//     .reset(rst), 
//     .transmit(rx_udp1_hdr_valid),
//     .data(rx_udp1_eth_src_mac[7:0]),
//     .TxD(uart_tx)
// );

//assign ledg[3:0] = sw[3:0];
assign ledr[0] = rx_udp1_eth_src_mac==48'h2020000000aa;
//assign ledg[7:0] = {rx1_axis_tap_tvalid,rx1_axis_tap_tready,rx1_axis_tready,rx1_axis_tvalid,rx0_axis_tvalid};

endmodule

`resetall
