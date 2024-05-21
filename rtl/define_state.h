`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [2:0] {
	S_IDLE,
	S_UART_RX,
	S_M2,
	S_M1
} top_state_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

typedef enum logic [5:0] {
	M1_IDLE,
	LI_0,
	LI_1,
	LI_2,
	LI_3,
	LI_4,
	LI_5,
	LI_6,
	LI_7,
	LI_8,
	LI_9,
	LI_10,
	LI_11,
	LI_12,
	LI_13,
	CC_0,
	CC_1,
	CC_2,
	CC_3,
	CC_4,
	CC_5,
	CC_6,
	LO_0,
	LO_1,
	LO_2,
	LO_3,
	LO_4,
	LO_5,
	LO_6,
	LO_7,
	LO_8,
	FINISH_M1,
	M1_DELAY
} Milestone1_state_type;

typedef enum logic [5:0] {
	M2_IDLE,
	FS_LI_0,
	FS_LI_1,
	FS_0,
	FS_LO_0,
	FS_LO_1,
	FS_LO_2,
	CT_LI_0,
	CT,
	CT_LO,
	CT_LO_1,
	CT_LO_2,
	CS_FS_LI_0,
	CS_FS,
	CS_FS_LO_0,
	CS_FS_LO_1,
	CS_FS_LO_2,
	CT_WS_LI_0,
	CT_WS,
	CT_WS_LO,
	CT_WS_LO_1,
	CT_WS_LO_2,
	CS_LI_0,
	CS,
	CS_LO,
	CS_LO_1,
	CS_LO_2,
	WS_LI_0,
	WS_LI_1,
	WS_LI_2,
	WS,
	WS_LO,
	FINISH_M2,
	M2_DELAY
} Milestone2_state_type;

parameter
	Y_OFFSET = 76800,
	U_OFFSET = 153600,
	V_OFFSET = 192000;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
