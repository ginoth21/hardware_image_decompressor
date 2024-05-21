// Milestone 1

/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module Milestone2 (
	input  logic		Clock,
   input  logic		Resetn,
	input	 logic		m2_start,
	input  logic   [15:0]   SRAM_read_data,
	
	output logic   [17:0]   SRAM_address,
	output logic [15:0]		SRAM_write_data,
	output logic		SRAM_we_n,
	output logic	m2_end
	
);

Milestone2_state_type M2_state;

logic [6:0] address_a [2:0];
logic [6:0] address_b [2:0];
logic [31:0] write_data_a [2:0];
logic [31:0] write_data_b [2:0];
logic write_enable_a [2:0];
logic write_enable_b [2:0];
logic [31:0] read_data_a [2:0];
logic [31:0] read_data_b [2:0];

// instantiate RAM0 - S'/S matrices
dual_port_RAM0 RAM_inst0 (
	.address_a ( address_a[0] ),
	.address_b ( address_b[0] ),
	.clock ( Clock ),
	.data_a ( write_data_a[0] ),
	.data_b ( write_data_b[0] ),
	.wren_a ( write_enable_a[0] ),
	.wren_b ( write_enable_b[0] ),
	.q_a ( read_data_a[0] ),
	.q_b ( read_data_b[0] )
	);

// instantiate RAM1 - C matrix
dual_port_RAM1 RAM_inst1 (
	.address_a ( address_a[1] ),
	.address_b ( address_b[1] ),
	.clock ( Clock ),
	.data_a ( write_data_a[1] ),
	.data_b ( write_data_b[1] ),
	.wren_a ( write_enable_a[1] ),
	.wren_b ( write_enable_b[1] ),
	.q_a ( read_data_a[1] ),
	.q_b ( read_data_b[1] )
	);

// instantiate RAM2 - T matrix
dual_port_RAM2 RAM_inst2 (
	.address_a ( address_a[2] ),
	.address_b ( address_b[2] ),
	.clock ( Clock ),
	.data_a ( write_data_a[2] ),
	.data_b ( write_data_b[2] ),
	.wren_a ( write_enable_a[2] ),
	.wren_b ( write_enable_b[2] ),
	.q_a ( read_data_a[2] ),
	.q_b ( read_data_b[2] )
	);

//multipliers
logic [31:0] mult1_op1;
logic [31:0] mult1_op2;

logic [31:0] mult2_op1;
logic [31:0] mult2_op2;

logic [31:0] mult3_op1;
logic [31:0] mult3_op2;

logic [31:0] mult4_op1;
logic [31:0] mult4_op2;

//multiplier results
logic [63:0] mult1_result_long;
logic [31:0] mult1_result;
logic [63:0] mult2_result_long;
logic [31:0] mult2_result;
logic [63:0] mult3_result_long;
logic [31:0] mult3_result;
logic [63:0] mult4_result_long;
logic [31:0] mult4_result;

//MAC unit registers
logic [31:0] mac1;
logic [31:0] mac2;
	
// RAM1 is read-only for C matrix coefficients
assign write_data_a[1] = 32'd0;
assign write_data_b[1] = 32'd0;
assign write_enable_a[1] = 1'd0;
assign write_enable_b[1] = 1'd0;

logic [7:0] row_addr;	// concatenate rb and ri so 8 bits
logic [8:0] col_addr;	// concatenate cb and ci so 9 bits
logic [4:0] row_block;	// 30 rows of blocks so 5 bits
logic [5:0] col_block;	// 20 cols of blockks for U/V and 40 cols of blocks for Y so 6 bits 
logic [2:0] row_index;	// 8 rows/columns per matrix so 3 bits
logic [2:0] col_index;
logic [5:0] sample_counter;	// count which element of the matrix we are on
logic [17:0] fetch_address;
logic [4:0] fs_counter; 

assign row_index = sample_counter[5:3];
assign col_index = sample_counter[2:0];

assign row_addr = {row_block, row_index};
assign col_addr = {col_block, col_index};

assign fetch_address = ({2'd0, row_addr, 8'd0} + {4'd0, row_addr, 6'd0}) + {9'd0, col_addr} + Y_OFFSET;

//assign SRAM_address = fetch_address;

logic [15:0] s_buffer;
logic [7:0] s_write_buffer;

//CT variables
logic [5:0] T_ram_counter;
logic [6:0] matrix_counter;
assign address_b[1] = address_a[1] + 7'd4;

//CS variables
logic [4:0] s_ram_counter;

//CT_WS variables
logic [5:0] ct_ws_counter;

//WS variables
logic [4:0] ws_counter;
logic [2:0] row_index_write;
logic [1:0] col_index_write;
logic [7:0] row_addr_write;
logic [7:0] col_addr_write;
logic [17:0] write_address;
logic [4:0] row_block_write;	
logic [5:0] col_block_write;

always_comb begin
	row_index_write = ws_counter[4:2];
	col_index_write = ws_counter[1:0];
	
	row_block_write = row_block;
	col_block_write = col_block;
	if (M2_state == CT_WS) begin
		if (col_block > 6'd0) begin
			col_block_write = col_block_write - 6'd1;
		end
	end
	
	row_addr_write = {row_block_write, row_index_write};
	col_addr_write = {col_block_write, col_index_write};
	
	write_address = ({3'd0, row_addr_write, 7'd0} + {3'd0, row_addr_write, 5'd0}) + {10'd0, col_addr_write};
end

always_comb begin
	SRAM_address = fetch_address;
	if (M2_state == CT_WS || M2_state == WS) begin
		SRAM_address = write_address;
	end
end

logic [7:0] s_clipped_even;
logic [7:0] s_clipped_odd;
logic [7:0] s_clipped_ct_ws;
	
always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn) begin
		M2_state <= M2_IDLE;
		
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		//SRAM_address <= 18'd0;
		
		row_block <= 5'd0;
		col_block <= 6'd0;
		sample_counter <= 6'd0;
		
		s_buffer <= 16'd0;
		s_write_buffer <= 8'd0;
		
		T_ram_counter <= 5'd0;
		s_ram_counter <= 5'd0;
		
		address_a[0] <= 7'd0;
		write_enable_a[0] <= 1'd0;
		write_enable_b[0] <= 1'd0;
		
		matrix_counter <= 7'd0;
		
		fs_counter <= 5'd0;
		ws_counter <= 5'd0;
		ct_ws_counter <= 6'd0;
		
		mac1 <= 32'd0;
		mac2 <= 32'd0;

	end else begin
		case (M2_state)
		M2_IDLE: begin
			if (m2_start) begin
				M2_state <= FS_LI_0;
			end
		end
		
		FS_LI_0: begin
			sample_counter <= sample_counter + 6'd1;
			M2_state <= FS_LI_1;
		end
		
		FS_LI_1: begin
			sample_counter <= sample_counter + 6'd1;
			M2_state <= FS_0;
		end
		
		FS_0: begin
			if (sample_counter[0] == 1'd1) begin
				if (sample_counter == 6'd3) begin
					address_a[0] <= 7'd0;
				end else begin
					address_a[0] <= address_a[0] + 7'd1;
				end
				write_enable_a[0] <= 1'd1;
				write_data_a[0] <= {s_buffer, SRAM_read_data};
			end else begin
				s_buffer <= SRAM_read_data;
			end
			
			sample_counter <= sample_counter + 6'd1;
			
			if (&sample_counter) begin
				M2_state <= FS_LO_0;
			end
		end
		
		FS_LO_0: begin
			s_buffer <= SRAM_read_data;
			M2_state <= FS_LO_1;
		end
		
		FS_LO_1: begin
				address_a[0] <= address_a[0] + 7'd1;
				write_data_a[0] <= {s_buffer, SRAM_read_data};
				M2_state <= FS_LO_2;
		end
		
		FS_LO_2: begin
			write_enable_a[0] <= 1'd0;
			M2_state <= CT_LI_0;
		end
		
		CT_LI_0: begin
			address_a[0] <= 7'd0;
			address_a[1] <= 7'd0;
			matrix_counter <= matrix_counter + 7'd1;
			M2_state <= CT;
		end
		
		CT: begin
			address_a[0] <= {2'd0, matrix_counter[6:4], matrix_counter[1:0]};
			address_a[1] <= {2'd0, matrix_counter[1:0], 1'd0, matrix_counter[3:2]};
			matrix_counter <= matrix_counter + 7'd1;
			
			if (matrix_counter == 7'd127) begin
				M2_state <= CT_LO;
			end
			
			write_enable_a[2] <= 1'd0;
			write_enable_b[2] <= 1'd0;
			
			
			if (matrix_counter[1:0] == 2'b01) begin
				 write_data_a[2] <= {{8{mac1[31]}}, mac1[31:8]};
				 write_data_b[2] <= {{8{mac2[31]}}, mac2[31:8]};
				 
				 if (matrix_counter > 7'd1) begin
					 address_a[2] <= T_ram_counter;
					 T_ram_counter <= T_ram_counter + 5'd2;
					 write_enable_a[2] <= 1'd1;
					 write_enable_b[2] <= 1'd1;
				 end
				 
			end
			
			if (matrix_counter[1:0] == 2'b10) begin
				mac1 <= mult1_result + mult2_result; 
				mac2 <= mult3_result + mult4_result;
			end else begin
				mac1 <= mac1 + mult1_result + mult2_result;
				mac2 <= mac2 + mult3_result + mult4_result;
			end
		end
		
		CT_LO: begin
			mac1 <= mac1 + mult1_result + mult2_result; 
			mac2 <= mac2 + mult3_result + mult4_result;
			M2_state <= CT_LO_1;
		end
		
		CT_LO_1: begin
			address_a[2] <= T_ram_counter;
			T_ram_counter <= T_ram_counter + 5'd2;
			
			write_enable_a[2] <= 1'd1;
			write_enable_b[2] <= 1'd1;
			
			write_data_a[2] <= {{8{mac1[31]}}, mac1[31:8]};
			write_data_b[2] <= {{8{mac2[31]}}, mac2[31:8]};
			
			M2_state <= CT_LO_2;
		end
		
		CT_LO_2: begin
			write_enable_a[2] <= 1'd0;
			write_enable_b[2] <= 1'd0;
			M2_state <= CS_FS_LI_0; 
		end
		
		CS_FS_LI_0: begin
			address_a[1] <= 7'd0;
			address_a[2] <= 7'd0;
			matrix_counter <= matrix_counter + 7'd1;
			
			if (col_block < 6'd39) begin
				col_block <= col_block + 6'd1;
			end else begin
				col_block <= 6'd0;
				row_block <= row_block + 6'd1;
			end
			
			sample_counter <= 6'd0;
			
			M2_state <= CS_FS;
		end
		
		CS_FS: begin
			address_a[1] <= {2'd0, matrix_counter[1:0], 1'd0, matrix_counter[3:2]};
			address_a[2] <= {1'd0, matrix_counter[1:0], 1'd0, matrix_counter[6:4]};
			matrix_counter <= matrix_counter + 7'd1;
			
			if (matrix_counter == 7'd127) begin
				M2_state <= CS_FS_LO_0;
			end
			
			write_enable_a[0] <= 1'd0;
			write_enable_b[0] <= 1'd0;
			
			
			if (matrix_counter[1:0] == 2'b01) begin
				 write_data_a[0] <= mac1;
				 write_data_b[0] <= mac2;
				 
				 if (matrix_counter > 7'd1) begin
					 address_a[0] <= ({1'd0, s_ram_counter[1:0], 1'd0, s_ram_counter[4:2]}) + 7'd32;
					 s_ram_counter <= s_ram_counter + 5'd1;
					 write_enable_a[0] <= 1'd1;
					 write_enable_b[0] <= 1'd1;
				 end
			end
			
			if (matrix_counter[1:0] == 2'b10) begin
				mac1 <= mult1_result + mult2_result; 
				mac2 <= mult3_result + mult4_result;
			end else begin
				mac1 <= mac1 + mult1_result + mult2_result;
				mac2 <= mac2 + mult3_result + mult4_result;
			end
			
			if (matrix_counter[1:0] == 2'b01 || matrix_counter[1:0] == 2'b00) begin
				sample_counter <= sample_counter + 6'd1;
			end
			
			if (matrix_counter[1:0] == 2'b11) begin
				s_buffer <= SRAM_read_data;
			end
			
			if (matrix_counter[1:0] == 2'b00) begin
				write_enable_a[0] <= 1'd1;
				write_data_a[0] <= {s_buffer, SRAM_read_data};
				address_a[0] <= fs_counter;
				fs_counter <= fs_counter + 5'd1;
			end
			
		end
		
		CS_FS_LO_0: begin
			mac1 <= mac1 + mult1_result + mult2_result;
			mac2 <= mac2 + mult3_result + mult4_result;
			
			write_enable_a[0] <= 1'd1;
			write_data_a[0] <= {s_buffer, SRAM_read_data};
			address_a[0] <= fs_counter;
			fs_counter <= fs_counter + 5'd1;
			
			M2_state <= CS_FS_LO_1;
		end
		
		CS_FS_LO_1: begin
			address_a[0] <= ({1'd0, s_ram_counter[1:0], 1'd0, s_ram_counter[4:2]}) + 7'd32;
			s_ram_counter <= s_ram_counter + 5'd1;
			//write_enable_a[0] <= 1'd1;
			write_enable_b[0] <= 1'd1;
			write_data_a[0] <= mac1;
			write_data_b[0] <= mac2;
			M2_state <= CS_FS_LO_2;
		end
		
		CS_FS_LO_2: begin
			write_enable_a[0] <= 1'd0;
			write_enable_b[0] <= 1'd0;
			M2_state <= CT_WS_LI_0;
		end
		
		CT_WS_LI_0: begin
			address_a[0] <= 7'd0;
			address_a[1] <= 7'd0;
			matrix_counter <= matrix_counter + 7'd1;
			
			ct_ws_counter <= 6'd0;
			
			M2_state <= CT_WS;
		end
		
		CT_WS: begin
			address_a[0] <= {2'd0, matrix_counter[6:4], matrix_counter[1:0]};
			address_a[1] <= {2'd0, matrix_counter[1:0], 1'd0, matrix_counter[3:2]};
			matrix_counter <= matrix_counter + 7'd1;
			
			write_enable_a[2] <= 1'd0;
			write_enable_b[2] <= 1'd0;
			
			
			if (matrix_counter[1:0] == 2'b01) begin
				 write_data_a[2] <= {{8{mac1[31]}}, mac1[31:8]};
				 write_data_b[2] <= {{8{mac2[31]}}, mac2[31:8]};
				 
				 if (matrix_counter > 7'd1) begin
					 address_a[2] <= T_ram_counter;
					 T_ram_counter <= T_ram_counter + 5'd2;
					 write_enable_a[2] <= 1'd1;
					 write_enable_b[2] <= 1'd1;
				 end
				 
			end
			
			if (matrix_counter[1:0] == 2'b10) begin
				mac1 <= mult1_result + mult2_result; 
				mac2 <= mult3_result + mult4_result;
			end else begin
				mac1 <= mac1 + mult1_result + mult2_result;
				mac2 <= mac2 + mult3_result + mult4_result;
			end
			
			if (ct_ws_counter < 6'd63) begin
				ct_ws_counter <= ct_ws_counter + 6'd1;
			end
			
			if (matrix_counter[1:0] == 2'b10 || matrix_counter[1:0] == 2'b00) begin
				s_write_buffer <= s_clipped_ct_ws;
			end
			
			if (matrix_counter[1:0] == 2'b11 || (matrix_counter[1:0] == 2'b01 && matrix_counter > 7'd1)) begin
				SRAM_write_data <= {s_write_buffer, s_clipped_ct_ws};
				SRAM_we_n <= 1'b0; //UNCOMMENT WHEN TESTING
				if (matrix_counter > 7'd3) begin
					if (ws_counter < 5'd31) begin
						ws_counter <= ws_counter + 5'd1;
					end else begin
						SRAM_we_n <= 1'b1;
					end
				end
			end
			
			if (matrix_counter == 7'd127) begin
				M2_state <= CT_WS_LO;
				SRAM_we_n <= 1'b1;
			end
		end
		
		CT_WS_LO: begin
			ws_counter <= 5'd0;
			
			mac1 <= mac1 + mult1_result + mult2_result; 
			mac2 <= mac2 + mult3_result + mult4_result;
			M2_state <= CT_WS_LO_1;
		end
		
		CT_WS_LO_1: begin
			address_a[2] <= T_ram_counter;
			
			write_enable_a[2] <= 1'd1;
			write_enable_b[2] <= 1'd1;
			
			write_data_a[2] <= {{8{mac1[31]}}, mac1[31:8]};
			write_data_b[2] <= {{8{mac2[31]}}, mac2[31:8]};
			
			M2_state <= CT_WS_LO_2;
		end
		
		CT_WS_LO_2: begin
			write_enable_a[2] <= 1'd0;
			write_enable_b[2] <= 1'd0;
			
			if (row_block == 6'd29 && col_block == 6'd39) begin
				M2_state <= CS_LI_0;
			end else begin
				M2_state <= CS_FS_LI_0;
			end
			
		end
		
		CS_LI_0: begin
			address_a[1] <= 7'd0;
			address_a[2] <= 7'd0;
			matrix_counter <= matrix_counter + 7'd1;
			M2_state <= CS;
		end
		
		CS: begin
			address_a[1] <= {2'd0, matrix_counter[1:0], 1'd0, matrix_counter[3:2]};
			address_a[2] <= {1'd0, matrix_counter[1:0], 1'd0, matrix_counter[6:4]};
			matrix_counter <= matrix_counter + 7'd1;
			
			if (matrix_counter == 7'd127) begin
				M2_state <= CS_LO;
			end
			
			write_enable_a[0] <= 1'd0;
			write_enable_b[0] <= 1'd0;
			
			
			if (matrix_counter[1:0] == 2'b01) begin
				 write_data_a[0] <= mac1;
				 write_data_b[0] <= mac2;
				 
				 if (matrix_counter > 7'd1) begin
					 address_a[0] <= ({1'd0, s_ram_counter[1:0], 1'd0, s_ram_counter[4:2]}) + 7'd32;
					 s_ram_counter <= s_ram_counter + 5'd1;
					 write_enable_a[0] <= 1'd1;
					 write_enable_b[0] <= 1'd1;
				 end
			end
			
			if (matrix_counter[1:0] == 2'b10) begin
				mac1 <= mult1_result + mult2_result; 
				mac2 <= mult3_result + mult4_result;
			end else begin
				mac1 <= mac1 + mult1_result + mult2_result;
				mac2 <= mac2 + mult3_result + mult4_result;
			end
			
		end
		
		CS_LO: begin
			mac1 <= mac1 + mult1_result + mult2_result;
			mac2 <= mac2 + mult3_result + mult4_result;
			M2_state <= CS_LO_1;
		end
		
		CS_LO_1: begin
			address_a[0] <= ({1'd0, s_ram_counter[1:0], 1'd0, s_ram_counter[4:2]}) + 7'd32;
			write_enable_a[0] <= 1'd1;
			write_enable_b[0] <= 1'd1;
			write_data_a[0] <= mac1;
			write_data_b[0] <= mac2;
			M2_state <= CS_LO_2;
		end
		
		CS_LO_2: begin
			write_enable_a[0] <= 1'd0;
			write_enable_b[0] <= 1'd0;
			M2_state <= WS_LI_0;
		end
		
		WS_LI_0: begin
			address_a[0] <= 7'd32;
			M2_state <= WS_LI_1;
		end
		
		WS_LI_1: begin
			address_a[0] <= address_a[0] + 7'd2;
			M2_state <= WS_LI_2;
		end
		
		WS_LI_2: begin
			address_a[0] <= address_a[0] + 7'd2;
			
			SRAM_we_n <= 1'b0;		//UNCOMMENT THIS WHEN TESTING
			SRAM_write_data <= {s_clipped_even, s_clipped_odd};
			
			M2_state <= WS;
		end
		
		
		WS: begin
			if (ws_counter < 5'd29) begin
				address_a[0] <= address_a[0] + 7'd2;
			end
			
			ws_counter <= ws_counter + 5'd1;
			
			SRAM_write_data <= {s_clipped_even, s_clipped_odd};
			
			if (ws_counter == 5'd31) begin
				M2_state <= WS_LO;
				SRAM_we_n <= 1'b1;
			end
		end
		
		WS_LO: begin
			M2_state <= FINISH_M2;
		end
		
		FINISH_M2: begin
			m2_end <= 1'd1;
			M2_state <= M2_DELAY;
		end
		
		M2_DELAY: begin		//delay state needed since it takes extra clock cycle to turn off m2_start
			M2_state <= M2_IDLE;
		end

		endcase

	end
end

always_comb begin
	address_b[2] = 7'd0;
	if (M2_state == CT || M2_state == CT_LO || M2_state == CT_LO_1 || M2_state == CT_LO_2 || M2_state == CT_WS || M2_state == CT_WS_LO || M2_state == CT_WS_LO_1 || M2_state == CT_WS_LO_2) begin
		address_b[2] = address_a[2] + 7'd1;
	end
	if (M2_state == CS || M2_state == CS_LO || M2_state == CS_FS || M2_state == CS_FS_LO_0) begin	// T addresses are 8 addresses apart when reading them to calculate S
		address_b[2] = address_a[2] + 7'd8;
	end
end

always_comb begin
	address_b[0] = 7'd0;
	if (M2_state == WS_LI_0 || M2_state == WS_LI_1 || M2_state == WS_LI_2 || M2_state == WS || M2_state == WS_LO) begin
		address_b[0] = address_a[0] + 7'd1;
	end
	if (M2_state == CS || M2_state == CS_LO || M2_state == CS_LO_1 || M2_state == CS_LO_2 || M2_state == CS_FS || M2_state == CS_FS_LO_0 || M2_state == CS_FS_LO_1 || M2_state == CS_FS_LO_2) begin
		address_b[0] = address_a[0] + 7'd8;
	end
	if (M2_state == CT_WS || M2_state == CT_WS_LO || M2_state == CT_WS_LO_1 || M2_state == CT_WS_LO_2) begin
		address_b[0] = ct_ws_counter + 7'd32;
	end
end


always_comb begin
	mult1_op1 = 32'd0;
	mult1_op2 = 32'd0;
	
	mult2_op1 = 32'd0;
	mult2_op2 = 32'd0;
	
	mult3_op1 = 32'd0;
	mult3_op2 = 32'd0;
	
	mult4_op1 = 32'd0;
	mult4_op2 = 32'd0;

	if (M2_state == CT || M2_state == CT_LO || M2_state == CT_LO_1 || M2_state == CT_WS || M2_state == CT_WS_LO || M2_state == CT_WS_LO_1) begin
		mult1_op1 = {{16{read_data_a[0][31]}}, read_data_a[0][31:16]};
		mult1_op2 = {{16{read_data_a[1][31]}}, read_data_a[1][31:16]};
		
		mult2_op1 = {{16{read_data_a[0][15]}}, read_data_a[0][15:0]}; 
		mult2_op2 = {{16{read_data_b[1][31]}}, read_data_b[1][31:16]};
		
		mult3_op1 = {{16{read_data_a[0][31]}}, read_data_a[0][31:16]};
		mult3_op2 = {{16{read_data_a[1][15]}}, read_data_a[1][15:0]};
		
		mult4_op1 = {{16{read_data_a[0][15]}}, read_data_a[0][15:0]};
		mult4_op2 = {{16{read_data_b[1][15]}}, read_data_b[1][15:0]};
	end
	
	if (M2_state == CS || M2_state == CS_LO || M2_state == CS_LO_1 || M2_state == CS_FS || M2_state == CS_FS_LO_0 || M2_state == CS_FS_LO_1) begin
		mult1_op1 = {{16{read_data_a[1][31]}}, read_data_a[1][31:16]};
		mult1_op2 = read_data_a[2];
		
		mult2_op1 = {{16{read_data_b[1][31]}}, read_data_b[1][31:16]};
		mult2_op2 = read_data_b[2];
		
		mult3_op1 = {{16{read_data_a[1][15]}}, read_data_a[1][15:0]};
		mult3_op2 = read_data_a[2];
		
		mult4_op1 = {{16{read_data_b[1][15]}}, read_data_b[1][15:0]};
		mult4_op2 = read_data_b[2];
	end
end

assign mult1_result_long = mult1_op1 * mult1_op2;
assign mult1_result = mult1_result_long[31:0];

assign mult2_result_long = mult2_op1 * mult2_op2;
assign mult2_result = mult2_result_long[31:0];

assign mult3_result_long = mult3_op1 * mult3_op2;
assign mult3_result = mult3_result_long[31:0];

assign mult4_result_long = mult4_op1 * mult4_op2;
assign mult4_result = mult4_result_long[31:0];

//clipping for S
always_comb begin
	s_clipped_even = 8'd0;
	s_clipped_odd = 8'd0;
	if (M2_state == WS_LI_2 || M2_state == WS) begin
		s_clipped_even = read_data_a[0][23:16];
		s_clipped_odd = read_data_b[0][23:16];
	end
	
	s_clipped_ct_ws = 8'd0;
	if (M2_state == CT_WS) begin
		s_clipped_ct_ws = read_data_b[0][23:16];
	end
end

endmodule 