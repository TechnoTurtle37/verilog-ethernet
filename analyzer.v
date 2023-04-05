module analyzer(
    input  wire rst,
    input  wire clk,
    input  wire [4095:0] pkt,
    input  wire pkt_valid,
    output wire pkt_ready
);
    
localparam [5:0]
    STATE_IDLE

localparam hdr_size = 96 // bits
localparam pkt_size = 4096 // bits

reg [5:0] state_reg = STATE_IDLE, state_next;
reg [4095:0] pkt_reg, pkt_next;

reg pkt_ready_reg, pkt_ready_next;
reg pkt_valid_reg, pkt_valid_next;

reg [15:0] hdr_id, hdr_id_next;
reg hdr_qr, hdr_qr_next;
reg [3:0] hdr_opcode, hdr_opcode_next;
reg hdr_aa, hdr_aa_next;
reg hdr_tc, hdr_tc_next;
reg hdr_rd, hdr_rd_next;
reg hdr_ra, hdr_ra_next;
reg [2:0] hdr_z, hdr_z_next;
reg [3:0] hdr_rcode, hdr_rcode_next;
reg [15:0] hdr_qdcount, hdr_qdcount_next;
reg [15:0] hdr_ancount, hdr_ancount_next;
reg [15:0] hdr_nscount, hdr_nscount_next;
reg [15:0] hdr_arcount, hdr_arcount_next;

// q name


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

    case(state_reg) begin
        STATE_IDLE: begin
            pkt_ready_next = 1'b0;

            if (pkt_valid == 1'b1) begin
                pkt_next = pkt;
                state_next = STATE_RD_HDR;
            end
        end

        STATE_RD_HDR: begin
            pkt_ready_next = 1'b1;

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
                hdr_arcount_next} = pkt[pkt_size - 1 : pkt_size - hdr_size - 1];

            pkt_next = pkt << hdr_size;

            if (hdr_qdcount > 0)
                state_next = STATE_RD_QUESTION;
            else if (hdr_ancount > 0)
                state_next = STATE_RD_ANSWER;
            else
                state_next = STATE_EMPTY_PKT;
        end

        STATE_RD_QUESTION_NAME: begin
            
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= STATE_IDLE;
        pkt <= 4096'b0;
        pkt_ready <= 1'b0;
    end else begin
        state <= state_next;
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

    end
end

endmodule