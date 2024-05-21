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
module Milestone1 (
	input  logic		Clock,
   input  logic		Resetn,
	input	 logic		m1_start,
	input  logic   [15:0]   SRAM_read_data,
	
	output logic   [17:0]   SRAM_address,
	output logic [15:0]		SRAM_write_data,
	output logic		SRAM_we_n,
	output logic	m1_end
	
);

Milestone1_state_type M1_state;

logic [17:0] y_address; //register to store address of y segment
logic [17:0] u_address; //register to store address of u segment
logic [17:0] v_address; //register to store address of v segment
logic [17:0] RGB_address; //register to store address of RGB segment

logic [15:0] Y; //register to store Y values read from memory

//registers needed for buffers
logic [7:0] u_even_buffer;
logic [7:0] u_odd_buffer;
logic [7:0] v_odd_buffer;

//registers needed to store RGB values
logic [31:0] R_even;
logic [31:0] G_even;
logic [31:0] B_even;
logic [31:0] R_odd;
logic [31:0] G_odd;
logic [31:0] B_odd;

//Registers for U' and V' values
logic [31:0] u_prime;
logic [31:0] v_prime;
logic [31:0] u_prime_buffer;
logic [31:0] v_prime_buffer;

//multiplier 1
logic [8:0] mult1_op1; //9 bits for Y-16, U'even-128, V'even-128 - need sign extension after the subtraction
logic [31:0] mult1_op1_ext;
logic [31:0] mult1_op2;

//multiplier 2
logic [31:0] mult2_op1;
logic [31:0] mult2_op2;

//multiplier 3
logic [31:0] mult3_op1;

//multiplier 4
logic [31:0] mult4_op1;
logic [8:0] mult34_op2;	//9 bits to store 21, -52, 159 for both U and V multiplications
logic [31:0] mult34_op2_ext;	//sign extension to 32 bits

//U shift register
logic [7:0] u_plus_5;
logic [7:0] u_plus_3;
logic [7:0] u_plus_1;
logic [7:0] u_minus_1;
logic [7:0] u_minus_3;
logic [7:0] u_minus_5;

//V shift register
logic [7:0] v_plus_5;
logic [7:0] v_plus_3;
logic [7:0] v_plus_1;
logic [7:0] v_minus_1;
logic [7:0] v_minus_3;
logic [7:0] v_minus_5;

//multiplier results
logic [63:0] mult1_result_long;
logic [31:0] mult1_result;
logic [63:0] mult2_result_long;
logic [31:0] mult2_result;
logic [63:0] mult3_result_long;
logic [31:0] mult3_result;
logic [63:0] mult4_result_long;
logic [31:0] mult4_result;

logic read_uv;	//flag to determine whether U and V should be read in the common case

logic [7:0] cc_counter; //register to count how many times the common case was iterated - to determine whether lead out should be triggered
logic [7:0] row_counter; //register to count how many rows have been done - determines whether to go into common case or to finish milestone 1

//clipped 8-bit values of RGB values
logic [7:0] R_even_clipped;
logic [7:0] G_even_clipped;
logic [7:0] B_even_clipped;
logic [7:0] R_odd_clipped;
logic [7:0] G_odd_clipped;
logic [7:0] B_odd_clipped;


always_ff @(posedge Clock or negedge Resetn) begin
	if(!Resetn) begin
		M1_state <= M1_IDLE;
		
		y_address <= 18'd0;
		u_address <= 18'd38400;
		v_address <= 18'd57600;
		RGB_address <= 18'd146944;
		
		Y <= 16'd0;
		
		u_even_buffer <= 8'd0;
		u_odd_buffer <= 8'd0;
		v_odd_buffer <= 8'd0;
		
		R_even <= 32'd0;
		G_even <= 32'd0;
		B_even <= 32'd0;
		R_odd <= 32'd0;
		G_odd <= 32'd0;
		B_odd <= 32'd0;
		
		u_prime <= 32'd0;
		v_prime <= 32'd0;
		u_prime_buffer <= 32'd0;
		v_prime_buffer <= 32'd0;
		
		mult1_op1 <= 9'd0;
		mult1_op2 <= 32'd0;
		mult2_op1 <= 32'd0;
		mult2_op2 <= 32'd0;
		
		mult34_op2 <= 9'd0;	//21, -52, or 159
		
		u_plus_5 <= 8'd0;
		u_plus_3 <= 8'd0;
		u_plus_1 <= 8'd0;
		u_minus_1 <= 8'd0;
		u_minus_3 <= 8'd0;
		u_minus_5 <= 8'd0;
		
		v_plus_5 <= 8'd0;
		v_plus_3 <= 8'd0;
		v_plus_1 <= 8'd0;
		v_minus_1 <= 8'd0; 
		v_minus_3 <= 8'd0;
		v_minus_5 <= 8'd0;
		
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
		
		read_uv <= 1'd0;
		
		cc_counter <= 8'd0;
		row_counter <= 8'd0;
		
		m1_end <= 1'd0;
	
	end else begin
		case (M1_state)
		M1_IDLE: begin
			if (m1_start) begin
				M1_state <= LI_0;
			end
		end
		
		LI_0: begin
			SRAM_address <= u_address;
			u_address <= u_address + 18'd1;
			
			cc_counter <= 8'd0;
			
			M1_state <= LI_1;
		end
		
		LI_1: begin
			SRAM_address <= v_address;
			v_address <= v_address + 18'd1;
			
			M1_state <= LI_2;
		end
		
		LI_2: begin
			SRAM_address <= u_address;
			u_address <= u_address + 18'd1;
			
			M1_state <= LI_3;
		end
		
		LI_3: begin
			SRAM_address <= v_address;
			v_address <= v_address + 18'd1;
			
			u_even_buffer <= SRAM_read_data[15:8];
			u_odd_buffer <= SRAM_read_data[7:0];
			
			M1_state <= LI_4;
		end
		
		LI_4: begin
			u_plus_5 <= u_even_buffer;
			u_plus_3 <= u_even_buffer;
			u_plus_1 <= u_even_buffer;
			
			v_plus_5 <= SRAM_read_data[15:8];
			v_plus_3 <= SRAM_read_data[15:8];
			v_plus_1 <= SRAM_read_data[15:8];
		
			v_odd_buffer <= SRAM_read_data[7:0];
			
			M1_state <= LI_5;
		end
		
		LI_5: begin
			u_plus_5 <= u_odd_buffer;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			
			v_plus_5 <= v_odd_buffer;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
		
			u_even_buffer <= SRAM_read_data[15:8];
			u_odd_buffer <= SRAM_read_data[7:0];
			
			M1_state <= LI_6;
		end
		
		LI_6: begin
			u_plus_5 <= u_even_buffer;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			
			v_plus_5 <= SRAM_read_data[15:8];
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			
			v_odd_buffer <= SRAM_read_data[7:0];
			
			M1_state <= LI_7;
		end
		
		LI_7: begin
			u_plus_5 <= u_odd_buffer;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_odd_buffer;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= 32'd128;	//U' = V' = 128
			v_prime <= 32'd128;
			
			mult34_op2 <= 9'd21;
			
			M1_state <= LI_8;
		end
		
		LI_8: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= -9'd52;
			
			M1_state <= LI_9;
		end
		
		LI_9: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd159;
			
			SRAM_address <= y_address;
			y_address <= y_address + 18'd1;
			
			M1_state <= LI_10;
		end
		
		LI_10: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd159;
		
			SRAM_address <= u_address;
			u_address <= u_address + 18'd1;
			
			M1_state <= LI_11;
		end
		
		LI_11: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= -9'd52;
		
			SRAM_address <= v_address;
			v_address <= v_address + 18'd1;
			
			M1_state <= LI_12;
		end
		
		LI_12: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1 - 52U2
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd21;
			
			Y <= SRAM_read_data;
			
			M1_state <= LI_13;
		end
		
		LI_13: begin
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= (u_prime + mult3_result) >>> 8;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1 - 52U2 + 21U3
			v_prime <= (v_prime + mult4_result) >>> 8;
			
			u_even_buffer <= SRAM_read_data[15:8];
			u_odd_buffer <= SRAM_read_data[7:0];
			
			read_uv <= 1'd0;
			
			M1_state <= CC_0;
		end
		
		//NOTE - Y VALUES SHOULD BE Y-16 AND U AND V VALUES SHOULD BE U-128 AND V-128
		CC_0: begin
			mult1_op1 <= {1'b0, Y[15:8]} - 9'd16;
			mult1_op2 <= 32'd76284;
			
			if (read_uv) begin
				u_plus_5 <= u_odd_buffer;
			end else begin
				if (cc_counter > 8'd154) begin
					u_plus_5 <= u_odd_buffer;
				end else begin
					u_plus_5 <= u_even_buffer;
				end
			end
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			if (read_uv) begin
				v_plus_5 <= v_odd_buffer;
			end else begin
				if (cc_counter > 8'd154) begin
					v_plus_5 <= v_odd_buffer;
				end else begin
					v_plus_5 <= SRAM_read_data[15:8];
				end
			end
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= 32'd128;	//U' = V' = 128
			v_prime <= 32'd128;
			
			mult34_op2 <= 9'd21;
			
			u_prime_buffer <= u_prime;
			v_prime_buffer <= v_prime;
			
			if (cc_counter > 0) begin
				SRAM_address <= RGB_address;
				RGB_address <= RGB_address + 18'd1;
			end
			
			SRAM_write_data <= {G_odd_clipped, B_odd_clipped};	//NEED TO DO CLIPPING HERE
			
			if (~read_uv && (cc_counter < 8'd155)) begin
				v_odd_buffer <= SRAM_read_data[7:0];
			end
			
			M1_state <= CC_1;
			
		end
		
		CC_1: begin
			SRAM_we_n <= 1'b1;
			
			R_even <= mult1_result;
			G_even <= mult1_result;
			B_even <= mult1_result;
			
			mult1_op1 <= {1'b0, v_minus_3} - 9'd128;
			mult1_op2 <= 32'd104595;
			
			mult2_op1 <= Y[7:0] - 8'd16;
			mult2_op2 <= 32'd76284;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0
			v_prime <= v_prime + mult4_result;
			
			
			mult34_op2 <= -9'd52;
			
			M1_state <= CC_2;
		end
		
		CC_2: begin
			SRAM_address <= y_address;
			y_address <= y_address + 18'd1;
			
			R_even <= R_even + mult1_result;

			mult1_op1 <= {1'b0, u_minus_5} - 9'd128;
			mult1_op2 <= -32'd25624;
			
			R_odd <= mult2_result;
			G_odd <= mult2_result;
			B_odd <= mult2_result;
			
			mult2_op1 <= v_prime_buffer - 8'd128;
			mult2_op2 <= 32'd104595;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd159;
			
			M1_state <= CC_3;
		end
		
		CC_3: begin
			G_even <= G_even + mult1_result;
			
			mult1_op1 <= {1'b0, v_plus_5} - 9'd128;
			mult1_op2 <= -32'd53281;
			
			R_odd <= R_odd + mult2_result;
			
			mult2_op1 <= u_prime_buffer - 8'd128;
			mult2_op2 <= -32'd25624;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd159;
			
			if (read_uv) begin
				if (cc_counter < 8'd154) begin		//stop reading at this point to start going to lead out - NEED TO FIND WAY TO KEEP GOING FOR 4 MORE CC ITERATIONS
				//NEED TO CHANGE THIS CONDITION SINCE DIFFERENCE BETWEEN ADDRESSES WONT ALWAYS BE 80
					SRAM_address <= u_address;
					u_address <= u_address + 18'd1;
				end
			end
			
			M1_state <= CC_4;
		end
		
		CC_4: begin
			G_even <= G_even + mult1_result;
			
			mult1_op1 <= {1'b0, u_plus_3} - 9'd128;
			mult1_op2 <= 32'd132251;
			
			G_odd <= G_odd + mult2_result;
			
			mult2_op1 <= v_prime_buffer - 8'd128;
			mult2_op2 <= -32'd53281;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= -9'd52;
			
			if (read_uv) begin
				if (cc_counter < 8'd154) begin	//stop reading at this point to start going to lead out - NEED TO FIND WAY TO KEEP GOING FOR 4 MORE CC ITERATIONS
				//NEED TO CHANGE THIS CONDITION SINCE DIFFERENCE BETWEEN ADDRESSES WONT ALWAYS BE 80
					SRAM_address <= v_address;
					v_address <= v_address + 18'd1;
				end
			end
			
			M1_state <= CC_5;
		end
		
		CC_5: begin
			SRAM_we_n <= 1'b0;
			
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {R_even_clipped, G_even_clipped};	//NEED TO DO CLIPPING HERE
			
			B_even <= B_even + mult1_result;
			
			G_odd <= G_odd + mult2_result;
			
			mult2_op1 <= u_prime_buffer - 8'd128;
			mult2_op2 <= 32'd132251;
			
			Y <= SRAM_read_data;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= u_prime + mult3_result;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1 - 52U2
			v_prime <= v_prime + mult4_result;
			
			mult34_op2 <= 9'd21;
			
			M1_state <= CC_6; 
		end
		
		CC_6: begin
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {B_even_clipped, R_odd_clipped};	//NEED TO DO CLIPPING HERE
			
			B_odd <= B_odd + mult2_result;
			
			u_plus_5 <= u_minus_5;
			u_plus_3 <= u_plus_5;
			u_plus_1 <= u_plus_3;
			u_minus_1 <= u_plus_1;
			u_minus_3 <= u_minus_1;
			u_minus_5 <= u_minus_3;
			
			v_plus_5 <= v_minus_5;
			v_plus_3 <= v_plus_5;
			v_plus_1 <= v_plus_3;
			v_minus_1 <= v_plus_1;
			v_minus_3 <= v_minus_1;
			v_minus_5 <= v_minus_3;
			
			u_prime <= (u_prime + mult3_result) >>> 8;	//U' = 128 + 21U0 - 52U0 + 159U0 + 159U1 - 52U2 + 21U3
			v_prime <= (v_prime + mult4_result) >>> 8;
			
			if (read_uv && (cc_counter < 8'd154)) begin
				u_even_buffer <= SRAM_read_data[15:8];
				u_odd_buffer <= SRAM_read_data[7:0];
			end
			
			read_uv <= ~read_uv; //if U and V was read in this common case iteration don't read it for the next one
			
			if (cc_counter < 8'd158) begin
				M1_state <= CC_0;
			end else begin
				M1_state <= LO_0;
			end
			
			cc_counter <= cc_counter + 8'd1;
		end
		
		LO_0: begin
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {G_odd_clipped, B_odd_clipped};	//NEED TO DO CLIPPING HERE
			
			mult1_op1 <= {1'b0, Y[15:8]} - 9'd16;
			mult1_op2 <= 32'd76284;
			
			u_prime_buffer <= u_prime;
			v_prime_buffer <= v_prime;
			
			M1_state <= LO_1;
		end
		
		LO_1: begin
			SRAM_we_n <= 1'b1;
			
			R_even <= mult1_result;
			G_even <= mult1_result;
			B_even <= mult1_result;
			
			mult1_op1 <= {1'b0, v_minus_1} - 9'd128;
			mult1_op2 <= 32'd104595;
			
			mult2_op1 <= Y[7:0] - 8'd16;
			mult2_op2 <= 32'd76284;
			
			M1_state <= LO_2;
		end
		
		LO_2: begin
			R_even <= R_even + mult1_result;
			
			mult1_op1 <= {1'b0, u_minus_1} - 9'd128;
			mult1_op2 <= -32'd25624;
			
			R_odd <= mult2_result;
			G_odd <= mult2_result;
			B_odd <= mult2_result;
			
			mult2_op1 <= v_prime_buffer - 8'd128;
			mult2_op2 <= 32'd104595;
			
			M1_state <= LO_3;
		end
		
		LO_3: begin
			G_even <= G_even + mult1_result;
			
			mult1_op1 <= {1'b0, v_minus_1} - 9'd128;
			mult1_op2 <= -32'd53281;
			
			R_odd <= R_odd + mult2_result;
			
			mult2_op1 <= u_prime_buffer - 8'd128;
			mult2_op2 <= -32'd25624;
			
			M1_state <= LO_4;
		end
		
		LO_4: begin
			G_even <= G_even + mult1_result;
			
			mult1_op1 <= {1'b0, u_minus_1} - 9'd128;
			mult1_op2 <= 32'd132251;
			
			G_odd <= G_odd + mult2_result;
			
			mult2_op1 <= v_prime_buffer - 8'd128;
			mult2_op2 <= -32'd53281;
			
			M1_state <= LO_5;
		end
		
		LO_5: begin
			SRAM_we_n <= 1'b0;
			
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {R_even_clipped, G_even_clipped};	//NEED TO DO CLIPPING HERE
			
			B_even <= B_even + mult1_result;
			
			G_odd <= G_odd + mult2_result;
			
			mult2_op1 <= u_prime_buffer - 8'd128;
			mult2_op2 <= 32'd132251;
			
			M1_state <= LO_6;
		end
		
		LO_6: begin
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {B_even_clipped, R_odd_clipped};	//NEED TO DO CLIPPING HERE
			
			B_odd <= B_odd + mult2_result;
			
			M1_state <= LO_7;
		end
		
		LO_7: begin
			SRAM_address <= RGB_address;
			RGB_address <= RGB_address + 18'd1;
			
			SRAM_write_data <= {G_odd_clipped, B_odd_clipped};	//NEED TO DO CLIPPING HERE
			
			M1_state <= LO_8;
		end
		
		LO_8: begin
			SRAM_we_n <= 1'b1;
			
			if (row_counter < 8'd239) begin
				M1_state <= LI_0;
			end else begin
				M1_state <= FINISH_M1;
			end
			
			row_counter <= row_counter + 8'd1;
		end
		
		FINISH_M1: begin
			m1_end <= 1'd1;
			M1_state <= M1_DELAY;
		end
		
		M1_DELAY: begin		//delay state needed since it takes extra clock cycle to turn off m1_start
			M1_state <= M1_IDLE;
		end
		
		
		endcase
	
	end
end


//multiplier 1 - RGB even multiplications
assign mult1_op1_ext = {{23{mult1_op1[8]}},mult1_op1};
assign mult1_result_long = mult1_op1_ext * mult1_op2;
assign mult1_result = mult1_result_long[31:0];

//multiplier 2 - RGB odd multiplications
assign mult2_result_long = mult2_op1 * mult2_op2;
assign mult2_result = mult2_result_long[31:0];

//multiplier 3 - U' multiplications
assign mult3_op1 = {24'd0,u_minus_5};
assign mult34_op2_ext = {{23{mult34_op2[8]}},mult34_op2};

assign mult3_result_long = mult3_op1 * mult34_op2_ext;
assign mult3_result = mult3_result_long[31:0];

//multiplier 4 - V' multiplications
assign mult4_op1 = {24'd0,v_minus_5};

assign mult4_result_long = mult4_op1 * mult34_op2_ext;
assign mult4_result = mult4_result_long[31:0];

//clipping for RGB values to 8 bits

always_comb begin
	if (R_even[31]) begin
		R_even_clipped = 8'd0;
	end else begin
		if (|R_even[30:24]) begin
			R_even_clipped = 8'd255;
		end else begin
			R_even_clipped = R_even[23:16];
		end
	end
end

always_comb begin
	if (G_even[31]) begin
		G_even_clipped = 8'd0;
	end else begin
		if (|G_even[30:24]) begin
			G_even_clipped = 8'd255;
		end else begin
			G_even_clipped = G_even[23:16];
		end
	end
end

always_comb begin
	if (B_even[31]) begin
		B_even_clipped = 8'd0;
	end else begin
		if (|B_even[30:24]) begin
			B_even_clipped = 8'd255;
		end else begin
			B_even_clipped = B_even[23:16];
		end
	end
end

always_comb begin
	if (R_odd[31]) begin
		R_odd_clipped = 8'd0;
	end else begin
		if (|R_odd[30:24]) begin
			R_odd_clipped = 8'd255;
		end else begin
			R_odd_clipped = R_odd[23:16];
		end
	end
end

always_comb begin
	if (G_odd[31]) begin
		G_odd_clipped = 8'd0;
	end else begin
		if (|G_odd[30:24]) begin
			G_odd_clipped = 8'd255;
		end else begin
			G_odd_clipped = G_odd[23:16];
		end
	end
end

always_comb begin
	if (B_odd[31]) begin
		B_odd_clipped = 8'd0;
	end else begin
		if (|B_odd[30:24]) begin
			B_odd_clipped = 8'd255;
		end else begin
			B_odd_clipped = B_odd[23:16];
		end
	end
end



endmodule 