// DNS traffic analyzer
module analyzer(
    input  wire rst,
    input  wire clk,
    input  wire [31:0] source_ip_i,
    input  wire [31:0] dest_ip_i,
    input  wire [4095:0] pkt,
    input  wire pkt_valid,
    output wire pkt_ready,

    output wire parser_valid,
    input  wire parser_ready,

    output wire [15:0] hdr_id,
    output wire hdr_qr,
    output wire [3:0] hdr_opcode,
    output wire hdr_aa,
    output wire hdr_tc,
    output wire hdr_rd,
    output wire hdr_ra,
    output wire [2:0] hdr_z,
    output wire [3:0] hdr_rcode,
    output wire [15:0] hdr_qdcount,
    output wire [15:0] hdr_ancount,
    output wire [15:0] hdr_nscount,
    output wire [15:0] hdr_arcount,
    output wire [31:0] source_ip_o,
    output wire [31:0] dest_ip_o,

    // Query output wireisters,
    output wire [2047:0] qry_name,
    output wire [15:0]  qry_type,
    output wire [15:0]  qry_class,

    // A Answer output wireisters,
    output wire [15:0]  ans_type,
    output wire [15:0]  ans_class,
    output wire [31:0]  ans_ttl,
    output wire [15:0]  ans_datalen,
    output wire [31:0]  ans_addr,
    output wire [31:0]  ans_addr_2,
    output wire [31:0]  ans_addr_3,
    output wire [31:0]  ans_addr_4,
    output wire [31:0]  ans_addr_5,
    output wire [31:0]  ans_addr_6,
    output wire [31:0]  ans_addr_7,
    output wire [31:0]  ans_addr_8,
    output wire [31:0]  ans_addr_9,
    output wire [31:0]  ans_addr_10,
    output wire [31:0]  ans_addr_11,
    output wire [31:0]  ans_addr_12,
    output wire [31:0]  ans_addr_13,
    output wire [31:0]  ans_addr_14,
    output wire [31:0]  ans_addr_15,
    output wire [31:0]  ans_addr_16,
    output wire [31:0]  ans_addr_17,
    output wire [31:0]  ans_addr_18,
    output wire [31:0]  ans_addr_19,
    output wire [31:0]  ans_addr_20,
    output wire [31:0]  ans_addr_21,
    output wire [31:0]  ans_addr_22,
    output wire [31:0]  ans_addr_23,
    output wire [31:0]  ans_addr_24,
    output wire [31:0]  ans_addr_25,
    output wire [31:0]  ans_addr_26,
    output wire [31:0]  ans_addr_27,
    output wire [31:0]  ans_addr_28,
    output wire [31:0]  ans_addr_29,
    output wire [31:0]  ans_addr_30,
    output wire [4:0]   ans_a_count,

    // AAAA Answer output wireisters,
    output wire [15:0]   a4_ans_type,
    output wire [15:0]   a4_ans_class,
    output wire [31:0]   a4_ans_ttl,
    output wire [15:0]   a4_ans_datalen,
    output wire [127:0]  a4_ans_addr,
    output wire [127:0]   a4_ans_addr_2,
    output wire [127:0]   a4_ans_addr_3,
    output wire [127:0]   a4_ans_addr_4,
    output wire [127:0]   a4_ans_addr_5,
    output wire [127:0]   a4_ans_addr_6,
    output wire [127:0]   a4_ans_addr_7,
    output wire [127:0]   a4_ans_addr_8,
    
    output wire [2:0]   ans_aaaa_count,

    // CNAME Answer output wireisters
    output wire [2047:0] cname_ans_cname,
    output wire [15:0]   cname_ans_type,
    output wire [15:0]   cname_ans_class,
    output wire [31:0]   cname_ans_ttl,
    output wire [15:0]   cname_ans_datalen,

    output wire [2047:0] cname_ans_cname_2,
    output wire [15:0]   cname_ans_type_2,
    output wire [15:0]   cname_ans_class_2,
    output wire [31:0]   cname_ans_ttl_2,
    output wire [15:0]   cname_ans_datalen_2,
    output wire [1:0] cname_count
);
    
// States
localparam [5:0]
    STATE_IDLE = 5'd0,
    STATE_RD_QUESTION_NAME = 5'd1,
    STATE_RD_QUESTION_NAME_SHIFT = 5'd2,
    STATE_RD_QUESTION_TYPE = 5'd3,
    STATE_RD_QUESTION_CLASS = 5'd4,
    STATE_RD_ANSWER = 5'd5,
    STATE_RD_ANSWER_NAME = 5'd6,
    STATE_RD_ANSWER_NAME_SHIFT = 5'd7,
    STATE_RD_ANSWER_TYPE = 5'd8,
    STATE_RD_ANSWER_A = 5'd9,
    STATE_RD_ANSWER_AAAA = 5'd10,
    STATE_RD_HDR = 5'd11,
    STATE_RD_ANSWER_CNAME = 5'd12,
    STATE_RD_ANSWER_CNAME_NAME = 5'd13,
    STATE_RD_ANSWER_CNAME_SHIFT = 5'd14;

localparam hdr_size = 96; // bits
localparam pkt_size = 4096; // bits
localparam type_size = 16; // bits
localparam class_size = 16; // bits
localparam a_fixed_data_size = 96; // bits
localparam aaaa_fixed_data_size = 192; // bits
localparam cname_fixed_data_size = 64; // bits

reg [5:0] state_reg = STATE_IDLE, state_next;
reg [4095:0] pkt_reg, pkt_next;

reg pkt_ready_reg, pkt_ready_next;
reg pkt_valid_reg, pkt_valid_next;
reg parser_valid_reg = 1'b0, parser_valid_next;

// Header registers
reg [15:0] hdr_id_reg, hdr_id_next;
reg hdr_qr_reg, hdr_qr_next;
reg [3:0] hdr_opcode_reg, hdr_opcode_next;
reg hdr_aa_reg, hdr_aa_next;
reg hdr_tc_reg, hdr_tc_next;
reg hdr_rd_reg, hdr_rd_next;
reg hdr_ra_reg, hdr_ra_next;
reg [2:0] hdr_z_reg, hdr_z_next;
reg [3:0] hdr_rcode_reg, hdr_rcode_next;
reg [15:0] hdr_qdcount_reg, hdr_qdcount_next;
reg [15:0] hdr_ancount_reg, hdr_ancount_next;
reg [15:0] hdr_nscount_reg, hdr_nscount_next;
reg [15:0] hdr_arcount_reg, hdr_arcount_next;
reg [31:0] source_ip_reg, source_ip_next;
reg [31:0] dest_ip_reg, dest_ip_next;

// Query registers
reg [2047:0] qry_name_reg, qry_name_next;
reg [15:0] qry_type_reg, qry_type_next;
reg [15:0] qry_class_reg, qry_class_next;

// A Answer registers
reg [15:0] ans_type_reg, ans_type_next;
reg [15:0] ans_class_reg, ans_class_next;
reg [31:0] ans_ttl_reg, ans_ttl_next;
reg [15:0] ans_datalen_reg, ans_datalen_next;
reg [31:0] ans_addr_reg, ans_addr_next;
// N bytes after this for "Additional Records"

// Other Collected A Records addresses
reg [31:0] ans_addr_2_reg, ans_addr_2_next;
reg [31:0] ans_addr_3_reg, ans_addr_3_next;
reg [31:0] ans_addr_4_reg, ans_addr_4_next;
reg [31:0] ans_addr_5_reg, ans_addr_5_next;
reg [31:0] ans_addr_6_reg, ans_addr_6_next;
reg [31:0] ans_addr_7_reg, ans_addr_7_next;
reg [31:0] ans_addr_8_reg, ans_addr_8_next;
reg [31:0] ans_addr_9_reg, ans_addr_9_next;
reg [31:0] ans_addr_10_reg, ans_addr_10_next;
reg [31:0] ans_addr_11_reg, ans_addr_11_next;
reg [31:0] ans_addr_12_reg, ans_addr_12_next;
reg [31:0] ans_addr_13_reg, ans_addr_13_next;
reg [31:0] ans_addr_14_reg, ans_addr_14_next;
reg [31:0] ans_addr_15_reg, ans_addr_15_next;
reg [31:0] ans_addr_16_reg, ans_addr_16_next;
reg [31:0] ans_addr_17_reg, ans_addr_17_next;
reg [31:0] ans_addr_18_reg, ans_addr_18_next;
reg [31:0] ans_addr_19_reg, ans_addr_19_next;
reg [31:0] ans_addr_20_reg, ans_addr_20_next;
reg [31:0] ans_addr_21_reg, ans_addr_21_next;
reg [31:0] ans_addr_22_reg, ans_addr_22_next;
reg [31:0] ans_addr_23_reg, ans_addr_23_next;
reg [31:0] ans_addr_24_reg, ans_addr_24_next;
reg [31:0] ans_addr_25_reg, ans_addr_25_next;
reg [31:0] ans_addr_26_reg, ans_addr_26_next;
reg [31:0] ans_addr_27_reg, ans_addr_27_next;
reg [31:0] ans_addr_28_reg, ans_addr_28_next;
reg [31:0] ans_addr_29_reg, ans_addr_29_next;
reg [31:0] ans_addr_30_reg, ans_addr_30_next;
reg [4:0] a_record_reg, a_record_next;

// AAAA Answer registers
reg [15:0]    a4_ans_type_reg, a4_ans_type_next;
reg [15:0]    a4_ans_class_reg, a4_ans_class_next;
reg [31:0]    a4_ans_ttl_reg, a4_ans_ttl_next;
reg [15:0]    a4_ans_datalen_reg, a4_ans_datalen_next;
reg [127:0]   a4_ans_addr_reg, a4_ans_addr_next;
reg [127:0]   a4_ans_addr_2_reg, a4_ans_addr_2_next;
reg [127:0]   a4_ans_addr_3_reg, a4_ans_addr_3_next;
reg [127:0]   a4_ans_addr_4_reg, a4_ans_addr_4_next;
reg [127:0]   a4_ans_addr_5_reg, a4_ans_addr_5_next;
reg [127:0]   a4_ans_addr_6_reg, a4_ans_addr_6_next;
reg [127:0]   a4_ans_addr_7_reg, a4_ans_addr_7_next;
reg [127:0]   a4_ans_addr_8_reg, a4_ans_addr_8_next;
reg [2:0] a4_record_reg, a4_record_next;

// CNAME Answer Registers
reg [2047:0] cname_ans_cname_reg,    cname_ans_cname_next;   
reg [15:0]   cname_ans_type_reg,    cname_ans_type_next;
reg [15:0]   cname_ans_class_reg,   cname_ans_class_next;
reg [31:0]   cname_ans_ttl_reg,     cname_ans_ttl_next;
reg [15:0]   cname_ans_datalen_reg, cname_ans_datalen_next;
reg [2047:0] cname_ans_cname_2_reg,  cname_ans_cname_2_next;
reg [15:0]   cname_ans_type_2_reg,  cname_ans_type_2_next;
reg [15:0]   cname_ans_class_2_reg, cname_ans_class_2_next;
reg [31:0]   cname_ans_ttl_2_reg,   cname_ans_ttl_2_next;
reg [15:0]   cname_ans_datalen_2_reg, cname_ans_datalen_2_next;
reg [1:0]    cname_record_reg, cname_record_next;

//DATAPATH
assign hdr_id       = hdr_id_reg;
assign hdr_qr       = hdr_qr_reg;
assign hdr_opcode   = hdr_opcode_reg;
assign hdr_aa       = hdr_aa_reg;
assign hdr_tc       = hdr_tc_reg;
assign hdr_rd       = hdr_rd_reg;
assign hdr_ra       = hdr_ra_reg;
assign hdr_z        = hdr_z_reg;
assign hdr_rcode    = hdr_rcode_reg;
assign hdr_qdcount  = hdr_qdcount_reg;
assign hdr_ancount  = hdr_ancount_reg;
assign hdr_nscount  = hdr_nscount_reg;
assign hdr_arcount  = hdr_arcount_reg;
assign qry_name     = qry_name_reg;
assign qry_type     = qry_type_reg;
assign qry_class    = qry_class_reg;
assign ans_type     = ans_type_reg;
assign ans_class    = ans_class_reg;
assign ans_ttl      = ans_ttl_reg;
assign ans_datalen  = ans_datalen_reg;
assign ans_addr     = ans_addr_reg;
assign ans_addr_2   = ans_addr_2_reg;
assign ans_addr_3   = ans_addr_3_reg;
assign ans_addr_4   = ans_addr_4_reg;
assign ans_addr_5   = ans_addr_5_reg;
assign ans_addr_6   = ans_addr_6_reg;
assign ans_addr_7   = ans_addr_7_reg;
assign ans_addr_8   = ans_addr_8_reg;
assign ans_addr_9   = ans_addr_9_reg;
assign ans_addr_10  = ans_addr_10_reg;
assign ans_addr_11  = ans_addr_11_reg;
assign ans_addr_12  = ans_addr_12_reg;
assign ans_addr_13  = ans_addr_13_reg;
assign ans_addr_14  = ans_addr_14_reg;
assign ans_addr_15  = ans_addr_15_reg;
assign ans_addr_16  = ans_addr_16_reg;
assign ans_addr_17  = ans_addr_17_reg;
assign ans_addr_18  = ans_addr_18_reg;
assign ans_addr_19  = ans_addr_19_reg;
assign ans_addr_20  = ans_addr_20_reg;
assign ans_addr_21  = ans_addr_21_reg;
assign ans_addr_22  = ans_addr_22_reg;
assign ans_addr_23  = ans_addr_23_reg;
assign ans_addr_24  = ans_addr_24_reg;
assign ans_addr_25  = ans_addr_25_reg;
assign ans_addr_26  = ans_addr_26_reg;
assign ans_addr_27  = ans_addr_27_reg;
assign ans_addr_28  = ans_addr_28_reg;
assign ans_addr_29  = ans_addr_29_reg;
assign ans_addr_30  = ans_addr_30_reg;
// Keeps track of current A record index we are parsing for.
assign ans_a_count     = a_record_reg;

assign a4_ans_type      = a4_ans_type_reg;    
assign a4_ans_class     = a4_ans_class_reg;   
assign a4_ans_ttl       = a4_ans_ttl_reg;     
assign a4_ans_datalen   = a4_ans_datalen_reg; 
assign a4_ans_addr      = a4_ans_addr_reg;    
assign a4_ans_addr_2    = a4_ans_addr_2_reg;  
assign a4_ans_addr_3    = a4_ans_addr_3_reg;  
assign a4_ans_addr_4    = a4_ans_addr_4_reg;  
assign a4_ans_addr_5    = a4_ans_addr_5_reg;  
assign a4_ans_addr_6    = a4_ans_addr_6_reg;  
assign a4_ans_addr_7    = a4_ans_addr_7_reg;  
assign a4_ans_addr_8    = a4_ans_addr_8_reg;  
assign ans_aaaa_count        = a4_record_reg;

assign cname_ans_cname     = cname_ans_cname_reg;    
assign cname_ans_type      = cname_ans_type_reg;    
assign cname_ans_class     = cname_ans_class_reg;   
assign cname_ans_ttl       = cname_ans_ttl_reg;     
assign cname_ans_datalen   = cname_ans_datalen_reg; 
assign cname_ans_cname_2   = cname_ans_cname_2_reg;  
assign cname_ans_type_2    = cname_ans_type_2_reg;  
assign cname_ans_class_2   = cname_ans_class_2_reg; 
assign cname_ans_ttl_2     = cname_ans_ttl_2_reg;   
assign cname_ans_datalen_2 = cname_ans_datalen_2_reg;
assign cname_count        = cname_record_reg;

assign source_ip_o  = source_ip_reg;
assign dest_ip_o    = dest_ip_reg;

assign pkt_ready    = pkt_ready_reg;

assign parser_valid = parser_valid_reg;

always @* begin
    state_next = STATE_IDLE;

    pkt_ready_next = 1'b0;
    pkt_next = pkt_reg;

    hdr_id_next = hdr_id_reg;        
    hdr_qr_next = hdr_qr_reg;        
    hdr_opcode_next = hdr_opcode_reg;    
    hdr_aa_next = hdr_aa_reg;        
    hdr_tc_next = hdr_tc_reg;        
    hdr_rd_next = hdr_rd_reg;        
    hdr_ra_next = hdr_ra_reg;        
    hdr_z_next  = hdr_z_reg;        
    hdr_rcode_next = hdr_rcode_reg;     
    hdr_qdcount_next = hdr_qdcount_reg;
    hdr_ancount_next = hdr_ancount_reg;
    hdr_nscount_next = hdr_nscount_reg;
    hdr_arcount_next = hdr_arcount_reg;

    qry_name_next = qry_name_reg;
    qry_type_next = qry_type_reg;
    qry_class_next = qry_class_reg;

    ans_type_next = ans_type_reg;
    ans_class_next = ans_class_reg;
    ans_ttl_next = ans_ttl_reg;
    ans_datalen_next = ans_datalen_reg;
    ans_addr_next = ans_addr_reg;
    ans_addr_2_next   = ans_addr_2_reg;
    ans_addr_3_next   = ans_addr_3_reg;
    ans_addr_4_next   = ans_addr_4_reg;
    ans_addr_5_next   = ans_addr_5_reg;
    ans_addr_6_next   = ans_addr_6_reg;
    ans_addr_7_next   = ans_addr_7_reg;
    ans_addr_8_next   = ans_addr_8_reg;
    ans_addr_9_next   = ans_addr_9_reg;
    ans_addr_10_next  = ans_addr_10_reg;
    ans_addr_11_next  = ans_addr_11_reg;
    ans_addr_12_next  = ans_addr_12_reg;
    ans_addr_13_next  = ans_addr_13_reg;
    ans_addr_14_next  = ans_addr_14_reg;
    ans_addr_15_next  = ans_addr_15_reg;
    ans_addr_16_next  = ans_addr_16_reg;
    ans_addr_17_next  = ans_addr_17_reg;
    ans_addr_18_next  = ans_addr_18_reg;
    ans_addr_19_next  = ans_addr_19_reg;
    ans_addr_20_next  = ans_addr_20_reg;
    ans_addr_21_next  = ans_addr_21_reg;
    ans_addr_22_next  = ans_addr_22_reg;
    ans_addr_23_next  = ans_addr_23_reg;
    ans_addr_24_next  = ans_addr_24_reg;
    ans_addr_25_next  = ans_addr_25_reg;
    ans_addr_26_next  = ans_addr_26_reg;
    ans_addr_27_next  = ans_addr_27_reg;
    ans_addr_28_next  = ans_addr_28_reg;
    ans_addr_29_next  = ans_addr_29_reg;
    ans_addr_30_next  = ans_addr_30_reg;
    a_record_next     = a_record_reg;

    a4_ans_type_next      = a4_ans_type_reg;    
    a4_ans_class_next     = a4_ans_class_reg;   
    a4_ans_ttl_next       = a4_ans_ttl_reg;     
    a4_ans_datalen_next   = a4_ans_datalen_reg; 
    a4_ans_addr_next      = a4_ans_addr_reg;    
    a4_ans_addr_2_next    = a4_ans_addr_2_reg;  
    a4_ans_addr_3_next    = a4_ans_addr_3_reg;  
    a4_ans_addr_4_next    = a4_ans_addr_4_reg;  
    a4_ans_addr_5_next    = a4_ans_addr_5_reg;  
    a4_ans_addr_6_next    = a4_ans_addr_6_reg;  
    a4_ans_addr_7_next    = a4_ans_addr_7_reg;  
    a4_ans_addr_8_next    = a4_ans_addr_8_reg;  
    a4_record_next        = a4_record_reg;

    cname_ans_cname_next      = cname_ans_cname_reg;    
    cname_ans_type_next      = cname_ans_type_reg;    
    cname_ans_class_next     = cname_ans_class_reg;   
    cname_ans_ttl_next       = cname_ans_ttl_reg;     
    cname_ans_datalen_next   = cname_ans_datalen_reg; 
    cname_ans_cname_2_next    = cname_ans_cname_2_reg;  
    cname_ans_type_2_next    = cname_ans_type_2_reg;  
    cname_ans_class_2_next   = cname_ans_class_2_reg; 
    cname_ans_ttl_2_next     = cname_ans_ttl_2_reg;   
    cname_ans_datalen_2_next = cname_ans_datalen_2_reg;
    cname_record_next        = cname_record_reg;

    source_ip_next = source_ip_reg;
    dest_ip_next = dest_ip_reg;

    parser_valid_next = parser_valid_reg && !parser_ready;

    case(state_reg)
        STATE_IDLE: begin
            pkt_ready_next = !parser_valid_next;

            if (pkt_valid == 1'b1) begin
                a_record_next = 4'b0;
                pkt_next = pkt;
                state_next = STATE_RD_HDR;
                pkt_ready_next = 1'b0;

                hdr_id_next      <= 16'b0;
                hdr_qr_next      <= 1'b0;
                hdr_opcode_next  <= 4'b0;
                hdr_aa_next      <= 1'b0; 
                hdr_tc_next      <= 1'b0; 
                hdr_rd_next      <= 1'b0; 
                hdr_ra_next      <= 1'b0; 
                hdr_z_next       <= 3'b0; 
                hdr_rcode_next   <= 4'b0;  
                hdr_qdcount_next <= 16'b0;
                hdr_ancount_next <= 16'b0;
                hdr_nscount_next <= 16'b0;
                hdr_arcount_next <= 16'b0;
                source_ip_next   <= 32'b0;
                dest_ip_next     <= 32'b0;
                // latch in query info
                qry_name_next    <= 2048'b0;
                qry_type_next    <= 16'b0;
                qry_class_next   <= 16'b0;
                // latch in answer info
                ans_type_next    <= 16'b0;
                ans_class_next   <= 16'b0;
                ans_ttl_next     <= 32'b0;
                ans_datalen_next <= 16'b0;
                ans_addr_next    <= 32'b0;
                ans_addr_2_next  <= 32'b0;
                ans_addr_3_next  <= 32'b0;
                ans_addr_4_next  <= 32'b0;
                ans_addr_5_next  <= 32'b0;
                ans_addr_6_next  <= 32'b0;
                ans_addr_7_next  <= 32'b0;
                ans_addr_8_next  <= 32'b0;
                ans_addr_9_next  <= 32'b0;
                ans_addr_10_next <= 32'b0;
                ans_addr_11_next <= 32'b0;
                ans_addr_12_next <= 32'b0;
                ans_addr_13_next <= 32'b0;
                ans_addr_14_next <= 32'b0;
                ans_addr_15_next <= 32'b0;
                ans_addr_16_next <= 32'b0;
                ans_addr_17_next <= 32'b0;
                ans_addr_18_next <= 32'b0;
                ans_addr_19_next <= 32'b0;
                ans_addr_20_next <= 32'b0;
                ans_addr_21_next <= 32'b0;
                ans_addr_22_next <= 32'b0;
                ans_addr_23_next <= 32'b0;
                ans_addr_24_next <= 32'b0;
                ans_addr_25_next <= 32'b0;
                ans_addr_26_next <= 32'b0;
                ans_addr_27_next <= 32'b0;
                ans_addr_28_next <= 32'b0;
                ans_addr_29_next <= 32'b0;
                ans_addr_30_next <= 32'b0;
                a_record_next    <= 5'b0;
                a4_ans_type_next    <= 16'b0;
                a4_ans_class_next   <= 16'b0;
                a4_ans_ttl_next     <= 32'b0;
                a4_ans_datalen_next <= 16'b0;
                a4_ans_addr_next    <= 128'b0;
                a4_ans_addr_2_next  <= 128'b0;
                a4_ans_addr_3_next  <= 128'b0;
                a4_ans_addr_4_next  <= 128'b0;
                a4_ans_addr_5_next  <= 128'b0;
                a4_ans_addr_6_next  <= 128'b0;
                a4_ans_addr_7_next  <= 128'b0;
                a4_ans_addr_8_next  <= 128'b0;
                a4_record_next      <= 3'b0;
                cname_ans_cname_next      <=  2048'b0;  
                cname_ans_type_next      <=  16'b0;  
                cname_ans_class_next     <=  16'b0; 
                cname_ans_ttl_next       <=  32'b0;   
                cname_ans_datalen_next   <=  16'b0;
                cname_ans_cname_2_next    <=  2048'b0;
                cname_ans_type_2_next    <=  16'b0;
                cname_ans_class_2_next   <=  16'b0;
                cname_ans_ttl_2_next     <=  32'b0; 
                cname_ans_datalen_2_next <=  16'b0;
                cname_record_next        <=  2'b0;
            end
        end

        STATE_RD_HDR: begin
            pkt_ready_next = 1'b0;

            // Latch all the hdr signals at once
            {   hdr_id_next, 
                hdr_qr_next, 
                hdr_opcode_next, 
                hdr_aa_next, 
                hdr_tc_next, 
                hdr_rd_next, 
                hdr_ra_next, 
                hdr_z_next, 
                hdr_rcode_next, 
                hdr_qdcount_next, 
                hdr_ancount_next, 
                hdr_nscount_next, 
                hdr_arcount_next} = pkt_reg[pkt_size - 1 : pkt_size - hdr_size];

            source_ip_next = source_ip_i;
            dest_ip_next = dest_ip_i;
            

            pkt_next = pkt_reg << hdr_size;

            if (pkt_reg[4063:4048] > 0) begin
                state_next = STATE_RD_QUESTION_NAME;
            end else if (pkt_reg[4047:4032] > 0) begin
                state_next = STATE_RD_ANSWER;
            end else begin
                state_next = STATE_RD_QUESTION_TYPE;
            end
        end

        STATE_RD_QUESTION_NAME: begin
            // Read the queried name in byte by byte until the null terminator is found.
            if (pkt_reg[(pkt_size - 1) -: 8] == 8'b0) begin
                state_next = STATE_RD_QUESTION_TYPE;
            end else begin
                state_next = STATE_RD_QUESTION_NAME_SHIFT;
            end

            // Include null terminator in qry_name
            qry_name_next[7:0] = pkt_reg[(pkt_size - 1) -: 8];
            
            pkt_next = pkt_reg << 8; // Shift byte by byte
        end

        STATE_RD_QUESTION_NAME_SHIFT: begin
            qry_name_next = qry_name_reg << 8;

            state_next = STATE_RD_QUESTION_NAME; // Shift string's chars to the left 1 byte to make space for next character.
        end

        STATE_RD_QUESTION_TYPE: begin
            // Read in next 2 bytes (Type)
            qry_type_next = pkt_reg[pkt_size - 1: pkt_size - type_size];
            state_next = STATE_RD_QUESTION_CLASS;

            pkt_next = pkt_reg << 16;
        end

        STATE_RD_QUESTION_CLASS: begin
            // Read in next 2 bytes (Class)
            qry_class_next = pkt_reg[pkt_size - 1: pkt_size - class_size];

            // Check if answers exist in packet, if not go back and start next packet
            if (pkt_reg[4047:4032] > 0) begin
                state_next = STATE_RD_ANSWER;
            end else begin
                state_next = STATE_RD_HDR;
            end

            pkt_next = pkt_reg << 16;
        end

        STATE_RD_ANSWER: begin
            // Check if an answer is in the packet
            //if (pkt_reg[(pkt_size - 1) -: 16] == 16'hC00C) begin
            if (pkt_reg[(pkt_size - 1) -: 8] == 8'hC0) begin
            //if (hdr_ancount_reg > 16'b0) begin
                // If the next 2 bytes is "C00C", an answer exists
                state_next = STATE_RD_ANSWER_TYPE;
                pkt_next = pkt_reg << 16;
            end else begin
                // Otherwise, start over and read next packet header.
                //state_next = STATE_RD_HDR;

                state_next = STATE_IDLE;
                parser_valid_next = 1'b1;
                pkt_next = pkt_reg << a_fixed_data_size;
            end
        end

        // Same logic as STATE_RD_QUESTION_NAME
        // STATE_RD_ANSWER_NAME: begin
        //     // Read the queried name in byte by byte until the null terminator is found.
        //     if (pkt_reg[(pkt_size - 1) -: 8] == 8'b0) begin
        //         state_next = STATE_RD_ANSWER_TYPE;
        //     end else begin
        //         state_next = STATE_RD_QUESTION_NAME;
        //     end

        //     // Include null terminator in qry_name
        //     ans_name_next[7:0] = pkt_reg[(pkt_size - 1) -: 8];
            
        //     pkt_next = pkt_reg << 8; // Shift byte by byte
        // end

        // STATE_RD_ANSWER_NAME_SHIFT: begin
        //     ans_name_next = ans_name_reg << 8;

        //     state_next = STATE_RD_ANSWER_NAME;
        // end

        STATE_RD_ANSWER_TYPE: begin
            ans_type_next = pkt_reg[pkt_size - 1: pkt_size - type_size];

            // Check if type == A (1)
            if (pkt_reg[pkt_size - 1: pkt_size - type_size] == 8'h01) begin
                state_next = STATE_RD_ANSWER_A;
            end

            // Check if type == AAAA (128)
            if (pkt_reg[pkt_size - 1: pkt_size - type_size] == 8'h1c) begin
                state_next = STATE_RD_ANSWER_AAAA;
            end

            if (pkt_reg[pkt_size - 1: pkt_size - type_size] == 8'h05) begin
                state_next = STATE_RD_ANSWER_CNAME;
            end

            pkt_next = pkt_reg << type_size;
        end

        // The rest of the data is fixed, it can be read in one state
        STATE_RD_ANSWER_A: begin
                if (a_record_reg == 8'h00) begin
                { 
                    ans_class_next,
                    ans_ttl_next,
                    ans_datalen_next,
                    ans_addr_next} = pkt_reg[pkt_size - 1: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h01) begin
                    ans_addr_2_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h02) begin
                    ans_addr_3_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h03) begin
                    ans_addr_4_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h04) begin
                    ans_addr_5_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h05) begin
                    ans_addr_6_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h06) begin
                    ans_addr_7_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h07) begin
                    ans_addr_8_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h08) begin
                    ans_addr_9_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h09) begin
                    ans_addr_10_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0A) begin
                    ans_addr_11_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0B) begin
                    ans_addr_12_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0C) begin
                    ans_addr_13_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0D) begin
                    ans_addr_14_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0E) begin
                    ans_addr_15_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h0F) begin
                    ans_addr_16_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h10) begin
                    ans_addr_17_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h11) begin
                    ans_addr_18_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h12) begin
                    ans_addr_19_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h13) begin
                    ans_addr_20_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h14) begin
                    ans_addr_21_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h15) begin
                    ans_addr_22_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h16) begin
                    ans_addr_23_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h17) begin
                    ans_addr_24_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h18) begin
                    ans_addr_25_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h19) begin
                    ans_addr_26_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h1A) begin
                    ans_addr_27_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h1B) begin
                    ans_addr_28_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h1C) begin
                    ans_addr_29_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end else if (a_record_reg == 8'h1D) begin
                    ans_addr_30_next = pkt_reg[pkt_size - 65: pkt_size - a_fixed_data_size];
                end 
            a_record_next = a_record_reg + 1;
            // Return back to STATE_RD_ANSWER to check if another A record exists. If so, continue parsing.
            state_next = STATE_RD_ANSWER;
            //parser_valid_next = 1'b1;
            //pkt_ready_next = !parser_valid_next;
            pkt_next = pkt_reg << a_fixed_data_size;
        end

       
        STATE_RD_ANSWER_AAAA: begin
            if (a4_record_reg == 8'h00) begin
            {
                ans_class_next,
                ans_ttl_next,
                ans_datalen_next,
                a4_ans_addr_next} = pkt_reg[pkt_size - 1: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h01) begin
                a4_ans_addr_2_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h02) begin
                a4_ans_addr_3_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h03) begin
                a4_ans_addr_4_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h04) begin
                a4_ans_addr_5_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h05) begin
                a4_ans_addr_6_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h06) begin
                a4_ans_addr_7_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end else if (a4_record_reg == 8'h07) begin
                a4_ans_addr_8_next = pkt_reg[pkt_size - 65: pkt_size - aaaa_fixed_data_size];
            end
            a4_record_next = a4_record_reg + 1;
            state_next = STATE_RD_ANSWER;
            // parser_valid_next = 1'b1;
            // pkt_ready_next = !parser_valid_next;
            pkt_next = pkt_reg << aaaa_fixed_data_size;
        end

        STATE_RD_ANSWER_CNAME: begin
            if (cname_record_reg == 8'h00) begin
            {
                cname_ans_class_next,
                cname_ans_ttl_next,
                cname_ans_datalen_next} = pkt_reg[pkt_size - 1: pkt_size - cname_fixed_data_size];
                
            end else if (cname_record_reg == 8'h01) begin
                {
                cname_ans_class_2_next,
                cname_ans_ttl_2_next,
                cname_ans_datalen_2_next} = pkt_reg[pkt_size - 1: pkt_size - cname_fixed_data_size];
            end
            
            state_next = STATE_RD_ANSWER_CNAME_NAME;

            pkt_next = pkt_reg << cname_fixed_data_size;

        end

        STATE_RD_ANSWER_CNAME_NAME: begin
            if (pkt_reg[(pkt_size - 1) -: 8] == 8'b0) begin
                state_next = STATE_RD_ANSWER;
                cname_record_next = cname_record_reg + 1;
            end else begin
                state_next = STATE_RD_ANSWER_CNAME_SHIFT;
            end

            if (cname_record_reg == 8'h00) begin
                cname_ans_cname_next[7:0] = pkt_reg[(pkt_size - 1) -: 8];    
            end else if (cname_record_reg == 8'h01) begin
                cname_ans_cname_2_next[7:0] = pkt_reg[(pkt_size - 1) -: 8];
            end

            pkt_next = pkt_reg << 8;
        end

        STATE_RD_ANSWER_CNAME_SHIFT: begin
            if (cname_record_reg == 8'h00) begin
                cname_ans_cname_next = cname_ans_cname_reg << 8; 
            end else if (cname_record_reg == 8'h01) begin
                cname_ans_cname_2_next = cname_ans_cname_2_reg << 8; 
            end

            state_next = STATE_RD_ANSWER_CNAME_NAME;
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        pkt_reg <= 4096'b0;
        pkt_ready_reg <= 1'b0;

        hdr_id_reg      <= 16'b0;
        hdr_qr_reg      <= 1'b0;
        hdr_opcode_reg  <= 4'b0;
        hdr_aa_reg      <= 1'b0; 
        hdr_tc_reg      <= 1'b0; 
        hdr_rd_reg      <= 1'b0; 
        hdr_ra_reg      <= 1'b0; 
        hdr_z_reg       <= 3'b0; 
        hdr_rcode_reg   <= 4'b0;  
        hdr_qdcount_reg <= 16'b0;
        hdr_ancount_reg <= 16'b0;
        hdr_nscount_reg <= 16'b0;
        hdr_arcount_reg <= 16'b0;

        source_ip_reg   <= 32'b0;
        dest_ip_reg     <= 32'b0;

        // latch in query info
        qry_name_reg <= 2048'b0;
        qry_type_reg <= 16'b0;
        qry_class_reg  <= 16'b0;

        // latch in answer info
        ans_type_reg <= 16'b0;
        ans_class_reg <= 16'b0;
        ans_ttl_reg <= 32'b0;
        ans_datalen_reg <= 16'b0;
        ans_addr_reg <= 32'b0;
        ans_addr_2_reg  <= 32'b0;
        ans_addr_3_reg  <= 32'b0;
        ans_addr_4_reg  <= 32'b0;
        ans_addr_5_reg  <= 32'b0;
        ans_addr_6_reg  <= 32'b0;
        ans_addr_7_reg  <= 32'b0;
        ans_addr_8_reg  <= 32'b0;
        ans_addr_9_reg  <= 32'b0;
        ans_addr_10_reg <= 32'b0;
        ans_addr_11_reg <= 32'b0;
        ans_addr_12_reg <= 32'b0;
        ans_addr_13_reg <= 32'b0;
        ans_addr_14_reg <= 32'b0;
        ans_addr_15_reg <= 32'b0;
        ans_addr_16_reg <= 32'b0;
        ans_addr_17_reg <= 32'b0;
        ans_addr_18_reg <= 32'b0;
        ans_addr_19_reg <= 32'b0;
        ans_addr_20_reg <= 32'b0;
        ans_addr_21_reg <= 32'b0;
        ans_addr_22_reg <= 32'b0;
        ans_addr_23_reg <= 32'b0;
        ans_addr_24_reg <= 32'b0;
        ans_addr_25_reg <= 32'b0;
        ans_addr_26_reg <= 32'b0;
        ans_addr_27_reg <= 32'b0;
        ans_addr_28_reg <= 32'b0;
        ans_addr_29_reg <= 32'b0;
        ans_addr_30_reg <= 32'b0;
        a_record_reg    <= 5'b0;

        a4_ans_type_reg    <= 16'b0;
        a4_ans_class_reg   <= 16'b0;
        a4_ans_ttl_reg     <= 32'b0;
        a4_ans_datalen_reg <= 16'b0;
        a4_ans_addr_reg    <= 128'b0;
        a4_ans_addr_2_reg  <= 128'b0;
        a4_ans_addr_3_reg  <= 128'b0;
        a4_ans_addr_4_reg  <= 128'b0;
        a4_ans_addr_5_reg  <= 128'b0;
        a4_ans_addr_6_reg  <= 128'b0;
        a4_ans_addr_7_reg  <= 128'b0;
        a4_ans_addr_8_reg  <= 128'b0;
        a4_record_reg      <= 3'b0;

        cname_ans_cname_reg      <=  2048'b0;  
        cname_ans_type_reg      <=  16'b0;  
        cname_ans_class_reg     <=  16'b0; 
        cname_ans_ttl_reg       <=  32'b0;   
        cname_ans_datalen_reg   <=  16'b0;
        cname_ans_cname_2_reg    <=  2048'b0;
        cname_ans_type_2_reg    <=  16'b0;
        cname_ans_class_2_reg   <=  16'b0;
        cname_ans_ttl_2_reg     <=  32'b0; 
        cname_ans_datalen_2_reg <=  16'b0;
        cname_record_reg        <=  2'b0;

        parser_valid_reg <= 1'b0;
    end else begin
        state_reg <= state_next;
        pkt_reg <= pkt_next;
        pkt_ready_reg <= pkt_ready_next;

        // latch in header
        hdr_id_reg      <= hdr_id_next;
        hdr_qr_reg      <= hdr_qr_next;
        hdr_opcode_reg  <= hdr_opcode_next;
        hdr_aa_reg      <= hdr_aa_next; 
        hdr_tc_reg      <= hdr_tc_next; 
        hdr_rd_reg      <= hdr_rd_next; 
        hdr_ra_reg      <= hdr_ra_next; 
        hdr_z_reg       <= hdr_z_next ; 
        hdr_rcode_reg   <= hdr_rcode_next;  
        hdr_qdcount_reg <= hdr_qdcount_next;
        hdr_ancount_reg <= hdr_ancount_next;
        hdr_nscount_reg <= hdr_nscount_next;
        hdr_arcount_reg <= hdr_arcount_next;

        source_ip_reg <= source_ip_next;
        dest_ip_reg <= dest_ip_next;

        // latch in query info
        qry_name_reg <= qry_name_next;
        qry_type_reg <= qry_type_next;
        qry_class_reg  <= qry_class_next;

        // latch in answer info
        ans_type_reg <= ans_type_next;
        ans_class_reg <= ans_class_next;
        ans_ttl_reg <= ans_ttl_next;
        ans_datalen_reg <= ans_datalen_next;
        ans_addr_reg <= ans_addr_next;
        ans_addr_2_reg  <= ans_addr_2_next;
        ans_addr_3_reg  <= ans_addr_3_next;
        ans_addr_4_reg  <= ans_addr_4_next;
        ans_addr_5_reg  <= ans_addr_5_next;
        ans_addr_6_reg  <= ans_addr_6_next;
        ans_addr_7_reg  <= ans_addr_7_next;
        ans_addr_8_reg  <= ans_addr_8_next;
        ans_addr_9_reg  <= ans_addr_9_next;
        ans_addr_10_reg <= ans_addr_10_next;
        ans_addr_11_reg <= ans_addr_11_next;
        ans_addr_12_reg <= ans_addr_12_next;
        ans_addr_13_reg <= ans_addr_13_next;
        ans_addr_14_reg <= ans_addr_14_next;
        ans_addr_15_reg <= ans_addr_15_next;
        ans_addr_16_reg <= ans_addr_16_next;
        ans_addr_17_reg <= ans_addr_17_next;
        ans_addr_18_reg <= ans_addr_18_next;
        ans_addr_19_reg <= ans_addr_19_next;
        ans_addr_20_reg <= ans_addr_20_next;
        ans_addr_21_reg <= ans_addr_21_next;
        ans_addr_22_reg <= ans_addr_22_next;
        ans_addr_23_reg <= ans_addr_23_next;
        ans_addr_24_reg <= ans_addr_24_next;
        ans_addr_25_reg <= ans_addr_25_next;
        ans_addr_26_reg <= ans_addr_26_next;
        ans_addr_27_reg <= ans_addr_27_next;
        ans_addr_28_reg <= ans_addr_28_next;
        ans_addr_29_reg <= ans_addr_29_next;
        ans_addr_30_reg <= ans_addr_30_next;
        a_record_reg    <= a_record_next;
        a4_record_reg <= a4_record_next;

        a4_ans_type_reg    <= a4_ans_type_next;    
        a4_ans_class_reg   <= a4_ans_class_next;   
        a4_ans_ttl_reg     <= a4_ans_ttl_next;     
        a4_ans_datalen_reg <= a4_ans_datalen_next; 
        a4_ans_addr_reg    <= a4_ans_addr_next;    
        a4_ans_addr_2_reg  <= a4_ans_addr_2_next;  
        a4_ans_addr_3_reg  <= a4_ans_addr_3_next;  
        a4_ans_addr_4_reg  <= a4_ans_addr_4_next;  
        a4_ans_addr_5_reg  <= a4_ans_addr_5_next;  
        a4_ans_addr_6_reg  <= a4_ans_addr_6_next;  
        a4_ans_addr_7_reg  <= a4_ans_addr_7_next;  
        a4_ans_addr_8_reg  <= a4_ans_addr_8_next;  

        cname_ans_cname_reg = cname_ans_cname_next;    
        cname_ans_type_reg = cname_ans_type_next;    
        cname_ans_class_reg = cname_ans_class_next;   
        cname_ans_ttl_reg = cname_ans_ttl_next;     
        cname_ans_datalen_reg = cname_ans_datalen_next; 
        cname_ans_cname_2_reg = cname_ans_cname_2_next;  
        cname_ans_type_2_reg = cname_ans_type_2_next;  
        cname_ans_class_2_reg = cname_ans_class_2_next; 
        cname_ans_ttl_2_reg = cname_ans_ttl_2_next;   
        cname_ans_datalen_2_reg = cname_ans_datalen_2_next ;
        cname_record_reg= cname_record_next;

        parser_valid_reg <= parser_valid_next;


        if (state_reg == STATE_IDLE) begin

            

            

        end
    end
end

endmodule