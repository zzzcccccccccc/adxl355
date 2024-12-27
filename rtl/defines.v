//read
`define DEVID_AD_REG      7'h00
`define DEVID_MST_REG     7'h01
`define PARTID_REG        7'h02
`define REVID_REG         7'h03
`define STATUS_REG        7'h04
`define FIFO_ENTRIES_REG  7'h05
`define TEMP2_REG         7'h06
`define TEMP1_REG         7'h07
`define XDATA3_REG        7'h08
`define XDATA2_REG        7'h09
`define XDATA1_REG        7'h0A
`define YDATA3_REG        7'h0B
`define YDATA2_REG        7'h0C
`define YDATA1_REG        7'h0D
`define ZDATA3_REG        7'h0E
`define ZDATA2_REG        7'h0F
`define ZDATA1_REG        7'h10
`define FIFO_DATA_REG     7'h11

//write read
`define OFFSET_X_H_REG    7'h1E
`define OFFSET_X_L_REG    7'h1F
`define OFFSET_Y_H_REG    7'h20
`define OFFSET_Y_L_REG    7'h21
`define OFFSET_Z_H_REG    7'h22
`define OFFSET_Z_L_REG    7'h23
`define ACT_EN_REG        7'h24
`define ACT_THRESH_H_REG  7'h25
`define ACT_THRESH_L_REG  7'h26
`define ACT_COUNT_REG     7'h27
`define FILTER_REG        7'h28
`define FIFO_SAMPLES_REG  7'h29
`define INT_MAP_REG       7'h2A
`define SYNC_REG          7'h2B
`define POWER_CTL_REG     7'h2C
`define SELF_TEST_REG     7'h2D
`define RESET_REG         7'h2E