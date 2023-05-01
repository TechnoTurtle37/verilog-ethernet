module sbdm2048 (

	input wire clk,
	input wire rst,

	input wire [2047:0] qname,
	input wire qname_valid,
	output wire qname_ready,

	output wire [31:0] hash,
	output wire hash_valid,
	input wire hash_ready


);

localparam [1:0] 
	STATE_IDLE = 2'd0,
	STATE_HASH = 2'd1,
	STATE_HASH_SHIFT = 2'd2;


reg [1:0] state_reg, state_next;
reg [7:0] counter_reg, counter_next;

reg [31:0] hash_reg, hash_next;
reg qname_ready_reg, qname_ready_next;
reg hash_valid_reg, hash_valid_next;

assign hash = hash_reg;
assign qname_ready = qname_ready_reg;
assign hash_valid = hash_valid_reg;


always @(*) begin

	state_next = STATE_IDLE;

	qname_ready_next = 1'b0;

	counter_next = counter_reg;
	hash_next = hash_reg;
	qname_ready_next = qname_ready_reg;
	
	hash_valid_next = hash_valid_reg && !hash_ready;

	case(state_reg)

		STATE_IDLE : begin

			qname_ready_next = !hash_valid_next;
			counter_next = 8'hff;


			if (qname_valid == 1'b1) begin

				hash_next = 32'b0;
				state_next = STATE_HASH;
				qname_ready_next = 1'b0;
				
			end

		end

		STATE_HASH : begin

			if (counter_reg == 8'b0) begin

				state_next = STATE_IDLE;
				hash_valid_next = 1'b1;

			end else begin

				hash_next = qname[counter_reg*8 +: 8] + (hash_reg << 6) + (hash_reg << 16) - hash_reg;
				counter_next = counter_reg - 1;
				state_next = STATE_HASH;
				hash_valid_next = 1'b0;

			end

		end

	endcase

end

always @(posedge clk) begin

	if(rst) begin

		state_reg <= STATE_IDLE;
		counter_reg <= 8'hff;
		qname_ready_reg <= 1'b0;
		hash_valid_reg <= 1'b0;
		hash_reg <= 32'b0;

	end else begin

		state_reg <= state_next;
		qname_ready_reg <= qname_ready_next;

		counter_reg <= counter_next;
		hash_valid_reg <= hash_valid_next;
		hash_reg <= hash_next;

	end

end

endmodule