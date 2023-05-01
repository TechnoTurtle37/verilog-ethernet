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
    output wire [2047:0] ans_name,
    output wire [15:0]  ans_type,
    output wire [15:0]  ans_class,
    output wire [31:0]  ans_ttl,
    output wire [15:0]  ans_datalen,
    output wire [31:0]  ans_addr



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
    STATE_RD_HDR = 5'd11;

localparam hdr_size = 96; // bits
localparam pkt_size = 4096; // bits
localparam type_size = 16; // bits
localparam class_size = 16; // bits
localparam a_fixed_data_size = 96; // bits
localparam aaaa_fixed_data_size = 192; // bits

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
reg [2047:0] ans_name_reg, ans_name_next;
reg [15:0] ans_type_reg, ans_type_next;
reg [15:0] ans_class_reg, ans_class_next;
reg [31:0] ans_ttl_reg, ans_ttl_next;
reg [15:0] ans_datalen_reg, ans_datalen_next;
reg [31:0] ans_addr_reg, ans_addr_next;
// N bytes after this for "Additional Records"

// Additional AA Answer registers



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
assign ans_name     = ans_name_reg;
assign ans_type     = ans_type_reg;
assign ans_class    = ans_class_reg;
assign ans_ttl      = ans_ttl_reg;
assign ans_datalen  = ans_datalen_reg;
assign ans_addr     = ans_addr_reg; 
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

    ans_name_next = ans_name_reg;
    ans_type_next = ans_type_reg;
    ans_class_next = ans_class_reg;
    ans_ttl_next = ans_ttl_reg;
    ans_datalen_next = ans_datalen_reg;
    ans_addr_next = ans_addr_reg;

    source_ip_next = source_ip_reg;
    dest_ip_next = dest_ip_reg;

    parser_valid_next = parser_valid_reg && !parser_ready;

    case(state_reg)
        STATE_IDLE: begin
            pkt_ready_next = !parser_valid_next;

            if (pkt_valid == 1'b1) begin
                pkt_next = pkt;
                state_next = STATE_RD_HDR;
                pkt_ready_next = 1'b0;
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
            if (pkt_reg[(pkt_size - 1) -: 16] == 16'hC00C) begin
                // If the next 2 bytes is "C00C", an answer exist
                state_next = STATE_RD_ANSWER_TYPE;
                pkt_next = pkt_reg << 16;
            end else begin
                // Otherwise, start over and read next packet header.
                state_next = STATE_RD_HDR;
            end
        end

        // Same logic as STATE_RD_QUESTION_NAME
        STATE_RD_ANSWER_NAME: begin
            // Read the queried name in byte by byte until the null terminator is found.
            if (pkt_reg[(pkt_size - 1) -: 8] == 8'b0) begin
                state_next = STATE_RD_ANSWER_TYPE;
            end else begin
                state_next = STATE_RD_QUESTION_NAME;
            end

            // Include null terminator in qry_name
            ans_name_next[7:0] = pkt_reg[(pkt_size - 1) -: 8];
            
            pkt_next = pkt_reg << 8; // Shift byte by byte
        end

        STATE_RD_ANSWER_NAME_SHIFT: begin
            ans_name_next = ans_name_reg << 8;

            state_next = STATE_RD_ANSWER_NAME;
        end

        STATE_RD_ANSWER_TYPE: begin
            ans_type_next = pkt_reg[pkt_size - 1: pkt_size - type_size];

            // Check if type == A (1)
            if (pkt_reg[pkt_size - 1: pkt_size - type_size] == 8'h01) begin
                state_next = STATE_RD_ANSWER_A;
            end

            // Check if type == AAAA (128)
            if (pkt_reg[pkt_size - 1: pkt_size - type_size] == 8'h80) begin
                state_next = STATE_RD_ANSWER_AAAA;
            end

            pkt_next = pkt_reg << type_size;
        end

        // The rest of the data is fixed, it can be read in one state
        STATE_RD_ANSWER_A: begin
            { 
                ans_class_next,
                ans_ttl_next,
                ans_datalen_next,
                ans_addr_next} = pkt_reg[pkt_size - 1: pkt_size - a_fixed_data_size];

            state_next = STATE_IDLE;
            parser_valid_next = 1'b1;
            pkt_ready_next = !parser_valid_next;
            pkt_next = pkt_reg << a_fixed_data_size;
        end

       
        STATE_RD_ANSWER_AAAA: begin
            // Verify this is fixed len
            {
                ans_class_next,
                ans_ttl_next,
                ans_datalen_next,
                ans_addr_next} = pkt_reg[pkt_size - 1: pkt_size - aaaa_fixed_data_size];

            state_next = STATE_IDLE;
            parser_valid_next = 1'b1;
            pkt_ready_next = !parser_valid_next;
            pkt_next = pkt_reg << aaaa_fixed_data_size;
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
        ans_name_reg <= 2048'b0;
        ans_type_reg <= 16'b0;
        ans_class_reg <= 16'b0;
        ans_ttl_reg <= 32'b0;
        ans_datalen_reg <= 16'b0;
        ans_addr_reg <= 32'b0;

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
        ans_name_reg <= ans_name_next;
        ans_type_reg <= ans_type_next;
        ans_class_reg <= ans_class_next;
        ans_ttl_reg <= ans_ttl_next;
        ans_datalen_reg <= ans_datalen_next;
        ans_addr_reg <= ans_addr_next;

        parser_valid_reg <= parser_valid_next;


        if (state_reg == STATE_IDLE) begin

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
            qry_name_reg    <= 2048'b0;
            qry_type_reg    <= 16'b0;
            qry_class_reg   <= 16'b0;

            // latch in answer info
            ans_name_reg    <= 2048'b0;
            ans_type_reg    <= 16'b0;
            ans_class_reg   <= 16'b0;
            ans_ttl_reg     <= 32'b0;
            ans_datalen_reg <= 16'b0;
            ans_addr_reg    <= 32'b0;

        end
    end
end

endmodule