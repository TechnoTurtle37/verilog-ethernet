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
    input  wire [15:0] s_udp_source_port,
    input  wire [15:0] s_udp_dest_port,
    input  wire [31:0] s_udp_source_ip,
    input  wire [31:0] s_udp_dest_ip,
    input  wire [15:0] s_udp_length,
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
    output wire         m_dns_valid,
    input wire          m_dns_ready,
    output wire [31:0]  m_udp_src_ip,
    output wire [31:0]  m_udp_dst_ip,
    output wire [15:0]  m_udp_length,
    output wire [4095:0]m_dns_pkt
    // output wire [7:0]   m_dns_axis_tdata,
    // output wire         m_dns_axis_tvalid,
    // input  wire         m_dns_axis_tready,
    // output wire         m_dns_axis_tlast,
    // output wire         m_dns_axis_tuser


);

// states
localparam [2:0]
    STATE_IDLE = 3'd0,
    STATE_READ_PKT = 3'd1,
    STATE_READ_LAST = 3'd2;

reg [2:0]  state_reg = STATE_IDLE, state_next;

reg [15:0] m_source_port_reg = 16'b0; 
reg [15:0] m_dest_port_reg = 16'b0; 
reg [31:0] m_source_ip_reg = 32'b0; 
reg [31:0] m_dest_ip_reg = 32'b0; 
reg [15:0] m_length_reg = 16'b0; 
//reg [7:0]  m_axis_tdata_reg = 8'b0; 

reg [4095:0] dns_data_reg = 4096'b0;

reg error_early_termination_reg = 1'b0, error_early_termination_next;
// udp hdr ready signals
reg s_udp_hdr_ready_reg = 1'b0, s_udp_hdr_ready_next;
reg s_udp_payload_axis_tready_reg = 1'b0, s_udp_payload_axis_tready_next;
reg store_udp_hdr;
// dns valid
reg m_dns_valid_reg = 1'b0, m_dns_valid_next;

reg [15:0] end_length_reg = 16'b0;
reg [15:0] data_count_reg = 14'b0;
reg [15:0] data_count_next = 14'b0;

assign s_udp_payload_axis_tready = s_udp_payload_axis_tready_reg;
assign m_udp_src_ip = m_source_ip_reg;
assign m_udp_dst_ip = m_dest_ip_reg;
assign m_udp_length = m_length_reg;
assign m_dns_pkt = dns_data_reg << 8;
assign s_udp_hdr_ready = s_udp_hdr_ready_reg;
assign m_dns_valid = m_dns_valid_reg;
// combinational logic
always @* begin
    // default values
    state_next = STATE_IDLE;

    s_udp_hdr_ready_next = 1'b0;
    s_udp_payload_axis_tready_next = 1'b0;
    
    store_udp_hdr = 1'b0;
    data_count_next = data_count_reg;
    m_dns_valid_next = m_dns_valid_reg && !m_dns_ready;
    error_early_termination_next = 1'b0;

    case (state_reg)
        STATE_IDLE: begin
            // wait for header
            data_count_next = 14'h8;
            
            s_udp_hdr_ready_next = !m_dns_valid_next;
            
            if (s_udp_hdr_ready && s_udp_hdr_valid) begin
                s_udp_hdr_ready_next = 1'b0;
                s_udp_payload_axis_tready_next = 1'b1;
                store_udp_hdr = 1'b1;
                state_next = STATE_READ_PKT;
            end else begin
                state_next = STATE_IDLE;
            end
        end

        STATE_READ_PKT: begin
            s_udp_payload_axis_tready_next = 1'b1;
            if (s_udp_payload_axis_tready && s_udp_payload_axis_tvalid) begin
                data_count_next = data_count_reg + 8'h8;

                if (s_udp_payload_axis_tlast) begin
                    error_early_termination_next = 1'b1;
                    state_next = STATE_IDLE;
                    m_dns_valid_next = 1'b0;
                end else begin

                    if ( data_count_reg == end_length_reg ) begin
                        state_next = STATE_READ_LAST;
                    end else begin
                        state_next = STATE_READ_PKT;
                    end

                end
            end else begin
                state_next = STATE_READ_PKT;
            end
        end

        STATE_READ_LAST: begin
            s_udp_payload_axis_tready_next = 1'b0;
            if (s_udp_payload_axis_tready && s_udp_payload_axis_tvalid) begin
                if (s_udp_payload_axis_tlast) begin
                    s_udp_hdr_ready_next = !m_dns_valid_next;
                    s_udp_payload_axis_tready_next = 1'b0;
                    m_dns_valid_next = (m_dest_port_reg == 16'h35) || (m_source_port_reg == 16'h35);
                    state_next = STATE_IDLE;
                end else begin
                    state_next = STATE_READ_LAST;
                end
            end
        end

    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        s_udp_hdr_ready_reg <= 1'b0;
        s_udp_payload_axis_tready_reg <= 1'b0;
        m_dns_valid_reg <= 1'b0;
        error_early_termination_reg <= 1'b0;
        dns_data_reg = 4096'b0;
    end else begin
        state_reg <= state_next;

        s_udp_hdr_ready_reg <= s_udp_hdr_ready_next;
        s_udp_payload_axis_tready_reg <= s_udp_payload_axis_tready_next;

        m_dns_valid_reg <= m_dns_valid_next;
        end_length_reg <= ( m_length_reg - 16'h9 ) << 3;
        error_early_termination_reg <= error_early_termination_next;
        data_count_reg <= data_count_next;
    end
    if (state_reg == STATE_IDLE) begin
        dns_data_reg = 4096'b0;
    end else begin
        dns_data_reg [(4095-data_count_reg) -:8] <= s_udp_payload_axis_tdata;
        
    end

    if (store_udp_hdr) begin
        m_length_reg <= s_udp_length;
        m_source_ip_reg <= s_udp_source_ip;
        m_dest_ip_reg <= s_udp_dest_ip;
        m_source_port_reg <= s_udp_source_port;
        m_dest_port_reg <= s_udp_dest_port;
        m_length_reg <= s_udp_length;

    end
end

endmodule

`resetall
