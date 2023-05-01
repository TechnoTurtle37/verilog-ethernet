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
     * clk          : 125MHz
     * clk_dram     : 133MHz
     * clk_dram_c   : 133HMz (-150deg out of phase from clk_dram)
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
	 
    // RS-232 Signals
	output wire		    uart_tx,
	input wire 		    uart_rx,

    //DRAM Signals
    output wire [12:0]  dram_addr,
    output wire [1:0]   dram_bank,
    output wire         dram_cas_n,
    output wire         dram_ras_n,
    output wire         dram_cke,
    output wire         dram_clk,
    output wire         dram_cs_n,
    inout wire  [31:0]  dram_dq,
    output wire [3:0]   dram_dqm,
    output wire         dram_we_n,

    output wire [24:0] ext_sdram_wb_addr_i,
    output wire [31:0] ext_sdram_wb_data_i,
    input wire [31:0] ext_sdram_wb_data_o,
    output wire        ext_sdram_wb_we_i,
    input wire        ext_sdram_wb_ack_o,
    output wire        ext_sdram_wb_stb_i,
    output wire        ext_sdram_wb_cyc_i,

	output wire [7:0] ext_uart_data,
	output wire ext_uart_valid,
	input wire ext_uart_ready

);

// AXI between mac0 and eth0 recieved data from Ethernet (is a transmit signal)
wire [7:0]  rx0_axis_tdata;
wire        rx0_axis_tvalid;
wire        rx0_axis_tready;
wire        rx0_axis_tlast;
wire        rx0_axis_tuser;

// AXI between mac0 and eth0 transmitted data from Ethernet (is a recieve signal)
wire [7:0]  tx0_axis_tdata;
wire        tx0_axis_tvalid;
wire        tx0_axis_tready;
wire        tx0_axis_tlast;
wire        tx0_axis_tuser;

// AXI between mac1 and eth1 recieved data from Ethernet (is a transmit signal)
wire [7:0]  rx1_axis_tdata;
wire        rx1_axis_tvalid;
wire        rx1_axis_tready;
wire        rx1_axis_tlast;
wire        rx1_axis_tuser;

// AXI between mac1 and eth1 transmitted data from Ethernet (is a recieve signal)
wire [7:0]  tx1_axis_tdata;
wire        tx1_axis_tvalid;
wire        tx1_axis_tready;
wire        tx1_axis_tlast;
wire        tx1_axis_tuser;



//TAPed RX data from phy0
wire [7:0]  rx0_axis_tap_tdata;
wire        rx0_axis_tap_tvalid;
wire        rx0_axis_tap_tready;
wire        rx0_axis_tap_tlast;
wire        rx0_axis_tap_tuser;



// Asynchronous FIFO Buffer between TAP and ETH, crosses CLK domains from 125MHz needed for PHYs and 133MHz needed for SDRAM
wire [7:0]  rx0_axis_async_fifo_tdata;
wire        rx0_axis_async_fifo_tvalid;
wire        rx0_axis_async_fifo_tready;
wire        rx0_axis_async_fifo_tlast;
wire        rx0_axis_async_fifo_tuser;



// // Ethernet frame between Ethernet modules and UDP stack
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



// // IP frame connections
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



// // UDP frame connections
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



//DNS Packet Parser
wire            dns0_valid;
wire            dns0_ready;
wire [31:0]     dns0_source_ip;
wire [31:0]     dns0_dest_ip;
wire [15:0]     dns0_length;
wire [4095:0]   dns0_pkt;



//DNS Packet Analyzer
wire            parser_valid;
wire            parser_ready;
wire [15:0]     hdr_id;
wire            hdr_qr;
wire [3:0]      hdr_opcode;
wire            hdr_aa;
wire            hdr_tc;
wire            hdr_rd;
wire            hdr_ra;
wire [2:0]      hdr_z;
wire [3:0]      hdr_rcode;
wire [15:0]     hdr_qdcount;
wire [15:0]     hdr_ancount;
wire [15:0]     hdr_nscount;
wire [15:0]     hdr_arcount;
wire [31:0]     hdr_source_ip;
wire [31:0]     hdr_dest_ip;
wire [2047:0]    qry_name;
wire [15:0]     qry_type;
wire [15:0]     qry_class;
wire [2047:0]    ans_name;
wire [15:0]     ans_type;
wire [15:0]     ans_class;
wire [31:0]     ans_ttl;
wire [15:0]     ans_datalen;

wire [31:0]     ans_addr;
wire [31:0]     ans_addr_2;
wire [31:0]     ans_addr_3;
wire [31:0]     ans_addr_4;
wire [31:0]     ans_addr_5;
wire [31:0]     ans_addr_6;
wire [31:0]     ans_addr_7;
wire [31:0]     ans_addr_8;
wire [31:0]     ans_addr_9;
wire [31:0]     ans_addr_10;
wire [31:0]     ans_addr_11;
wire [31:0]     ans_addr_12;
wire [31:0]     ans_addr_13;
wire [31:0]     ans_addr_14;
wire [31:0]     ans_addr_15;
wire [31:0]     ans_addr_16;
wire [31:0]     ans_addr_17;
wire [31:0]     ans_addr_18;
wire [31:0]     ans_addr_19;
wire [31:0]     ans_addr_20;
wire [31:0]     ans_addr_21;
wire [31:0]     ans_addr_22;
wire [31:0]     ans_addr_23;
wire [31:0]     ans_addr_24;
wire [31:0]     ans_addr_25;
wire [31:0]     ans_addr_26;
wire [31:0]     ans_addr_27;
wire [31:0]     ans_addr_28;
wire [31:0]     ans_addr_29;
wire [31:0]     ans_addr_30;

wire [127:0]    a4_ans_addr;
wire [127:0]    a4_ans_addr_2;
wire [127:0]    a4_ans_addr_3;
wire [127:0]    a4_ans_addr_4;
wire [127:0]    a4_ans_addr_5;
wire [127:0]    a4_ans_addr_6;
wire [127:0]    a4_ans_addr_7;
wire [127:0]    a4_ans_addr_8;

wire [2047:0]   ans_cname_1;
wire [2047:0]   ans_cname_2;

wire [4:0]    ans_a_count;
wire [2:0]    ans_aaaa_count;
wire [1:0]    ans_cname_count;


//AXIS UART config (unused)
wire [23:0] s_axis_config_tdata;
wire        s_axis_config_tvalid;



//SDRAM CONTROLLER WISHBONE INTERFACE
wire [24:0] sdram_wb_addr_i;
wire [31:0] sdram_wb_data_i;
wire [31:0] sdram_wb_data_o;
wire        sdram_wb_we_i;
wire        sdram_wb_ack_o;
wire        sdram_wb_stb_i;
wire        sdram_wb_cyc_i;

wire [5:0] storage_state;

wire [7:0] uart_data;
wire uart_valid;
wire uart_ready;

//PHY resets
assign phy0_reset_n = ~rst;
assign phy1_reset_n = ~rst;



//ETHERNET BRIDGING (Future; Conditionally Bridge if not in SPAN mode, use phy1 for offload)
assign tx1_axis_tdata = rx0_axis_tdata;
assign tx0_axis_tdata = rx1_axis_tdata;
assign tx1_axis_tvalid = rx0_axis_tvalid;
assign rx1_axis_tready = tx0_axis_tready;
assign tx0_axis_tvalid = rx1_axis_tvalid;
assign rx0_axis_tready = tx1_axis_tready;
assign tx1_axis_tlast = rx0_axis_tlast;
assign tx0_axis_tlast = rx1_axis_tlast;



//Not sure if this is needed
assign gpio = 0;



// // ---------------------------------------------------------------------------------------------------
// //Analyzer tester (Full chain test impossible due to timing, so all systems up though DNS need to be faked with this)
// reg [4095:0] dns_sample_reg = 4096'b0, dns_sample_next; 
// reg [7:0] sample_counter_reg = 8'b0, sample_counter_next;
// reg dns_valid_reg = 1'b0, dns_valid_next;
// reg [1:0] dns_valid_reg2 = 1'b0, dns_valid_next2;

// assign dns0_pkt = dns_sample_reg;
// assign dns0_valid = dns_valid_reg;
// assign dns0_dest_ip = 32'h0a02f22c;


// always @(*) begin

//     dns_sample_next = dns_sample_reg;
//     sample_counter_next = sample_counter_reg;
//     dns_valid_next = dns_valid_reg;
// 	dns_valid_next2 = dns_valid_reg2;
    
//     case (sample_counter_reg) 

//         8'b10000000: begin
//             if (dns0_ready && dns_valid_reg2 == 2'b00) begin //
//                 dns_valid_next = 1'b1;
// 				dns_valid_next2 = dns_valid_reg2 + 1;
//                 //dns_sample_next = {496'h0a74818000010001000000000b6d61726b6574706c6163650c76697375616c73747564696f03636f6d0000010001c00c00010001000000dc00040d6b2a12,3600'b0};
//                 dns_sample_next = {1120'hef87818000010003000000000278320163056c656e6372036f72670000010001c00c000500010000005700290363726c07726f6f742d78310b6c657473656e6372797074036f726707656467656b6579036e657400c02c0005000100001445001b05653836353204647363780a616b616d616965646765036e657400c06100010001000000060004686a0632,2976'b0};
// 				sample_counter_next = sample_counter_reg + 1;
// 			end else if (dns0_ready && dns_valid_reg2 == 2'b01) begin //
//                 dns_valid_next = 1'b1;
// 				dns_valid_next2 = dns_valid_reg2 + 1;
//                 //dns_sample_next = {496'h0a74818000010001000000000b6d61726b6574706c6163650c76697375616c73747564696f03636f6d0000010001c00c00010001000000dc00040d6b2a12,3600'b0};
//                 dns_sample_next = {1440'h90d3818000010004000000000278320163056c656e6372036f726700001c0001c00c000500010000005700290363726c07726f6f742d78310b6c657473656e6372797074036f726707656467656b6579036e657400c02c0005000100001445001b05653836353204647363780a616b616d616965646765036e657400c061001c000100000006001026001402b800089000000000000021ccc061001c000100000006001026001402b800088600000000000021cc,2656'b0};
// 				sample_counter_next = sample_counter_reg + 1;
// 			end

//         end

//         default: begin
//             dns_valid_next = 1'b0;
//             dns_sample_next = 4096'b0;
// 			sample_counter_next = sample_counter_reg + 1;
			
//         end
//     endcase
    
// end

// always @(posedge clk_dram_c) begin

//     if (rst) begin

//         dns_sample_reg <= 4096'b0;
//         sample_counter_reg <= 8'b0;
//         dns_valid_reg <= 1'b0;
// 		dns_valid_reg2 <= 2'b0;

// 	end else begin

// 		dns_sample_reg <= dns_sample_next;
// 		sample_counter_reg <= sample_counter_next;
// 		dns_valid_reg <= dns_valid_next;
// 		dns_valid_reg2 <= dns_valid_next2;

// 	end

// end
// // ---------------------------------------------------------------------------------------------------


// // ---------------------------------------------------------------------------------------------------
// // HASH Tester
// reg [8:0] sample_counter_reg = 9'b0, sample_counter_next;
// reg parser_valid_reg, parser_valid_next;
// reg hash_ready_reg, hash_ready_next;
// wire hash_valid;
// wire hash_ready;
// wire [31:0] hash;

// assign parser_valid = parser_valid_reg;
// assign hash_ready = hash_ready_reg;

// always @(*) begin

//     sample_counter_next = sample_counter_reg;
//     parser_valid_next = parser_valid_reg;
//     hash_ready_next = hash_ready_reg;
    
//     case (sample_counter_reg) 

//         9'b000001000: begin

//             parser_valid_next = 1'b1;

//         end

//         9'b111111110: begin

//             hash_ready_next = 1'b1;

//         end

//         default: begin
//             parser_valid_next = 1'b0;
//             hash_ready_next = 1'b0;
//         end
//     endcase
//     sample_counter_next = sample_counter_reg + 1;
// end

// always @(posedge clk_dram_c) begin

//     if (rst) begin

//         sample_counter_reg = 9'b0;
//         parser_valid_reg = 1'b0;
//         hash_ready_reg = 1'b0;

//     end

//     sample_counter_reg <= sample_counter_next;
//     parser_valid_reg <= parser_valid_next;
//     hash_ready_reg <= hash_ready_next;

// end

// sbdm2048 hash_qname_inst (

// 	.clk(clk_dram_c),
// 	.rst(rst),
	
// 	.qname(2048'h0b6d61726b6574706c6163650c76697375616c73747564696f03636f6d00),
// 	.qname_valid(parser_valid),
// 	.qname_ready(),

// 	.hash(hash),
// 	.hash_valid(hash_valid),
// 	.hash_ready(hash_ready)

// );
// // ---------------------------------------------------------------------------------------------------

assign ledr[6:1] = storage_state;
assign ledr[17] = uart_ready;
assign ledr[16] = uart_valid; 
assign ledr[15] = dns0_ready;
assign ledr[14] = dns0_valid;
assign ledr[13] = parser_ready;
assign ledr[12] = parser_valid;

eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .USE_CLK90("TRUE"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst0 (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx0_axis_tdata),
    .tx_axis_tvalid(tx0_axis_tvalid),
    .tx_axis_tready(tx0_axis_tready),
    .tx_axis_tlast(tx0_axis_tlast),
    .tx_axis_tuser(tx0_axis_tuser),

    .rx_axis_tdata(rx0_axis_tdata),
    .rx_axis_tvalid(rx0_axis_tvalid),
    .rx_axis_tready(rx0_axis_tready),
    .rx_axis_tlast(rx0_axis_tlast),
    .rx_axis_tuser(rx0_axis_tuser),

    .rgmii_rx_clk(phy0_rx_clk),
    .rgmii_rxd(phy0_rxd),
    .rgmii_rx_ctl(phy0_rx_ctl),
    .rgmii_tx_clk(phy0_tx_clk),
    .rgmii_txd(phy0_txd),
    .rgmii_tx_ctl(phy0_tx_ctl),
    
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),

    .ifg_delay(12)
);

eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .USE_CLK90("TRUE"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst1 (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx1_axis_tdata),
    .tx_axis_tvalid(tx1_axis_tvalid),
    .tx_axis_tready(tx1_axis_tready),
    .tx_axis_tlast(tx1_axis_tlast),
    .tx_axis_tuser(tx1_axis_tuser),

    .rx_axis_tdata(rx1_axis_tdata),
    .rx_axis_tvalid(rx1_axis_tvalid),
    .rx_axis_tready(rx1_axis_tready),
    .rx_axis_tlast(rx1_axis_tlast),
    .rx_axis_tuser(rx1_axis_tuser),

    .rgmii_rx_clk(phy1_rx_clk),
    .rgmii_rxd(phy1_rxd),
    .rgmii_rx_ctl(phy1_rx_ctl),
    .rgmii_tx_clk(phy1_tx_clk),
    .rgmii_txd(phy1_txd),
    .rgmii_tx_ctl(phy1_tx_ctl),
    
    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),

    .ifg_delay(12)
);



axis_tap
axis_tap0 (

    .clk(clk),
    .rst(rst),
    .tap_axis_tdata(rx0_axis_tdata),
    .tap_axis_tvalid(rx0_axis_tvalid),
    .tap_axis_tready(rx0_axis_tready),
    .tap_axis_tlast(rx0_axis_tlast),
    .tap_axis_tuser(rx0_axis_tuser),

    .m_axis_tdata(rx0_axis_tap_tdata),
    .m_axis_tvalid(rx0_axis_tap_tvalid),
    .m_axis_tready(rx0_axis_tap_tready),
    .m_axis_tlast(rx0_axis_tap_tlast),
    .m_axis_tuser(rx0_axis_tap_tuser)
);



axis_async_fifo
axis_async_fifo_inst
(
	.s_clk(clk),	
	.s_rst(rst),	
	.s_axis_tdata(rx0_axis_tap_tdata),		
	.s_axis_tvalid(rx0_axis_tap_tvalid),	
	.s_axis_tready(rx0_axis_tap_tready),	
	.s_axis_tlast(rx0_axis_tap_tlast),		
	.s_axis_tuser(rx0_axis_tap_tuser),	

	.m_clk(clk_dram_c),	
	.m_rst(rst),	
	.m_axis_tdata(rx0_axis_async_fifo_tdata),	
	.m_axis_tvalid(rx0_axis_async_fifo_tvalid),	
	.m_axis_tready(rx0_axis_async_fifo_tready),	
	.m_axis_tlast(rx0_axis_async_fifo_tlast),		
	.m_axis_tuser(rx0_axis_async_fifo_tuser),	

	.s_status_overflow(ledr[0]),	
	.s_status_bad_frame(),	
	.s_status_good_frame(),	
	.m_status_overflow(),	
	.m_status_bad_frame(),	
	.m_status_good_frame()
);



eth_axis_rx
eth_axis_rx0_inst (
    .clk(clk_dram_c),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx0_axis_async_fifo_tdata),
    .s_axis_tvalid(rx0_axis_async_fifo_tvalid),
    .s_axis_tready(rx0_axis_async_fifo_tready),
    .s_axis_tlast(rx0_axis_async_fifo_tlast),
    .s_axis_tuser(rx0_axis_async_fifo_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx0_eth_hdr_valid),
    .m_eth_hdr_ready(rx0_eth_hdr_ready),
    .m_eth_dest_mac(rx0_eth_dest_mac),
    .m_eth_src_mac(rx0_eth_src_mac),
    .m_eth_type(rx0_eth_type),
    .m_eth_payload_axis_tdata(rx0_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(rx0_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx0_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx0_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx0_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);



ip_eth_rx
ip0_eth_rx_inst (
    .clk(clk_dram_c),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(rx0_eth_hdr_valid),
    .s_eth_hdr_ready(rx0_eth_hdr_ready),
    .s_eth_dest_mac(rx0_eth_dest_mac),
    .s_eth_src_mac(rx0_eth_src_mac),
    .s_eth_type(rx0_eth_type),
    .s_eth_payload_axis_tdata(rx0_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(rx0_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx0_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx0_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx0_eth_payload_axis_tuser),
    // IP frame output
    .m_ip_hdr_valid(rx_ip0_hdr_valid),
    .m_ip_hdr_ready(rx_ip0_hdr_ready),
    .m_eth_dest_mac(rx_ip0_eth_dest_mac),
    .m_eth_src_mac(rx_ip0_eth_src_mac),
    .m_eth_type(rx_ip0_eth_type),
    .m_ip_version(rx_ip0_version),
    .m_ip_ihl(rx_ip0_ihl),
    .m_ip_dscp(rx_ip0_dscp),
    .m_ip_ecn(rx_ip0_ecn),
    .m_ip_length(rx_ip0_length),
    .m_ip_identification(rx_ip0_identification),
    .m_ip_flags(rx_ip0_flags),
    .m_ip_fragment_offset(rx_ip0_fragment_offset),
    .m_ip_ttl(rx_ip0_ttl),
    .m_ip_protocol(rx_ip0_protocol),
    .m_ip_header_checksum(rx_ip0_header_checksum),
    .m_ip_source_ip(rx_ip0_source_ip),
    .m_ip_dest_ip(rx_ip0_dest_ip),
    .m_ip_payload_axis_tdata(rx_ip0_payload_axis_tdata),
    .m_ip_payload_axis_tvalid(rx_ip0_payload_axis_tvalid),
    .m_ip_payload_axis_tready(rx_ip0_payload_axis_tready),
    .m_ip_payload_axis_tlast(rx_ip0_payload_axis_tlast),
    .m_ip_payload_axis_tuser(rx_ip0_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination(),
    .error_payload_early_termination(),
    .error_invalid_header(),
    .error_invalid_checksum()
);



udp_ip_rx
udp0_ip_rx_inst (
    .clk(clk_dram_c),
    .rst(rst),
    // IP frame input
    .s_ip_hdr_valid(rx_ip0_hdr_valid),
    .s_ip_hdr_ready(rx_ip0_hdr_ready),
    .s_eth_dest_mac(rx_ip0_eth_dest_mac),
    .s_eth_src_mac(rx_ip0_eth_src_mac),
    .s_eth_type(rx_ip0_eth_type),
    .s_ip_version(rx_ip0_version),
    .s_ip_ihl(rx_ip0_ihl),
    .s_ip_dscp(rx_ip0_dscp),
    .s_ip_ecn(rx_ip0_ecn),
    .s_ip_length(rx_ip0_length),
    .s_ip_identification(rx_ip0_identification),
    .s_ip_flags(rx_ip0_flags),
    .s_ip_fragment_offset(rx_ip0_fragment_offset),
    .s_ip_ttl(rx_ip0_ttl),
    .s_ip_protocol(rx_ip0_protocol),
    .s_ip_header_checksum(rx_ip0_header_checksum),
    .s_ip_source_ip(rx_ip0_source_ip),
    .s_ip_dest_ip(rx_ip0_dest_ip),
    .s_ip_payload_axis_tdata(rx_ip0_payload_axis_tdata),
    .s_ip_payload_axis_tvalid(rx_ip0_payload_axis_tvalid),
    .s_ip_payload_axis_tready(rx_ip0_payload_axis_tready),
    .s_ip_payload_axis_tlast(rx_ip0_payload_axis_tlast),
    .s_ip_payload_axis_tuser(rx_ip0_payload_axis_tuser),
    // UDP frame output
    .m_udp_hdr_valid(rx_udp0_hdr_valid),
    .m_udp_hdr_ready(rx_udp0_hdr_ready),
    .m_eth_dest_mac(rx_udp0_eth_dest_mac),
    .m_eth_src_mac(rx_udp0_eth_src_mac),
    .m_eth_type(rx_udp0_eth_type),
    .m_ip_version(rx_udp0_ip_version),
    .m_ip_ihl(rx_udp0_ip_ihl),
    .m_ip_dscp(rx_udp0_ip_dscp),
    .m_ip_ecn(rx_udp0_ip_ecn),
    .m_ip_length(rx_udp0_ip_length),
    .m_ip_identification(rx_udp0_ip_identification),
    .m_ip_flags(rx_udp0_ip_flags),
    .m_ip_fragment_offset(rx_udp0_ip_fragment_offset),
    .m_ip_ttl(rx_udp0_ip_ttl),
    .m_ip_protocol(rx_udp0_ip_protocol),
    .m_ip_header_checksum(rx_udp0_ip_header_checksum),
    .m_ip_source_ip(rx_udp0_ip_source_ip), //Needed
    .m_ip_dest_ip(rx_udp0_ip_dest_ip),
    .m_udp_source_port(rx_udp0_source_port),
    .m_udp_dest_port(rx_udp0_dest_port), //Needs to be 53
    .m_udp_length(rx_udp0_length), //Maybe
    .m_udp_checksum(rx_udp0_checksum),
    .m_udp_payload_axis_tdata(rx_udp0_payload_axis_tdata),
    .m_udp_payload_axis_tvalid(rx_udp0_payload_axis_tvalid),
    .m_udp_payload_axis_tready(rx_udp0_payload_axis_tready),
    .m_udp_payload_axis_tlast(rx_udp0_payload_axis_tlast),
    .m_udp_payload_axis_tuser(rx_udp0_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination(),
    .error_payload_early_termination()
);



dns_ip_rx 
dns0_ip_rx_inst
(
	.clk(clk_dram_c),	
	.rst(rst),	
	.s_udp_hdr_valid(rx_udp0_hdr_valid),	
	.s_udp_hdr_ready(rx_udp0_hdr_ready),
	.s_udp_source_port(rx_udp0_source_port),	
	.s_udp_dest_port(rx_udp0_dest_port),	
	.s_udp_source_ip(rx_udp0_ip_source_ip),	
	.s_udp_dest_ip(rx_udp0_ip_dest_ip),	
	.s_udp_length(rx_udp0_length),	
	.s_udp_payload_axis_tdata(rx_udp0_payload_axis_tdata),	
	.s_udp_payload_axis_tvalid(rx_udp0_payload_axis_tvalid),	
	.s_udp_payload_axis_tready(rx_udp0_payload_axis_tready),	
	.s_udp_payload_axis_tlast(rx_udp0_payload_axis_tlast),	
	.s_udp_payload_axis_tuser(rx_udp0_payload_axis_tuser),	
    //DNS Outputs
	.m_dns_valid(dns0_valid),	
	.m_dns_ready(dns0_ready),	
	.m_udp_src_ip(dns0_source_ip),	
	.m_udp_dst_ip(dns0_dest_ip),	
	.m_udp_length(dns0_length),	
	.m_dns_pkt(dns0_pkt)
);



axis_uart_v1_0
axis_uart (

    .aclk(clk_dram_c),
    .aresetn(!rst),
    .s_axis_config_tdata(),
    .s_axis_config_tvalid(),
    .s_axis_config_tready(),

    .s_axis_tdata(uart_data),
    .s_axis_tvalid(uart_valid),
    .s_axis_tready(uart_ready),

    .m_axis_tdata(),
    .m_axis_tuser(),
    .m_axis_tvalid(),
    .m_axis_tready(),

    .tx(uart_tx),
    .rx(),
    .rts(),
    .cts()
);



analyzer 
analyzer_inst
(
	.rst(rst),	
	.clk(clk_dram_c),

    .source_ip_i(dns0_source_ip),
    .dest_ip_i(dns0_dest_ip),

	.pkt(dns0_pkt),	
	.pkt_valid(dns0_valid),	
	.pkt_ready(dns0_ready), 	

    .parser_valid(parser_valid),
    .parser_ready(parser_ready),

    .hdr_id(hdr_id),	
	.hdr_qr(hdr_qr),	
	.hdr_opcode(hdr_opcode),	
	.hdr_aa(hdr_aa),	
	.hdr_tc(hdr_tc),	
	.hdr_rd(hdr_rd),	
	.hdr_ra(hdr_ra),	
	.hdr_z(hdr_z),	
	.hdr_rcode(hdr_rcode),	
	.hdr_qdcount(hdr_qdcount),	
	.hdr_ancount(hdr_ancount),	
	.hdr_nscount(hdr_nscount),	
	.hdr_arcount(hdr_arcount),	

    .source_ip_o(hdr_source_ip),
    .dest_ip_o(hdr_dest_ip),

	.qry_name(qry_name),	
	.qry_type(qry_type),	
	.qry_class(qry_class),
	
	.ans_type(ans_type),	
	.ans_class(ans_class),	
	.ans_ttl(ans_ttl),	
	.ans_datalen(ans_datalen),	
	.ans_addr(ans_addr),
    .ans_addr_2(ans_addr_2),
	.ans_addr_3(ans_addr_3),
	.ans_addr_4(ans_addr_4),
	.ans_addr_5(ans_addr_5),
	.ans_addr_6(ans_addr_6),
	.ans_addr_7(ans_addr_7),
	.ans_addr_8(ans_addr_8),
	.ans_addr_9(ans_addr_9),
	.ans_addr_10(ans_addr_10),
	.ans_addr_11(ans_addr_11) ,
	.ans_addr_12(ans_addr_12),
	.ans_addr_13(ans_addr_13),
	.ans_addr_14(ans_addr_14),
	.ans_addr_15(ans_addr_15),
	.ans_addr_16(ans_addr_16),
	.ans_addr_17(ans_addr_17),
	.ans_addr_18(ans_addr_18),
	.ans_addr_19(ans_addr_19),
	.ans_addr_20(ans_addr_20),
	.ans_addr_21(ans_addr_21),
	.ans_addr_22(ans_addr_22),
	.ans_addr_23(ans_addr_23),
	.ans_addr_24(ans_addr_24),
	.ans_addr_25(ans_addr_25),
	.ans_addr_26(ans_addr_26),
	.ans_addr_27(ans_addr_27),
	.ans_addr_28(ans_addr_28),
	.ans_addr_29(ans_addr_29),
	.ans_addr_30(ans_addr_30),
	.a4_ans_addr(a4_ans_addr),
	.a4_ans_addr_2(a4_ans_addr_2),
	.a4_ans_addr_3(a4_ans_addr_3),
	.a4_ans_addr_4(a4_ans_addr_4),
	.a4_ans_addr_5(a4_ans_addr_5),
	.a4_ans_addr_6(a4_ans_addr_6),
	.a4_ans_addr_7(a4_ans_addr_7),
	.a4_ans_addr_8(a4_ans_addr_8),
	.cname_ans_cname(ans_cname_1),
	.cname_ans_cname_2(ans_cname_2) , 	

    .ans_a_count(ans_a_count),
    .ans_aaaa_count(ans_aaaa_count),
    .cname_count(ans_cname_count)
);

storage storage_inst
(
	.clk(clk_dram_c),
	.rst(rst),

	.state(storage_state),

	.parser_valid(parser_valid),
	.parser_ready(parser_ready),

	.hdr_id(hdr_id) ,
	.hdr_qr(hdr_qr),
	.hdr_opcode(hdr_opcode),
	.hdr_aa(hdr_aa),
	.hdr_tc(hdr_tc),
	.hdr_rd(hdr_rd),
	.hdr_ra(hdr_ra),
	.hdr_z(hdr_z),
	.hdr_rcode(hdr_rcode),
	.hdr_qdcount(hdr_qdcount),
	.hdr_ancount(hdr_ancount),
	.hdr_nscount(hdr_nscount),
	.hdr_arcount(hdr_arcount),
	.hdr_source_ip(hdr_source_ip),
	.hdr_dest_ip(hdr_dest_ip),

	.qry_name(qry_name),
	.qry_type(qry_type),
	.qry_class(qry_class),

	.ans_type(ans_type),
	.ans_class(ans_class) ,
	.ans_ttl(ans_ttl),
	.ans_datalen(ans_datalen),

	.ans_addr(ans_addr),
	.ans_addr_2(ans_addr_2),
	.ans_addr_3(ans_addr_3),
	.ans_addr_4(ans_addr_4),
	.ans_addr_5(ans_addr_5),
	.ans_addr_6(ans_addr_6),
	.ans_addr_7(ans_addr_7),
	.ans_addr_8(ans_addr_8),
	.ans_addr_9(ans_addr_9),
	.ans_addr_10(ans_addr_10),
	.ans_addr_11(ans_addr_11) ,
	.ans_addr_12(ans_addr_12),
	.ans_addr_13(ans_addr_13),
	.ans_addr_14(ans_addr_14),
	.ans_addr_15(ans_addr_15),
	.ans_addr_16(ans_addr_16),
	.ans_addr_17(ans_addr_17),
	.ans_addr_18(ans_addr_18),
	.ans_addr_19(ans_addr_19),
	.ans_addr_20(ans_addr_20),
	.ans_addr_21(ans_addr_21),
	.ans_addr_22(ans_addr_22),
	.ans_addr_23(ans_addr_23),
	.ans_addr_24(ans_addr_24),
	.ans_addr_25(ans_addr_25),
	.ans_addr_26(ans_addr_26),
	.ans_addr_27(ans_addr_27),
	.ans_addr_28(ans_addr_28),
	.ans_addr_29(ans_addr_29),
	.ans_addr_30(ans_addr_30),

	.a4_ans_addr(a4_ans_addr),
	.a4_ans_addr_2(a4_ans_addr_2),
	.a4_ans_addr_3(a4_ans_addr_3),
	.a4_ans_addr_4(a4_ans_addr_4),
	.a4_ans_addr_5(a4_ans_addr_5),
	.a4_ans_addr_6(a4_ans_addr_6),
	.a4_ans_addr_7(a4_ans_addr_7),
	.a4_ans_addr_8(a4_ans_addr_8),

	.ans_cname_1(ans_cname_1),
	.ans_cname_2(ans_cname_2),

	.ans_a_count(ans_a_count),
	.ans_aaaa_count(ans_aaaa_count),
	.ans_cname_count(ans_cname_count),

	.wb_addr_o(sdram_wb_addr_i),
	.wb_data_o(sdram_wb_data_i),
	.wb_data_i(sdram_wb_data_o),
	.wb_we_o(sdram_wb_we_i),
	.wb_ack_i(sdram_wb_ack_o),
	.wb_stb_o(sdram_wb_stb_i),
	.wb_cyc_o(sdram_wb_cyc_i),

	.uart_data(uart_data),
	.uart_valid(uart_valid),
	.uart_ready(uart_ready)
);

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

    .addr_i(sdram_wb_addr_i),
    .dat_i(sdram_wb_data_i),
    .dat_o(sdram_wb_data_o),
    .we_i(sdram_wb_we_i),
    .ack_o(sdram_wb_ack_o),
    .stb_i(sdram_wb_stb_i),
    .cyc_i(sdram_wb_cyc_i)
);





endmodule

`resetall
