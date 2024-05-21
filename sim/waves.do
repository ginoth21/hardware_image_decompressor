# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {VGA signals}
add wave UUT/VGA_unit/VGA_SRAM_state
add wave -uns UUT/VGA_unit/SRAM_address
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

add wave -divider -height 10 {Milestone 2 signals}
add wave -bin UUT/m2_start
add wave -bin UUT/m2_unit/m2_end
add wave -uns UUT/m2_unit/row_block
add wave -uns UUT/m2_unit/col_block
add wave UUT/m2_unit/M2_state
add wave -uns UUT/m2_unit/SRAM_address
add wave -hex UUT/SRAM_read_data
add wave -uns UUT/m2_unit/SRAM_we_n
add wave -hex UUT/SRAM_write_data
# add wave -hex UUT/m2_unit/s_clipped_even
# add wave -hex UUT/m2_unit/s_clipped_odd
add wave -bin UUT/m2_unit/sample_counter
add wave -hex UUT/m2_unit/s_buffer
add wave -hex UUT/m2_unit/s_write_buffer
add wave -uns UUT/m2_unit/matrix_counter
add wave -uns UUT/m2_unit/ct_ws_counter

add wave -divider -height 10 {DP-RAM0 - S/S'}
add wave -uns {UUT/m2_unit/address_a[0]}
add wave -hex {UUT/m2_unit/write_data_a[0]}
add wave -hex {UUT/m2_unit/write_enable_a[0]}
add wave -hex {UUT/m2_unit/read_data_a[0]}
add wave -uns {UUT/m2_unit/address_b[0]}
add wave -hex {UUT/m2_unit/write_data_b[0]}
add wave -hex {UUT/m2_unit/write_enable_b[0]}
add wave -hex {UUT/m2_unit/read_data_b[0]}

add wave -divider -height 10 {DP-RAM1 - C}
add wave -uns {UUT/m2_unit/address_a[1]}
add wave -hex {UUT/m2_unit/write_data_a[1]}
add wave -hex {UUT/m2_unit/write_enable_a[1]}
add wave -hex {UUT/m2_unit/read_data_a[1]}
add wave -uns {UUT/m2_unit/address_b[1]}
add wave -hex {UUT/m2_unit/write_data_b[1]}
add wave -hex {UUT/m2_unit/write_enable_b[1]}
add wave -hex {UUT/m2_unit/read_data_b[1]}

add wave -divider -height 10 {DP-RAM2 - T}
add wave -uns {UUT/m2_unit/address_a[2]}
add wave -hex {UUT/m2_unit/write_data_a[2]}
add wave -hex {UUT/m2_unit/write_enable_a[2]}
add wave -hex {UUT/m2_unit/read_data_a[2]}
add wave -uns {UUT/m2_unit/address_b[2]}
add wave -hex {UUT/m2_unit/write_data_b[2]}
add wave -hex {UUT/m2_unit/write_enable_b[2]}
add wave -hex {UUT/m2_unit/read_data_b[2]}

add wave -divider -height 10 {M2 Multipliers}
add wave -hex UUT/m2_unit/mult1_op1
add wave -hex UUT/m2_unit/mult1_op2
add wave -hex UUT/m2_unit/mult1_result
add wave -hex UUT/m2_unit/mult2_op1
add wave -hex UUT/m2_unit/mult2_op2
add wave -hex UUT/m2_unit/mult2_result
add wave -hex UUT/m2_unit/mac1
add wave -hex UUT/m2_unit/mult3_op1
add wave -hex UUT/m2_unit/mult3_op2
add wave -hex UUT/m2_unit/mult3_result
add wave -hex UUT/m2_unit/mult4_op1
add wave -hex UUT/m2_unit/mult4_op2
add wave -hex UUT/m2_unit/mult4_result
add wave -hex UUT/m2_unit/mac2

add wave -uns UUT/m2_unit/ws_counter

add wave -divider -height 10 {Milestone 1 signals}
add wave -bin UUT/m1_start
add wave -bin UUT/m1_unit/m1_end
add wave UUT/m1_unit/M1_state
add wave -uns UUT/m1_unit/cc_counter
add wave -uns UUT/m1_unit/row_counter
add wave -uns UUT/m1_unit/SRAM_address
add wave -uns UUT/m1_unit/SRAM_we_n
add wave -hex UUT/SRAM_write_data

add wave -divider -height 10 {Buffers}
add wave -hex UUT/m1_unit/Y
add wave -hex UUT/m1_unit/u_even_buffer
add wave -hex UUT/m1_unit/u_odd_buffer
add wave -hex UUT/m1_unit/v_odd_buffer

add wave -divider -height 10 {U Shift Register}
add wave -bin UUT/m1_unit/read_uv
add wave -hex UUT/m1_unit/u_plus_5
add wave -hex UUT/m1_unit/u_plus_3
add wave -hex UUT/m1_unit/u_plus_1
add wave -hex UUT/m1_unit/u_minus_1
add wave -hex UUT/m1_unit/u_minus_3
add wave -hex UUT/m1_unit/u_minus_5

add wave -divider -height 10 {V Shift Register}
add wave -hex UUT/m1_unit/v_plus_5
add wave -hex UUT/m1_unit/v_plus_3
add wave -hex UUT/m1_unit/v_plus_1
add wave -hex UUT/m1_unit/v_minus_1
add wave -hex UUT/m1_unit/v_minus_3
add wave -hex UUT/m1_unit/v_minus_5

add wave -divider -height 10 {U' V' Registers}
add wave -hex UUT/m1_unit/mult1_result
add wave -hex UUT/m1_unit/mult1_op1_ext
add wave -hex UUT/m1_unit/mult1_op2
add wave -hex UUT/m1_unit/mult2_result
add wave -hex UUT/m1_unit/mult2_op1
add wave -hex UUT/m1_unit/mult2_op2
add wave UUT/m1_unit/M1_state

add wave -divider -height 10 {U' V' Registers}
add wave -hex UUT/m1_unit/u_prime
add wave -hex UUT/m1_unit/v_prime
add wave -hex UUT/m1_unit/u_prime_buffer
add wave -hex UUT/m1_unit/v_prime_buffer

add wave -divider -height 10 {RGB MACs}
add wave -hex UUT/m1_unit/R_even
add wave -hex UUT/m1_unit/G_even
add wave -hex UUT/m1_unit/B_even
add wave -hex UUT/m1_unit/R_odd
add wave -hex UUT/m1_unit/G_odd
add wave -hex UUT/m1_unit/B_odd