`timescale 1ns/100ps

module fpga_core_tb();

reg clk;
reg reset;
parameter TP = 1;
parameter CLK_HALF_PERIOD = 0.5;

integer idx;
reg [31:0] WISHBONE_RAM [0:8191];
reg [1:0] count_reg, count_next;

wire [24:0] sdram_wb_addr_i;
wire [31:0] sdram_wb_data_i;
wire [31:0] sdram_wb_data_o;
wire        sdram_wb_we_i;
wire        sdram_wb_ack_o;
wire        sdram_wb_stb_i;
wire        sdram_wb_cyc_i;

wire [7:0] uart_data;
wire uart_valid;


reg [2:0] state_reg, state_next;
reg [31:0] data_o_reg, data_o_next;
reg ack_o_reg, ack_o_next;


assign sdram_wb_ack_o = ack_o_reg;
assign sdram_wb_data_o = data_o_reg;

localparam [2:0] 
	STATE_IDLE = 3'd0,
	STATE_READ = 3'd1,
	STATE_WRITE = 3'd2;

	// assign clk = #CLK_HALF_PERIOD ~clk;  // Create a clock with a period of ten ns
	initial
	begin
		clk = 0;
		#5;
		forever clk = #( CLK_HALF_PERIOD )  ~clk;
	end

	initial
		begin
		$dumpfile("fpga_core_tb.vcd");
		$dumpvars(0,fpga_core_tb);
		for (idx = 0; idx < 8191; idx = idx + 1) begin
			$dumpvars(0, WISHBONE_RAM[idx]);
		end
		$readmemh("mem_init.mem", WISHBONE_RAM);
		// clk  = #CLK_HALF_PERIOD ~clk; 
		reset = #TP 1'b1;
		repeat (30) @ (posedge clk);
		reset  = #TP 1'b0;
		repeat (20000) @ (posedge clk);
		$finish ; // This causes the simulation to end.
		end

fpga_core core_inst (

	.clk_dram_c(clk),
	.rst(reset),
	.ext_sdram_wb_addr_i(sdram_wb_addr_i),
    .ext_sdram_wb_data_i(sdram_wb_data_i),
    .ext_sdram_wb_data_o(sdram_wb_data_o),
    .ext_sdram_wb_we_i(sdram_wb_we_i),
    .ext_sdram_wb_ack_o(sdram_wb_ack_o),
    .ext_sdram_wb_stb_i(sdram_wb_stb_i),
    .ext_sdram_wb_cyc_i(sdram_wb_cyc_i),
	.ext_uart_data(uart_data),
	.ext_uart_valid(uart_valid),
	.ext_uart_ready(1'b1)

);


always @(*) begin

	count_next = count_reg;
	data_o_next = data_o_reg;
	ack_o_next = ack_o_reg;
	state_next = STATE_IDLE;

	case(state_reg) 

		STATE_IDLE : begin

			if (sdram_wb_stb_i == 1'b1 && sdram_wb_cyc_i == 1'b1 && ack_o_reg == 1'b0) begin

				if (sdram_wb_we_i == 1'b1) begin

					state_next = STATE_WRITE;

				end else begin

					state_next = STATE_READ;

				end

				count_next = 2'b0;

			end else begin

				state_next = STATE_IDLE;

			end

			ack_o_next = 1'b0;
			data_o_next = 32'b0;

		end

		STATE_READ : begin

			if (count_reg == 2'b11) begin

				data_o_next = WISHBONE_RAM[sdram_wb_addr_i];
				ack_o_next = 1'b1;
				state_next = STATE_IDLE;

			end else begin

				state_next = STATE_READ;
				count_next = count_reg + 1;
				data_o_next = 32'b0;

			end

		end

		STATE_WRITE : begin

			if (count_reg == 2'b11) begin

				WISHBONE_RAM[sdram_wb_addr_i] = sdram_wb_data_i;
				ack_o_next = 1'b1;
				state_next = STATE_IDLE;
				

			end else begin

				state_next = STATE_WRITE;
				count_next = count_reg + 1;

			end

			data_o_next = 32'b0;

		end


	endcase

end

always @(posedge clk) begin

	if (reset) begin

		state_reg <= STATE_IDLE;
		ack_o_reg <= 1'b0;
		data_o_reg <= 32'b0;
		count_reg <= 2'b0;

	end else begin

		state_reg = state_next;
		count_reg = count_next;
		ack_o_reg = ack_o_next;
		data_o_reg = data_o_next;


	end

end

endmodule