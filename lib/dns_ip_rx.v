// Language: Verilog 2001

/*
 * UDP ethernet frame receiver (UDP Frame in, DNS Data out to RAM)
 */
module dns_ip_rx
(
    input  wire        clk,
    input  wire        rst,

    /*
     * UDP frame input
     */
    input  wire        s_udp_hdr_valid,
    output wire        s_udp_hdr_ready,
    input wire [15:0]  s_udp_source_port,
    input wire [15:0]  s_udp_dest_port,
    input  wire [31:0] s_udp_source_ip,
    input  wire [31:0] s_udp_dest_ip,
    input wire [15:0]  s_udp_length,
    input  wire [7:0]  s_udp_payload_axis_tdata,
    input  wire        s_udp_payload_axis_tvalid,
    output wire        s_udp_payload_axis_tready,
    input  wire        s_udp_payload_axis_tlast,
    input  wire        s_udp_payload_axis_tuser,

    /*
     * Memoy Output
     */
    // output wire [22:0] addr_i,
    // input wire [31:0] dat_i,
    // output wire [31:0] dat_o,
    // output wire we_i,
    // input wire ack_o,
    // output wire stb_i,
    // output wire cyc_i

    output wire [31:0]  m_udp_src_ip,
    output wire [31:0]  m_udp_dst_ip,
    output wire [2047:0]m_dns_name,
    output wire [31:0]  m_dns_qhost,
    output wire [959:0] m_dns_rhosts,
    output wire [4:0]   m_dns_rhost_count,
    output wire [15:0]  m_dns_flags,
    output wire [15:0]  m_dns_answer_rrs,
    output wire [2047:0]m_dns_cname1,
    output wire         m_dns_cname_count,
    output wire [7:0]   m_dns_axis_tdata,
    output wire         m_dns_axis_tvalid,
    input  wire         m_dns_axis_tready,
    output wire         m_dns_axis_tlast,
    output wire         m_dns_axis_tuser


);

// states
localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_READ_PKT = 3'd1,
    STATE_READ_LAST = 3'd2,
    STATE_ANALYZE = 3'd3;

reg [2:0] state_reg = STATE_IDLE, state_next;
reg []

reg [4095:0] dns_data = 4096'b0;
// udp hdr ready signals
reg s_udp_hdr_ready_reg = 1'b0, s_udp_hdr_ready_next;

reg store_udp_hdr;
// dns hdr valid
reg m_dns_hdr_valid;
reg m_dns_hdr_valid_reg = 1'b0, m_dns_hdr_valid_next;

reg [15:0] s_udp_length_reg = 16'd0;

reg [11:0] data_count_reg = 12'b0;
reg [11:0] data_count_next = 12'b0;
// combinational logic
always @* begin
    // default values
    state_next = STATE_IDLE;

    hdr_ptr_next = hdr_ptr_reg; 
    data_count_next = data_count_reg;


    case (state_reg)
        STATE_IDLE: begin
            // wait for header
            data_count_next = 12'b0;
            dns_data = 4096'b0;
            s_dns_hdr_ready_next = !m_dns_hdr_valid_next;

            if (s_udp_hdr_ready && s_udp_hdr_valid) begin
                s_ip_hdr_ready_next = 1'b0;
                s_ip_payload_axis_tready_next = 1'b1;
                store_udp_hdr = 1'b1;
                state_next = STATE_READ_PKT;
            end else begin
                state_next = STATE_IDLE;

            end
        end

        STATE_READ_PKT: begin
            s_ip_payload_axis_tready_next = 1'b1;
            data_count_next = data_count_reg + 8'h8;
        end

        STATE_READ_LAST: begin
            
        end

        STATE_ANALYZE : begin

        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        s_udp_hdr_ready_reg <= 1'b0;
        s_udp_payload_axis_tready_reg <= 1'b0;
        error_early_termination_reg <= 1'b0;
    end else begin
        state_reg <= state_next;


        s_udp_hdr_ready_reg <= s_udp_hdr_ready_next;
        s_udp_payload_axis_tready_reg <= s_udp_payload_axis_tready_next;

        error_early_termination_reg <= error_early_termination_next;

    end

    dns_data [4095-data_count_reg:4087-data_count_reg] <= s_udp_payload_axis_tdata;
    data_count_reg <= data_count_next;

    if (store_udp_hdr) begin
        m_ip_length_reg <= s_udp_length;
        m_ip_source_ip_reg <= s_udp_source_ip;
        m_ip_dest_ip_reg <= s_udp_dest_ip;

    end
end

endmodule

`resetall
