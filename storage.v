// Storage and Statistics Module
// Written by Senior Design team, this takes in DNS values on separate singals and runs through the main features of the project
// We store the data for the domain name if it's a new Qname, otherwise we update the statistics for a known QNAME
// All states have a _WAIT or _W state, this is how the design waits for SDRAM to retreive the data since it's a multi-clock cycle operation

module storage(



	input wire clk,
	input wire rst,
	output wire [5:0] state, //Debugging only

	input wire parser_valid,
    output wire parser_ready,

    input wire [15:0] hdr_id,
    input wire hdr_qr,
    input wire [3:0] hdr_opcode,
    input wire hdr_aa,
    input wire hdr_tc,
    input wire hdr_rd,
    input wire hdr_ra,
    input wire [2:0] hdr_z,
    input wire [3:0] hdr_rcode,
    input wire [15:0] hdr_qdcount,
    input wire [15:0] hdr_ancount,
    input wire [15:0] hdr_nscount,
    input wire [15:0] hdr_arcount,

	input  wire [31:0] hdr_source_ip,
    input  wire [31:0] hdr_dest_ip,

    // Query  wires,
    input wire [2047:0] qry_name,
    input wire [15:0]  qry_type,
    input wire [15:0]  qry_class,

    // A Answer wires,
    input wire [15:0]  ans_type,
    input wire [15:0]  ans_class,
    input wire [31:0]  ans_ttl,
    input wire [15:0]  ans_datalen,
    input wire [31:0]  ans_addr,
	input wire [31:0]  ans_addr_2,
    input wire [31:0]  ans_addr_3,
    input wire [31:0]  ans_addr_4,
    input wire [31:0]  ans_addr_5,
    input wire [31:0]  ans_addr_6,
    input wire [31:0]  ans_addr_7,
    input wire [31:0]  ans_addr_8,
    input wire [31:0]  ans_addr_9,
    input wire [31:0]  ans_addr_10,
    input wire [31:0]  ans_addr_11,
    input wire [31:0]  ans_addr_12,
    input wire [31:0]  ans_addr_13,
    input wire [31:0]  ans_addr_14,
    input wire [31:0]  ans_addr_15,
    input wire [31:0]  ans_addr_16,
    input wire [31:0]  ans_addr_17,
    input wire [31:0]  ans_addr_18,
    input wire [31:0]  ans_addr_19,
    input wire [31:0]  ans_addr_20,
    input wire [31:0]  ans_addr_21,
    input wire [31:0]  ans_addr_22,
    input wire [31:0]  ans_addr_23,
    input wire [31:0]  ans_addr_24,
    input wire [31:0]  ans_addr_25,
    input wire [31:0]  ans_addr_26,
    input wire [31:0]  ans_addr_27,
    input wire [31:0]  ans_addr_28,
    input wire [31:0]  ans_addr_29,
    input wire [31:0]  ans_addr_30,
	input wire [127:0]  a4_ans_addr,
    input wire [127:0]   a4_ans_addr_2,
    input wire [127:0]   a4_ans_addr_3,
    input wire [127:0]   a4_ans_addr_4,
    input wire [127:0]   a4_ans_addr_5,
    input wire [127:0]   a4_ans_addr_6,
    input wire [127:0]   a4_ans_addr_7,
    input wire [127:0]   a4_ans_addr_8,
	input wire [2047:0] ans_cname_1,
	input wire [2047:0] ans_cname_2,
		

	input wire [4:0]   ans_a_count,
	input wire [2:0]   ans_aaaa_count,
	input wire [1:0]   ans_cname_count,


	//Memory Outputs to SDRAM Controller
	output wire [24:0] wb_addr_o,
	output wire [31:0] wb_data_o,
	input wire  [31:0] wb_data_i,
	output wire wb_we_o,
	input wire wb_ack_i,
	output wire wb_stb_o,
	output wire wb_cyc_o,

	//Offload ot RS-232
	output wire [7:0] uart_data,
	output wire uart_valid,
	input wire uart_ready

);

localparam [5:0]
    STATE_IDLE = 6'd0,
    STATE_WRITE_QNAME = 6'd1,
    STATE_WRITE_QNAME_WAIT = 6'd2,
    STATE_READ_STATS = 6'd3,
    STATE_READ_STATS_W = 6'd4,
	STATE_OFFLOAD = 6'd5,
	STATE_HASHING = 6'd6,
	STATE_CHECK_CELLS = 6'd7,
	STATE_CHECK_CELLS_WAIT = 6'd8,
	STATE_CHECK_NAME = 6'd9,
	STATE_CHECK_NAME_WAIT = 6'd10,
	STATE_ZERO = 6'd11,
	STATE_ZERO_WAIT = 6'd12,
	STATE_NAME_MATCH = 6'd13,
	STATE_UPDATE_STATS = 6'd14,
	STATE_UPDATE_STATS_W = 6'd15,
	STATE_CHECK_A = 6'd16,
	STATE_CHECK_A_W = 6'd17,
	STATE_CHECK_AAAA = 6'd18,
	STATE_CHECK_AAAA_W = 6'd19,
	STATE_CHECK_CNAME = 6'd20,
	STATE_CHECK_CNAME_W = 6'd21,
	STATE_APPEND_A = 6'd22,
	STATE_APPEND_A_W = 6'd23,
	STATE_APPEND_AAAA = 6'd24,
	STATE_APPEND_AAAA_W = 6'd25,
	STATE_APPEND_CNAME = 6'd26,
	STATE_APPEND_CNAME_W = 6'd27,
	STATE_CHECK_QHOST = 6'd28,
	STATE_CHECK_QHOST_W = 6'd29,
	STATE_WRITE_QHOST = 6'd30,
	STATE_WRITE_QHOST_W = 6'd31,
	STATE_OFFLOAD_W = 6'd32,
	STATE_CHECK_AAAA_SPACE = 6'd33,
	STATE_CHECK_CNAME_SPACE = 6'd34,
	STATE_CHECK_AAAA_SPACE_W = 6'd33,
	STATE_CHECK_CNAME_SPACE_W = 6'd34,
	STATE_UPDATE_QHOST_STAT = 6'd35,
	STATE_UPDATE_QHOST_STAT_W = 6'd36,
	STATE_READ_QHOST_STAT = 6'd37,
	STATE_READ_QHOST_STAT_W = 6'd38,
	STATE_SET_IN_USE = 6'd39,
	STATE_SET_IN_USE_W = 6'd40;
	
	
reg [5:0] 	state_reg, state_next;
reg [7:0] 	data_count_reg, data_count_next;

reg 		parser_ready_reg, parser_ready_next;

// Header registers
reg [15:0] 	hdr_id_reg, hdr_id_next;
reg 		hdr_qr_reg, hdr_qr_next;
reg [3:0] 	hdr_opcode_reg, hdr_opcode_next;
reg 		hdr_aa_reg, hdr_aa_next;
reg 		hdr_tc_reg, hdr_tc_next;
reg 		hdr_rd_reg, hdr_rd_next;
reg 		hdr_ra_reg, hdr_ra_next;
reg [2:0] 	hdr_z_reg, hdr_z_next;
reg [3:0] 	hdr_rcode_reg, hdr_rcode_next;
reg [15:0] 	hdr_qdcount_reg, hdr_qdcount_next;
reg [15:0] 	hdr_ancount_reg, hdr_ancount_next;
reg [15:0] 	hdr_nscount_reg, hdr_nscount_next;
reg [15:0] 	hdr_arcount_reg, hdr_arcount_next;
reg [31:0] 	source_ip_reg, source_ip_next;
reg [31:0] 	dest_ip_reg, dest_ip_next;

// Query registers
reg [2047:0] qry_name_reg, qry_name_next;
reg [15:0] 	qry_type_reg, qry_type_next;
reg [15:0] 	qry_class_reg, qry_class_next;

// A Answer registers
reg [15:0] 	ans_type_reg, ans_type_next;
reg [15:0] 	ans_class_reg, ans_class_next;
reg [31:0] 	ans_ttl_reg, ans_ttl_next;
reg [15:0] 	ans_datalen_reg, ans_datalen_next;
reg [1023:0] 	ans_addr_reg, ans_addr_next;
reg [1023:0] 	ans_aaaa_addr_reg, ans_aaaa_addr_next;
reg [4095:0] ans_cname_reg, ans_cname_next;
reg [5:0]	ans_a_count_reg, ans_a_count_next;
reg [3:0]	ans_aaaa_count_reg, ans_aaaa_count_next;
reg [3:0]	ans_cname_count_reg, ans_cname_count_next;

// Internal Registers for intermittent use by features
reg [31:0]  block_aaaa_count_reg, block_aaaa_count_next;
reg [31:0]  block_cname_count_reg, block_cname_count_next;
reg [31:0]	block_a_count_reg, block_a_count_next;
reg [31:0]	qhosts_count_reg, qhosts_count_next;
reg [31:0]	query_count_reg, query_count_next;
reg [31:0]	resolve_count_reg, resolve_count_next;

// SDRAM Outputs
reg [24:0]  wb_addr_reg, wb_addr_next;
reg [31:0]  wb_data_o_reg, wb_data_o_next;
reg [31:0]  wb_data_i_reg, wb_data_i_next;
reg         wb_we_reg, wb_we_next;
reg         wb_stb_reg, wb_stb_next;
reg         wb_cyc_reg, wb_cyc_next;

// RS232 offload
reg [7:0] uart_data_reg, uart_data_next;
reg uart_valid_reg, uart_valid_next;

//Internal Addressing signals
reg [10:0] 	intrablock_addr_reg, intrablock_addr_next;
reg [2:0] 	interblock_addr_reg, interblock_addr_next;

// Statistics
reg [31:0] 	cell_flags_reg, cell_flags_next;
reg [31:0] parsed_pkts_reg, parsed_pkts_next;
reg 		overflow_reg, overflow_next;

//HAsh related signals
reg [31:0] 	qname_hash_reg;
reg [31:0] 	hash_reg, hash_next;
reg 		hash_ready_reg, hash_ready_next;
reg 		qname_valid_reg, qname_valid_next;
wire 		hash_valid;
wire 		hash_ready;
wire 		hash_busy;
wire [31:0] hash;


//OUTPUT DATAPATH
assign wb_addr_o = wb_addr_reg;
assign wb_data_o = wb_data_o_reg;
assign wb_we_o = wb_we_reg;
assign wb_stb_o = wb_stb_reg;
assign wb_cyc_o = wb_cyc_reg;

assign uart_data = uart_data_reg;
assign uart_valid = uart_valid_reg;

assign parser_ready = parser_ready_reg;

assign state = state_reg;

sbdm2048 hash_qname_inst (

	.clk(clk),
	.rst(rst),
	
	.qname(qry_name_reg),
	.qname_valid(parser_valid),
	.qname_ready(hash_busy),

	.hash(hash),
	.hash_valid(hash_valid),
	.hash_ready(1'b1)

);

always @(*) begin

    state_next = STATE_IDLE;


	//Default values, these are to protect against inferred latches in the sythesised design
    wb_addr_next = wb_addr_reg;
    wb_data_o_next = wb_data_o_reg;
    wb_we_next   = wb_we_reg;
    wb_stb_next  = wb_stb_reg;
    wb_cyc_next  = wb_cyc_reg;
	wb_data_i_next = wb_data_i_reg;

	data_count_next = data_count_reg;
	parser_ready_next = parser_ready_reg;
	hdr_id_next = hdr_id_reg;
	hdr_qr_next = hdr_qr_reg;
	hdr_opcode_next = hdr_opcode_reg;
	hdr_aa_next = hdr_aa_reg;
	hdr_tc_next = hdr_tc_reg;
	hdr_rd_next = hdr_rd_reg;
	hdr_ra_next = hdr_ra_reg;
	hdr_z_next = hdr_z_reg;
	hdr_rcode_next = hdr_rcode_reg;
	hdr_qdcount_next = hdr_qdcount_reg;
	hdr_ancount_next = hdr_ancount_reg;
	hdr_nscount_next = hdr_nscount_reg;
	hdr_arcount_next = hdr_arcount_reg;
	source_ip_next = source_ip_reg;
	dest_ip_next = dest_ip_reg;
	qry_name_next = qry_name_reg;
	qry_type_next = qry_type_reg;
	qry_class_next = qry_class_reg;
	ans_type_next = ans_type_reg;
	ans_class_next = ans_class_reg;
	ans_ttl_next = ans_ttl_reg;
	ans_datalen_next = ans_datalen_reg;
	ans_addr_next = ans_addr_reg;

	ans_aaaa_addr_next = ans_aaaa_addr_reg;
	ans_cname_next = ans_cname_reg;

	ans_a_count_next = ans_a_count_reg;
	ans_aaaa_count_next = ans_aaaa_count_reg;
	ans_cname_count_next = ans_cname_count_reg;

	block_aaaa_count_next = block_aaaa_count_reg;
	block_cname_count_next = block_cname_count_reg;
	block_a_count_next = block_a_count_reg;
	qhosts_count_next = qhosts_count_reg;
	query_count_next = query_count_reg;
	resolve_count_next = resolve_count_reg;

	hash_next = hash_reg;
	hash_ready_next = hash_ready_reg;
	qname_valid_next = qname_valid_reg;

	intrablock_addr_next = intrablock_addr_reg;
	interblock_addr_next = interblock_addr_reg;

	cell_flags_next = cell_flags_reg;
	parsed_pkts_next = parsed_pkts_reg;
	overflow_next = overflow_reg;

	uart_data_next = uart_data_reg;
	uart_valid_next = uart_valid_reg;
	

    case(state_reg) 
		
		STATE_ZERO : begin // SDRAM starts with garbled data, we need to zero it all out before we begin

			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next  = 1'b1;
			wb_data_o_next = 32'h00000000;
			parsed_pkts_next = 32'b0;
			state_next = STATE_ZERO_WAIT;


		end

		STATE_ZERO_WAIT : begin

			if (wb_ack_i) begin

				if (wb_addr_reg == 25'h1FFFFFF) begin

					wb_stb_next = 1'b0;
					wb_cyc_next = 1'b0;
					wb_we_next  = 1'b0;
					state_next = STATE_IDLE;

				end else begin

					wb_stb_next = 1'b0;
					wb_cyc_next = 1'b0;
					wb_we_next  = 1'b0;
					wb_addr_next = wb_addr_reg + 1;
					state_next = STATE_ZERO;

				end

			end else begin

				state_next = STATE_ZERO_WAIT;

			end

		end

        STATE_IDLE: begin //Wait for a new packet

			parser_ready_next = 1'b1;
			if (parsed_pkts_reg >= 2) begin //This is a debug to trigger an early offload for demonstration purposes

					state_next = STATE_OFFLOAD;
					wb_addr_next = {hash_reg[10:0], interblock_addr_reg, 11'b0};
					intrablock_addr_next = 11'b00000000001;
					wb_cyc_next = 1'b1;
					wb_stb_next = 1'b1;
					wb_we_next = 1'b0;

			end else if (parser_valid == 1'b1) begin // We have a new packet from the analyzer

				data_count_next = 8'h3f;
				state_next = STATE_HASHING;

				

				hdr_id_next = hdr_id;
				hdr_qr_next = hdr_qr;
				hdr_opcode_next = hdr_opcode;
				hdr_aa_next = hdr_aa;
				hdr_tc_next = hdr_tc;
				hdr_rd_next = hdr_rd;
				hdr_ra_next = hdr_ra;
				hdr_z_next = hdr_z;
				hdr_rcode_next = hdr_rcode;
				hdr_qdcount_next = hdr_qdcount;
				hdr_ancount_next = hdr_ancount;
				hdr_nscount_next = hdr_nscount;
				hdr_arcount_next = hdr_arcount;
				source_ip_next = hdr_source_ip;
				dest_ip_next = hdr_dest_ip;

				qry_name_next = qry_name;
				qry_type_next = qry_type;
				qry_class_next = qry_class;

				ans_type_next = ans_type;
				ans_class_next = ans_class;
				ans_ttl_next = ans_ttl;
				ans_datalen_next = ans_datalen;

				//This is sometrhing we did to save on time. 
				ans_addr_next = {ans_addr, ans_addr_2, ans_addr_3, ans_addr_4, ans_addr_5, ans_addr_6, ans_addr_7, ans_addr_8, ans_addr_9, ans_addr_10, ans_addr_11, ans_addr_12, ans_addr_13, ans_addr_14, ans_addr_15, ans_addr_16, ans_addr_17, ans_addr_18, ans_addr_19, ans_addr_20, ans_addr_21, ans_addr_22, ans_addr_23, ans_addr_24, ans_addr_25, ans_addr_26, ans_addr_27, ans_addr_28, ans_addr_29, ans_addr_30, 16'b0};

				ans_aaaa_addr_next = {a4_ans_addr, a4_ans_addr_2, a4_ans_addr_3, a4_ans_addr_4, a4_ans_addr_5, a4_ans_addr_6, a4_ans_addr_7, a4_ans_addr_8};
				ans_cname_next = {ans_cname_1, ans_cname_2};
				// ans_cname_1_next = ans_cname_1;
				// ans_cname_2_next = ans_cname_2;

				ans_a_count_next = ans_a_count;
				ans_aaaa_count_next = ans_aaaa_count;
				ans_cname_count_next = ans_cname_count;

				qname_valid_next = 1'b1;
				intrablock_addr_next = 11'h40;
				interblock_addr_next = 3'b0;

			end

        end

		STATE_HASHING : begin //Get a hash of the QNAME for use in addressing

			parser_ready_next = 1'b0;

			if (hash_busy == 1'b0) begin

				state_next = STATE_HASHING;

			end else begin

				hash_next = 32'b0;
				state_next = STATE_CHECK_CELLS;

			end

		end

		STATE_CHECK_CELLS : begin //Check to see if there is data in the cell we're looking at

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b0;
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_CHECK_CELLS_WAIT;

		end

		STATE_CHECK_CELLS_WAIT : begin

			if (wb_ack_i) begin

				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

				if (wb_data_i[0] == 1'b1) begin //There is data, check if it's the same domain that we just received

					state_next = STATE_CHECK_NAME;
					intrablock_addr_next = 11'd63;

				end else begin 

					state_next = STATE_WRITE_QNAME; // There is no data, write this domain's info in this cell
					intrablock_addr_next = 11'b0;

				end

			end else begin

				state_next = STATE_CHECK_CELLS_WAIT;

			end

		end

		STATE_CHECK_NAME : begin //Check if the name in the cell is the QNAME of the packet we just got

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b0;
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_CHECK_NAME_WAIT;
			

		end

		STATE_CHECK_NAME_WAIT : begin 

			if (wb_ack_i) begin 

				//If we've hit all zeroes, we're at the end of the QNAME and have a match, OR, we need to check if the last byte matches in the event that the QNAME
				//has taken up the entire register with no zero padding. Names are alighed to the end of the register/memory block
				if (wb_data_i == 32'h00000000 || (intrablock_addr_reg == 11'b0 && wb_data_i == qry_name_reg[2047:2016]) ) begin 

					state_next = STATE_READ_STATS;
					intrablock_addr_next = 11'd65;
					wb_stb_next = 1'b0;
					wb_cyc_next = 1'b0;

				end else begin

					if (qry_name_reg[ (11'd63 - intrablock_addr_reg) * 32 +: 32] == wb_data_i) begin //If the current 4 bytes of the QNAME matches the current 3 bytes of the memory's QNAME, continue checking

						intrablock_addr_next = intrablock_addr_reg - 1;
						state_next = STATE_CHECK_NAME;


					end else begin

						if (interblock_addr_reg == 3'b111) begin //We did not match and are out of cells, quit and move to offload

							state_next = STATE_OFFLOAD;
							overflow_next = 1'b1;
							wb_stb_next = 1'b0;
							wb_cyc_next = 1'b0;

						end else begin //We did not match, move to the next cell after this one

							interblock_addr_next = interblock_addr_reg + 1;
							state_next = STATE_CHECK_CELLS;

						end

					end

				end
				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

			end else begin

				state_next = STATE_CHECK_NAME_WAIT;

			end

		end

        STATE_WRITE_QNAME: begin //Write the QNAME into an empty cell

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b1;
			wb_data_o_next = qry_name_reg[data_count_reg*32 +: 32];
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_WRITE_QNAME_WAIT;

        end

        STATE_WRITE_QNAME_WAIT: begin

			if (wb_ack_i == 1'b1) begin

				if (data_count_reg == 8'b0) begin //We're done writing, move to setting the IN_USE flag

					state_next = STATE_SET_IN_USE;
					intrablock_addr_next = 11'd64;

					wb_cyc_next = 1'b0;
					wb_stb_next = 1'b0;

				end else begin //Write the next word of QNAME

					state_next = STATE_WRITE_QNAME;
					wb_cyc_next = 1'b0;
					wb_stb_next = 1'b0;
					data_count_next = data_count_reg - 1;
					intrablock_addr_next = intrablock_addr_reg + 1;

				end

				wb_we_next = 1'b0;

			end else begin 

				state_next = STATE_WRITE_QNAME_WAIT;

			end

        end

		STATE_SET_IN_USE : begin //Set the IN_USE flag in the block

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_data_o_next = 32'b1;
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b1;
			state_next = STATE_SET_IN_USE_W;

		end

		STATE_SET_IN_USE_W : begin //Wait for ACK signal from DRAM then move to a stat read

			if (wb_ack_i) begin

				state_next = STATE_READ_STATS;
				intrablock_addr_next = 11'd65;
				wb_cyc_next = 1'b0;
				wb_stb_next = 1'b0;
				wb_we_next = 1'b0;

			end else begin

				state_next = STATE_SET_IN_USE_W;

			end

		end

		STATE_READ_STATS : begin //Read in stat block at current address

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b0;
			state_next = STATE_READ_STATS_W;

		end

		STATE_READ_STATS_W : begin //Save the stat block we just read to a register and move to the next block

			if (wb_ack_i) begin

				case (intrablock_addr_reg)

					11'd65 : begin

						query_count_next = wb_data_i;
						intrablock_addr_next = 11'd66;
						state_next = STATE_READ_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd66 : begin

						resolve_count_next = wb_data_i;
						intrablock_addr_next = 11'd67;
						state_next = STATE_READ_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd67 : begin

						qhosts_count_next = wb_data_i;
						intrablock_addr_next = 11'd68;
						state_next = STATE_READ_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd68 : begin

						block_a_count_next = wb_data_i;
						intrablock_addr_next = 11'd69;
						state_next = STATE_READ_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd69 : begin

						block_aaaa_count_next = wb_data_i;
						intrablock_addr_next = 11'd70;
						state_next = STATE_READ_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd70 : begin //Last read, move to writing new stats

						block_cname_count_next = wb_data_i;
						intrablock_addr_next = 11'd65;
						state_next = STATE_UPDATE_STATS;
						wb_data_o_next = query_count_reg + 1;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

				endcase

				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

			end else begin

				state_next = STATE_READ_STATS_W;

			end

		end

		STATE_UPDATE_STATS : begin // Write the currently selected stat block

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b1;
			state_next = STATE_UPDATE_STATS_W;

		end

		STATE_UPDATE_STATS_W : begin

			if (wb_ack_i) begin

				case (intrablock_addr_reg)

					11'd65 : begin

						wb_data_o_next = resolve_count_reg + ans_a_count_reg + ans_aaaa_count_reg + ans_cname_count_reg;
						intrablock_addr_next = 11'd66;
						state_next = STATE_UPDATE_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd66 : begin 

						wb_data_o_next = block_a_count_reg + ans_a_count_reg;
						intrablock_addr_next = 11'd68;
						state_next = STATE_UPDATE_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					// 11'd67 : begin //Can't do this yet, needs to do a QHOST_CHECK first

						

					// end

					11'd68 : begin

						wb_data_o_next = block_aaaa_count_reg + ans_aaaa_count_reg;
						intrablock_addr_next = 11'd69;
						state_next = STATE_UPDATE_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd69 : begin

						wb_data_o_next = block_cname_count_reg + ans_cname_count_reg;
						intrablock_addr_next = 11'd70;
						state_next = STATE_UPDATE_STATS;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

					11'd70 : begin //Move to checking Resource Records next

						if (ans_a_count_reg > 5'b0) begin //If we have A records

							state_next = STATE_CHECK_A;
							intrablock_addr_next = 11'd128;

						end else if (ans_aaaa_count_reg > 3'b0 && (block_aaaa_count_reg + ans_aaaa_count_reg) <= 32'd64) begin //If we have AAAA records and space to store them

							state_next = STATE_CHECK_AAAA;
							data_count_next = 8'd0;
							intrablock_addr_next = 11'd512;
						
						end else if (ans_aaaa_count_reg > 3'b0 && (block_aaaa_count_reg + ans_aaaa_count_reg) > 32'd64) begin //If we have AAAA records but not space, offload

							state_next = STATE_OFFLOAD;
							overflow_next = 1'b1;
							wb_stb_next = 1'b0;
							wb_cyc_next = 1'b0;

						end else if (ans_cname_count_reg > 3'b0 && (block_cname_count_reg + ans_cname_count_reg) <= 32'd4) begin //If we have space for CNAMES (if not, just skip)

							state_next = STATE_CHECK_CNAME;
							data_count_next = 8'd0;
							intrablock_addr_next = 11'd831;

						end else begin //No answers, query only

							state_next = STATE_CHECK_QHOST;
							intrablock_addr_next = 11'd1024;

						end

						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

				endcase

				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

				wb_we_next = 1'b0;

			end else begin

				state_next = STATE_UPDATE_STATS_W;

			end

		end

		STATE_CHECK_A : begin //Check if we already know about this A record

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b0;
			state_next = STATE_CHECK_A_W;

		end

		STATE_CHECK_A_W : begin

			if (wb_ack_i == 1'b1) begin

				if (wb_data_i == ans_addr_reg[ 1023 - ( ( ans_a_count - 1 ) *32 ) +: 32 ] ) begin //If we have a match...

					//STATISTIC UPDATE
					if (ans_a_count_reg == 5'b0) begin //...and there are no more A records, go to AAAA or CNAME

						if (ans_aaaa_count_reg > 3'b0) begin

							state_next = STATE_CHECK_AAAA;
							intrablock_addr_next = 11'd512;
							data_count_next = 8'b0;

						end else if (ans_cname_count_reg > 2'b0) begin 

							state_next = STATE_CHECK_CNAME;
							intrablock_addr_next = 11'd831;
							data_count_next = 8'h00;

						end else begin

							state_next = STATE_CHECK_QHOST;
							intrablock_addr_next = 11'd1024;

						end

						wb_cyc_next = 1'b0;
						wb_stb_next = 1'b0;

					end else begin

						ans_a_count_next = ans_a_count_reg - 1; //Reduce A record count (indexes A record register)
						state_next = STATE_CHECK_A; 
						intrablock_addr_next = 11'd128;

					end

				end else begin

					if (intrablock_addr_reg == 11'd511) begin //No match and we hit the last A record slot, offload

						state_next = STATE_OFFLOAD;
						overflow_next = 1'b1;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end else if (wb_data_i == 32'h00000000) begin //No match and an empty slot, write here
						
						state_next = STATE_APPEND_A;

						
					end else begin //No match and there are still slots left, advance slot number and check again

						state_next = STATE_CHECK_A;
						intrablock_addr_next = intrablock_addr_reg + 1;

					end

				end

			end else begin 

				state_next = STATE_CHECK_A_W;

			end

		end

		STATE_APPEND_A : begin //This is a new A record, add it to the next open slot

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b1;
			wb_data_o_next = ans_addr_reg[ans_a_count*32 +: 32];
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_APPEND_A_W;

		end

		STATE_APPEND_A_W : begin

			if (wb_ack_i == 1'b1) begin

				if (ans_a_count_reg == 5'b0) begin //No mroe A records, go to AAAA or CNAME if they're there

					if (ans_aaaa_count_reg > 3'b0) begin

						state_next = STATE_CHECK_AAAA;
						intrablock_addr_next = 11'd512;
						data_count_next = 8'b0;

					end else if (ans_cname_count_reg > 2'b0) begin

						state_next = STATE_CHECK_CNAME;
						intrablock_addr_next = 11'd831;
						data_count_next = 8'h00;

					end else begin

						state_next = STATE_CHECK_QHOST;
						intrablock_addr_next = 11'd1024;

					end

					wb_cyc_next = 1'b0;
					wb_stb_next = 1'b0;

				end else begin //There are more A records, advance to the next answer and go back to Check state

					wb_cyc_next = 1'b1;
					wb_stb_next = 1'b1;
					ans_a_count_next = ans_a_count_reg - 1;
					state_next = STATE_CHECK_A;
					intrablock_addr_next = 11'd128;
					

				end

				wb_we_next = 1'b1;

			end else begin 

				state_next = STATE_APPEND_A_W;

			end

		end

		STATE_CHECK_AAAA : begin //Check to see if we already have this AAAA record

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b0;
			state_next = STATE_CHECK_AAAA_W;
			

		end

		STATE_CHECK_AAAA_W : begin 

			if (wb_ack_i == 1'b1) begin

				if (wb_data_i == ans_aaaa_addr_reg[ 1023 - ( ( (ans_aaaa_count_reg - 1) * 4 + data_count_reg )  * 32 ) -: 32 ] ) begin //If this quarter is a match....

					if (data_count_reg == 8'd3) begin //...and it was the last quarter, then we have a full match. No need to write, just update the stats

						if (ans_aaaa_count_reg-1 == 3'b0) begin //No more AAAA, check if we have CNAMEs, otherwise go to QHOST check

							if (ans_cname_count_reg > 2'b0 && (block_cname_count_reg + ans_cname_count_reg) <= 32'd4) begin

								state_next = STATE_CHECK_CNAME;
								data_count_next = 8'd0;
								intrablock_addr_next = 11'd831;

							end else begin

								state_next = STATE_CHECK_QHOST;
								intrablock_addr_next = 11'd1024;

							end

							wb_cyc_next = 1'b0;
							wb_stb_next = 1'b0;
							wb_we_next  = 1'b0;

						end else begin //Check the next AAAA record

							ans_aaaa_count_next = ans_aaaa_count_reg - 1;
							state_next = STATE_CHECK_AAAA;
							intrablock_addr_next = 11'd512;
							data_count_next = 8'b0;

						end
					end else begin //Check the next quarter of this AAAA record

						data_count_next = data_count_reg + 1;
						intrablock_addr_next = intrablock_addr_reg + 1;
						state_next = STATE_CHECK_AAAA;

					end

				end else begin //Mismatch

					if (intrablock_addr_reg >= 11'd767) begin //Mismatch with no AAAA slots left, offload

						state_next = STATE_OFFLOAD;
						overflow_next = 1'b1;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end else if (wb_data_i == 32'h00000000 && data_count_reg == 8'h00) begin //mismatch with an empty AAAA slot, write here
						
						state_next = STATE_APPEND_AAAA;
						
						
					end else begin //Mismatch with mroe AAAA slots to check

						state_next = STATE_CHECK_AAAA;
						intrablock_addr_next = intrablock_addr_reg + 4 - data_count_reg;
						data_count_next = 8'b0;

					end

				end

				wb_cyc_next = 1'b0;
				wb_stb_next = 1'b0;
				wb_we_next  = 1'b0;

			end else begin 

				state_next = STATE_CHECK_AAAA_W;

			end

		end

		STATE_APPEND_AAAA : begin //Write the AAAA record quarter at the current location

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b1;
			wb_data_o_next = ans_aaaa_addr_reg[ 1023 - ( ( (ans_aaaa_count_reg - 1) * 4 + data_count_reg )  * 32 ) -: 32 ];
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_APPEND_AAAA_W;

		end

		STATE_APPEND_AAAA_W : begin

			if (wb_ack_i == 1'b1) begin

				if(data_count_reg == 8'd3) begin //Done writing the 4 parts of the record

					if (ans_aaaa_count_reg-1 > 3'b0) begin //There are more records to check, advance to the next AAAA record

							state_next = STATE_CHECK_AAAA;
							intrablock_addr_next = 11'd512;
							data_count_next = 8'b0;

					end else if (ans_cname_count_reg > 2'b0 && (block_cname_count_reg + ans_cname_count_reg) <= 32'd4) begin //Check CNAMES if there is space 

						state_next = STATE_CHECK_CNAME;
						data_count_next = 8'd0;
						intrablock_addr_next = 11'd831;

					end else begin //Otherwise, check the querying host

						state_next = STATE_CHECK_QHOST;

					end

					ans_aaaa_count_next = ans_aaaa_count_reg - 1;

				end else begin //the entire AAAA record hasn't been written yet, write the next 4 bytes

					intrablock_addr_next = intrablock_addr_reg + 1;
					data_count_next = data_count_reg + 1;
					state_next = STATE_APPEND_AAAA;

				end

				wb_cyc_next = 1'b0;
				wb_stb_next = 1'b0;
				wb_we_next  = 1'b0;

			end else begin

				state_next = STATE_APPEND_AAAA_W;

			end

		end

		STATE_CHECK_CNAME : begin //Read a portion fo the selected CNAME from the block

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b0;
			state_next = STATE_CHECK_CNAME_W;

		end

		STATE_CHECK_CNAME_W : begin

			if (wb_ack_i) begin 

				if (wb_data_i == 32'h00000000 || (ans_cname_reg[ ( ( (ans_cname_count_reg - 1) * 64 + 8'h3f )  * 32 ) +: 32 ] == wb_data_i && data_count_reg == 8'h3f)) begin //Full Match

					if (data_count_reg == 8'h00) begin //The slot is empty, write this CNAME

						state_next = STATE_APPEND_CNAME;
						data_count_next = 8'h3f;
						intrablock_addr_next = intrablock_addr_reg - 11'h3f;

					end else begin //Full match so no need to write anything, check if we have another CNAME, otherwise process querying host data 

						if (ans_cname_count_reg-1 == 2'b00) begin // No more CNAMES, move on

							state_next = STATE_CHECK_QHOST;
							intrablock_addr_next = 11'd1024;

						end else begin //We have another CNAME, alight back to the start of CNAME sotrage and restart CNAME check

							ans_cname_count_next = ans_cname_count_reg - 1;
							intrablock_addr_next = 11'd831;
							state_next = STATE_CHECK_CNAME;
							data_count_next = 8'b0;

						end
						
					end
					wb_stb_next = 1'b0;
					wb_cyc_next = 1'b0;

				end else begin //Not a full match

					if (ans_cname_reg[ ( ( (ans_cname_count_reg - 1) * 64 + data_count_reg )  * 32 ) +: 32 ] == wb_data_i) begin //Partial Match

						intrablock_addr_next = intrablock_addr_reg - 1;
						data_count_next = data_count_reg + 1;
						state_next = STATE_CHECK_CNAME;


					end else begin //Mismatch

						if (data_count_reg == 8'h3f) begin //No match, but ignore the collision

							state_next = STATE_CHECK_QHOST;
							overflow_next = 1'b1;
							wb_stb_next = 1'b0;
							wb_cyc_next = 1'b0;

						end else begin //Check the next CNAME stored

							intrablock_addr_next = intrablock_addr_reg + 64 + data_count_reg;
							state_next = STATE_CHECK_CNAME;
							data_count_next = 8'b0;

						end

					end

				end

				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

			end else begin

				state_next = STATE_CHECK_CNAME_W;

			end

		end

		STATE_APPEND_CNAME : begin //Write the CNAME word by word to the open slot

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b1;
			wb_data_o_next = ans_cname_reg[ ( ( (ans_cname_count_reg - 1) * 64 + data_count_reg )  * 32 ) +: 32 ];
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_APPEND_CNAME_W;

		end

		STATE_APPEND_CNAME_W : begin

			if (wb_ack_i == 1'b1) begin

				if (data_count_reg == 8'b0) begin //Last word written

					if (ans_cname_count_reg-1 == 2'b0) begin //More CNAMEs, go back to check state

						state_next = STATE_CHECK_QHOST;
						intrablock_addr_next = 11'd1024;
						wb_cyc_next = 1'b0;
						wb_stb_next = 1'b0;

					end else begin //No more resource records at this point, move to querying host check

						state_next = STATE_CHECK_CNAME;
						data_count_next = 8'd0;
						intrablock_addr_next = 11'd831;

					end

					ans_cname_count_next = ans_cname_count_reg - 1;

				end else begin //Write the next word of the Cname

					state_next = STATE_APPEND_CNAME;
					wb_cyc_next = 1'b1;
					wb_stb_next = 1'b1;
					data_count_next = data_count_reg - 1;
					intrablock_addr_next = intrablock_addr_reg + 1;

				end

				wb_we_next = 1'b0;
				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

			end else begin 

				state_next = STATE_APPEND_CNAME_W;

			end

		end

		STATE_CHECK_QHOST : begin //See if we already know about this querying host

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b0;
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_CHECK_QHOST_W;

		end

		STATE_CHECK_QHOST_W : begin 

			if (wb_ack_i) begin

				if (wb_data_i == dest_ip_reg) begin //Match, just do a stat update

					state_next = STATE_IDLE;
					parsed_pkts_next = parsed_pkts_reg + 1;

				end else if (wb_data_i == 32'h00000000) begin //Empty slot, write the host

					state_next = STATE_WRITE_QHOST;
				
				end else begin

					if (intrablock_addr_reg == 11'd2047) begin //No slots left, offload

						state_next = STATE_OFFLOAD;
						overflow_next = 1'b1;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end else begin //Check the next slot

						state_next = STATE_CHECK_QHOST;
						intrablock_addr_next = intrablock_addr_reg + 1;
						wb_we_next = 1'b0;
						wb_stb_next = 1'b0;
						wb_cyc_next = 1'b0;

					end

				end

				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;

			end else begin

				state_next = STATE_CHECK_QHOST_W;

			end

		end

		STATE_WRITE_QHOST : begin //Write the QHost at the given slot

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_we_next = 1'b1;
			wb_data_o_next = dest_ip_reg;
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			state_next = STATE_WRITE_QHOST_W;

		end

		STATE_WRITE_QHOST_W : begin //Write the QHost at the given slot

			if (wb_ack_i == 1'b1) begin

				state_next = STATE_READ_QHOST_STAT;
				intrablock_addr_next = 11'd67;
				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;
				wb_we_next = 1'b0;

			end else begin 

				state_next = STATE_WRITE_QHOST_W;

			end

		end

		STATE_READ_QHOST_STAT : begin //Read the unique QHost count from the stat block

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b0;
			state_next = STATE_READ_QHOST_STAT_W;

		end

		STATE_READ_QHOST_STAT_W : begin //Read the unique QHost count from the stat block

			if (wb_ack_i == 1'b1) begin

				wb_data_o_next = qhosts_count_reg + 1;
				state_next = STATE_UPDATE_QHOST_STAT;
				wb_cyc_next = 1'b0;
				wb_stb_next = 1'b0;

			end else begin

				state_next = STATE_READ_QHOST_STAT_W;

			end

		end

		STATE_UPDATE_QHOST_STAT: begin //Update the unique QHost count from the stat block

			wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
			wb_cyc_next = 1'b1;
			wb_stb_next = 1'b1;
			wb_we_next = 1'b1;
			state_next = STATE_UPDATE_QHOST_STAT_W;

		end

		STATE_UPDATE_QHOST_STAT_W: begin //Update the unique QHost count from the stat block

			if (wb_ack_i) begin

				state_next = STATE_IDLE;
				parsed_pkts_next = parsed_pkts_reg + 1;
				wb_we_next = 1'b0;
				wb_stb_next = 1'b0;
				wb_cyc_next = 1'b0;


			end else begin

				state_next = STATE_UPDATE_QHOST_STAT_W;

			end

		end

		STATE_OFFLOAD : begin //Offload the first block over RS232

			state_next = STATE_OFFLOAD;

			if (wb_ack_i) begin

				if (intrablock_addr_reg == 11'd2047) begin

					state_next = STATE_ZERO;
					wb_we_next = 1'b0;
					wb_stb_next = 1'b0;
					wb_cyc_next = 1'b0;
					wb_addr_next = 25'b0;

				end else begin

					wb_addr_next = {hash_reg[10:0], interblock_addr_reg, intrablock_addr_reg};
					intrablock_addr_next = intrablock_addr_reg + 1;
					wb_data_i_next = wb_data_i;

					if (uart_ready) begin

						uart_valid_next = 1'b1;
						uart_data_next = wb_data_i[31:24];
						data_count_next = 8'b00000001;

					end else begin

						uart_valid_next = 1'b0;
						data_count_next = 8'b0;

					end

				end

			end else if (uart_ready) begin

				if (data_count_reg < 8'd4) begin

					uart_valid_next = 1'b1;
					uart_data_next = wb_data_i_reg[31 - data_count_reg*8 -: 8];
					data_count_next = data_count_reg + 1;

				end else begin

					uart_valid_next = 1'b0;
					data_count_next = data_count_reg;

				end

			end

			

		end

    endcase

end

always @(posedge clk) begin

	if(rst) begin
		state_reg <= STATE_IDLE;
		parser_ready_reg <= 1'b0;
		data_count_reg <= 8'b0;
		parsed_pkts_reg <= 32'b0;

		wb_addr_reg <= 25'b0;
		wb_data_o_reg <= 32'b0;
		wb_we_reg <= 1'b0;
		wb_stb_reg <= 1'b0;
		wb_cyc_reg <= 1'b0;

		interblock_addr_reg <= 3'b0;
		intrablock_addr_reg <= 11'b0;

	end else begin

		state_reg <= state_next;
		parser_ready_reg <= parser_ready_next;

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

        source_ip_reg 	<= source_ip_next;
        dest_ip_reg 	<= dest_ip_next;

        // latch in query info
        qry_name_reg 	<= qry_name_next;
        qry_type_reg 	<= qry_type_next;
        qry_class_reg  	<= qry_class_next;

        // latch in answer info
        ans_type_reg 	<= ans_type_next;
        ans_class_reg 	<= ans_class_next;
        ans_ttl_reg 	<= ans_ttl_next;
        ans_datalen_reg <= ans_datalen_next;
        ans_addr_reg 	<= ans_addr_next;

		ans_aaaa_addr_reg 	<= ans_aaaa_addr_next;
		ans_cname_reg 		<= ans_cname_next;
		// ans_cname_1_reg <= ans_cname_1_next;
		// ans_cname_2_reg <= ans_cname_2_next;

		ans_a_count_reg     <= ans_a_count_next;
		ans_aaaa_count_reg  <= ans_aaaa_count_next;
		ans_cname_count_reg <= ans_cname_count_next;

		block_aaaa_count_reg 	<= block_aaaa_count_next;
		block_cname_count_reg 	<= block_cname_count_next;
		block_a_count_reg 		<= block_a_count_next;
		qhosts_count_reg 		<= qhosts_count_next;
		query_count_reg 		<= query_count_next;
		resolve_count_reg 		<= resolve_count_next;

		hash_reg <= hash_next;
		hash_ready_reg <= hash_ready_next;

		qname_valid_reg <= qname_valid_next;
		data_count_reg 	<= data_count_next;
		intrablock_addr_reg <= intrablock_addr_next;
		interblock_addr_reg <= interblock_addr_next;
		cell_flags_reg 	<= cell_flags_next;
		parsed_pkts_reg <= parsed_pkts_next;
		overflow_reg 	<= overflow_next;

		wb_addr_reg  <= wb_addr_next;
		wb_data_o_reg <= wb_data_o_next;
		wb_we_reg <= wb_we_next;
		wb_stb_reg <= wb_stb_next;
		wb_cyc_reg <= wb_cyc_next;
		wb_data_i_reg <= wb_data_i_next;

		uart_data_reg <= uart_data_next;
		uart_valid_reg <= uart_valid_next;

	end

end

endmodule