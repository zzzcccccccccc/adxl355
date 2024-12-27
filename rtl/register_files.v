`include "../../rtl/defines.v"

module register_files(
    input           mems_clk,
    input           rst_n,
    input           cs_n,    

    input           spi_wr_addr_valid,
    input           spi_rd_addr_valid,

    input           spi_wr_data_valid,      

    input [99:0]    spi_wr_burst_num,
    input [99:0]    spi_rd_burst_num,
    
    input [7:0]     spi_wr_data,
    input [6:0]     spi_wr_rd_addr,

    input           NVM_BUSY,
    input           FIFO_OVR,


    input           temp_valid,          
    input [11:0]    temp_in,

    input           xdata_valid,
    input           ydata_valid,
    input           zdata_valid,
    input [19:0]    xdata_in,
    input [19:0]    ydata_in,
    input [19:0]    zdata_in,

    input [23:0]    fifo_reg_data,


    input [6:0]     FIFO_ENTRIES_in,


    output           reg_spi_rd_valid,
    output [7:0]     reg_spi_rd_data,

    output           reg_fifo_read_en,
  
    output [2:0]     HPF_CONER,
    output [3:0]     ODR_LPF,
    output           ACT_EN2,
    output           OVR_EN2,
    output           FULL_EN2,
    output           RDY_EN2,
    output           ACT_EN1,
    output           OVR_EN1,
    output           FULL_EN1,
    output           RDY_EN1,
    output           range,
    output           DRDY_OFF,
    output           TEMP_OFF,
    output           STANDBY

);


wire [99:0]  rd_burst_addr;
wire [99:0]  spi_slave_wr_addr_burst_out;
wire [99:0]  spi_slave_rd_addr_burst_out;

reg [1:0] req_count;

reg spi_wr_addr_valid_r;
reg spi_rd_addr_valid_r;
reg spi_wr_data_valid_r;
reg spi_wr_data_valid_r_pos;      
reg reg_fifo_read_en_r;

reg fifo_reg_data_valid_r;
reg fifo_load_r;

reg [7:0] reg_spi_rd_data_r;

reg [7:0] DEVID_AD_reg;
reg [7:0] DEVID_MST_reg;
reg [7:0] PARTID_reg;
reg [7:0] REVID_reg;
reg [7:0] status_reg;
reg [7:0] FIFO_ENTRIES_reg;
reg [7:0] TEMP2_reg;
reg [7:0] TEMP1_reg;
reg [7:0] XDATA3_reg;
reg [7:0] XDATA2_reg;
reg [7:0] XDATA1_reg;
reg [7:0] YDATA3_reg;
reg [7:0] YDATA2_reg;
reg [7:0] YDATA1_reg;
reg [7:0] ZDATA3_reg;
reg [7:0] ZDATA2_reg;
reg [7:0] ZDATA1_reg;
reg [7:0] FIFO_DATA_reg;
reg [7:0] OFFSET_X_H_reg;
reg [7:0] OFFSET_X_L_reg;
reg [7:0] OFFSET_Y_H_reg;
reg [7:0] OFFSET_Y_L_reg;
reg [7:0] OFFSET_Z_H_reg;
reg [7:0] OFFSET_Z_L_reg;
reg [7:0] ACT_EN_reg;
reg [7:0] ACT_THRESH_H_reg;
reg [7:0] ACT_THRESH_L_reg;
reg [7:0] ACT_COUNT_reg;
reg [7:0] FILTER_reg;
reg [7:0] FIFO_SAMPLES_reg;
reg [7:0] INT_MAP_reg;
reg [7:0] SYNC_reg;
reg [7:0] POWER_CTL_reg;
reg [7:0] SELF_TEST_reg;
reg [7:0] RESET_reg;



reg [7:0] fifo_count_mems_clk_r;
reg [2:0] mov_reg_valid_r;
reg [23:0] fifo_24bits;

reg [7:0] x_act_count;
reg [7:0] y_act_count;
reg [7:0] z_act_count;

reg [3:0] current_state;
reg [3:0] next_state;

reg [2:0] read_count;

parameter INIT_RESET_0 = 4'd0;
parameter INIT_RESET_1 = 4'd1;
parameter INIT_RESET_2 = 4'd2;
parameter INIT_RESET_3 = 4'd3;
parameter INIT_LOAD    = 4'd4;

parameter LOAD_00      = 4'd5;
parameter LOAD_01      = 4'd6;
parameter LOAD_02      = 4'd7;
parameter LOAD_03      = 4'd8;


//Write Read
wire OFFSET_X_H_REG_addr_valid  ; 
wire OFFSET_X_L_REG_addr_valid  ; 
wire OFFSET_Y_H_REG_addr_valid  ; 
wire OFFSET_Y_L_REG_addr_valid  ; 
wire OFFSET_Z_H_REG_addr_valid  ; 
wire OFFSET_Z_L_REG_addr_valid  ; 
wire ACT_EN_REG_addr_valid      ; 
wire ACT_THRESH_H_REG_addr_valid; 
wire ACT_THRESH_L_REG_addr_valid; 
wire ACT_COUNT_REG_addr_valid   ; 
wire FILTER_REG_addr_valid      ; 
wire FIFO_SAMPLES_REG_addr_valid; 
wire INT_MAP_REG_addr_valid     ; 
wire SYNC_REG_addr_valid        ; 
wire POWER_CTL_REG_addr_valid   ; 
wire SELF_TEST_REG_addr_valid   ; 
wire RESET_REG_addr_valid       ; 

//divided signal 
wire DATA_RDY;
wire Activity;
wire st2;
wire st1;
wire FIFO_FULL;
wire x_activity;
wire y_activity;
wire z_activity;


always @(posedge mems_clk or negedge rst_n)
    if(~rst_n || cs_n)
        spi_wr_addr_valid_r <= 1'b0;
    else if(spi_wr_addr_valid)
        spi_wr_addr_valid_r <= 1'b1;

always @(posedge mems_clk or negedge rst_n)
    if(~rst_n || cs_n)
        spi_rd_addr_valid_r <= 1'b0;
    else if(spi_rd_addr_valid)
        spi_rd_addr_valid_r <= 1'b1;

always @(posedge mems_clk or negedge rst_n)
    if(~rst_n || cs_n)
        spi_wr_data_valid_r_pos <= 1'b0;
    else if(spi_wr_data_valid)
        spi_wr_data_valid_r_pos <= 1'b1;
    else
        spi_wr_data_valid_r_pos <= 1'b0;

always @(posedge mems_clk or negedge rst_n)
    if(~rst_n || cs_n)
        spi_wr_data_valid_r <= 1'b0;
    else if(spi_wr_data_valid & !spi_wr_data_valid_r_pos)
        spi_wr_data_valid_r <= 1'b1;
    else   
        spi_wr_data_valid_r <= 1'b0;


assign spi_slave_wr_addr_burst_out = spi_wr_rd_addr + spi_wr_burst_num;



//Write Read
assign OFFSET_X_H_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_X_H_REG);
assign OFFSET_X_L_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_X_L_REG);
assign OFFSET_Y_H_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_Y_H_REG);
assign OFFSET_Y_L_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_Y_L_REG);
assign OFFSET_Z_H_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_Z_H_REG);
assign OFFSET_Z_L_REG_addr_valid      = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `OFFSET_Z_L_REG);
assign ACT_EN_REG_addr_valid          = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `ACT_EN_REG);
assign ACT_THRESH_H_REG_addr_valid    = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `ACT_THRESH_H_REG);
assign ACT_THRESH_L_REG_addr_valid    = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `ACT_THRESH_L_REG);
assign ACT_COUNT_REG_addr_valid       = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `ACT_COUNT_REG);
assign FILTER_REG_addr_valid          = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `FILTER_REG);
assign FIFO_SAMPLES_REG_addr_valid    = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `FIFO_SAMPLES_REG);
assign INT_MAP_REG_addr_valid         = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `INT_MAP_REG);
assign SYNC_REG_addr_valid            = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `SYNC_REG);
assign POWER_CTL_REG_addr_valid       = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `POWER_CTL_REG);
assign SELF_TEST_REG_addr_valid       = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `SELF_TEST_REG);
assign RESET_REG_addr_valid           = spi_wr_addr_valid_r & (spi_slave_wr_addr_burst_out == `RESET_REG);



always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n)
        OFFSET_X_H_reg <= 8'd0;
    else if(OFFSET_X_H_REG_addr_valid & spi_wr_data_valid_r)
        OFFSET_X_H_reg <= spi_wr_data;
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        OFFSET_X_L_reg <= 8'd0;
    end else if (OFFSET_X_L_REG_addr_valid & spi_wr_data_valid_r) begin
        OFFSET_X_L_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        OFFSET_Y_H_reg <= 8'd0;
    end else if (OFFSET_Y_H_REG_addr_valid & spi_wr_data_valid_r) begin
        OFFSET_Y_H_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        OFFSET_Y_L_reg <= 8'd0;
    end else if (OFFSET_Y_L_REG_addr_valid & spi_wr_data_valid_r) begin
        OFFSET_Y_L_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        OFFSET_Z_H_reg <= 8'd0;
    end else if (OFFSET_Z_H_REG_addr_valid & spi_wr_data_valid_r) begin
        OFFSET_Z_H_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        OFFSET_Z_L_reg <= 8'd0;
    end else if (OFFSET_Z_L_REG_addr_valid & spi_wr_data_valid_r) begin
        OFFSET_Z_L_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        ACT_EN_reg <= 8'd0;
    end else if (ACT_EN_REG_addr_valid & spi_wr_data_valid_r) begin
        ACT_EN_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        ACT_THRESH_H_reg <= 8'd0;
    end else if (ACT_THRESH_H_REG_addr_valid & spi_wr_data_valid_r) begin
        ACT_THRESH_H_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        ACT_THRESH_L_reg <= 8'd0;
    end else if (ACT_THRESH_L_REG_addr_valid & spi_wr_data_valid_r) begin
        ACT_THRESH_L_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        ACT_COUNT_reg <= 8'd0;
    end else if (ACT_COUNT_REG_addr_valid & spi_wr_data_valid_r) begin
        ACT_COUNT_reg <= spi_wr_data;
    end
end

assign  HPF_CONER = FILTER_reg[6:4]; 
assign  ODR_LPF   = FILTER_reg[3:0]; 

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        FILTER_reg <= 8'd0;
    end else if (FILTER_REG_addr_valid  & spi_wr_data_valid_r) begin
        FILTER_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        FIFO_SAMPLES_reg <= 8'd0;
    end else if (FIFO_SAMPLES_REG_addr_valid & spi_wr_data_valid_r) begin
        FIFO_SAMPLES_reg <= spi_wr_data;
    end
end
assign ACT_EN1  = INT_MAP_reg[3];
assign OVR_EN1  = INT_MAP_reg[2];
assign FULL_EN1 = INT_MAP_reg[1];
assign RDY_EN1  = INT_MAP_reg[0];
assign ACT_EN2  = INT_MAP_reg[7];
assign OVR_EN2  = INT_MAP_reg[6];
assign FULL_EN2 = INT_MAP_reg[5];
assign RDY_EN2  = INT_MAP_reg[4];

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        INT_MAP_reg <= 8'd0;
    end else if (INT_MAP_REG_addr_valid & spi_wr_data_valid_r) begin
        INT_MAP_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        SYNC_reg <= 8'd0;
    end else if (SYNC_REG_addr_valid & spi_wr_data_valid_r) begin
        SYNC_reg <= spi_wr_data;
    end
end

assign DRDY_OFF = POWER_CTL_reg[2];
assign TEMP_OFF = POWER_CTL_reg[1];
assign STANDBY  = POWER_CTL_reg[0];

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        POWER_CTL_reg <= 8'd0;
    end else if (POWER_CTL_REG_addr_valid & spi_wr_data_valid_r) begin
        POWER_CTL_reg <= spi_wr_data;
    end
end

assign st1 = SELF_TEST_reg[1];
assign st0 = SELF_TEST_reg[0];

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        SELF_TEST_reg <= 8'd0;
    end else if (SELF_TEST_REG_addr_valid & spi_wr_data_valid_r) begin
        SELF_TEST_reg <= spi_wr_data;
    end
end

always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        RESET_reg <= 8'd0;
    end else if (RESET_REG_addr_valid & spi_wr_data_valid_r) begin
        RESET_reg <= spi_wr_data;
    end
end


// read 部分

assign spi_slave_rd_addr_burst_out = spi_wr_rd_addr + spi_rd_burst_num;


always @(posedge mems_clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_spi_rd_data_r <= 8'd0;
    end else begin
        case (spi_slave_rd_addr_burst_out)
            `DEVID_AD_REG: begin
                reg_spi_rd_data_r <= DEVID_AD_reg;
            end
            `DEVID_MST_REG: begin
                reg_spi_rd_data_r <= DEVID_MST_reg;
            end
            `PARTID_REG: begin
                reg_spi_rd_data_r <= PARTID_reg;
            end
            `REVID_REG: begin
                reg_spi_rd_data_r <= REVID_reg;
            end
            `STATUS_REG: begin
                reg_spi_rd_data_r <= status_reg;
            end
            `FIFO_ENTRIES_REG: begin
                reg_spi_rd_data_r <= FIFO_ENTRIES_reg;
            end
            `TEMP1_REG: begin
                reg_spi_rd_data_r <= TEMP1_reg;
            end
            `TEMP2_REG: begin
                reg_spi_rd_data_r <= TEMP2_reg;
            end
            `XDATA1_REG: begin
                reg_spi_rd_data_r <= XDATA1_reg;
            end
            `XDATA2_REG: begin
                reg_spi_rd_data_r <= XDATA2_reg;
            end
            `XDATA3_REG: begin
                reg_spi_rd_data_r <= XDATA3_reg;
            end
            `YDATA1_REG: begin
                reg_spi_rd_data_r <= YDATA1_reg;
            end
            `YDATA2_REG: begin
                reg_spi_rd_data_r <= YDATA2_reg;
            end
            `YDATA3_REG: begin
                reg_spi_rd_data_r <= YDATA3_reg;
            end
            `ZDATA1_REG: begin
                reg_spi_rd_data_r <= ZDATA1_reg;
            end
            `ZDATA2_REG: begin
                reg_spi_rd_data_r <= ZDATA2_reg;
            end
            `ZDATA3_REG: begin
                reg_spi_rd_data_r <= ZDATA3_reg;
            end
            `FIFO_DATA_REG: begin
                reg_spi_rd_data_r <= FIFO_DATA_reg;
            end
            `OFFSET_X_H_REG: begin
                reg_spi_rd_data_r <= OFFSET_X_H_reg;
            end
            `OFFSET_X_L_REG: begin
                reg_spi_rd_data_r <= OFFSET_X_L_reg;
            end
            `OFFSET_Y_H_REG: begin
                reg_spi_rd_data_r <= OFFSET_Y_H_reg;
            end
            `OFFSET_Y_L_REG: begin
                reg_spi_rd_data_r <= OFFSET_Y_L_reg;
            end
            `OFFSET_Z_H_REG: begin
                reg_spi_rd_data_r <= OFFSET_Z_H_reg;
            end
            `OFFSET_Z_L_REG: begin
                reg_spi_rd_data_r <= OFFSET_Z_L_reg;
            end
            `ACT_EN_REG: begin
                reg_spi_rd_data_r <= ACT_EN_reg;
            end
            `ACT_THRESH_H_REG: begin
                reg_spi_rd_data_r <= ACT_THRESH_H_reg;
            end
            `ACT_THRESH_L_REG: begin
                reg_spi_rd_data_r <= ACT_THRESH_L_reg;
            end
            `ACT_COUNT_REG: begin
                reg_spi_rd_data_r <= ACT_COUNT_reg;
            end
            `FILTER_REG: begin
                reg_spi_rd_data_r <= FILTER_reg;
            end
            `FIFO_SAMPLES_REG: begin
                reg_spi_rd_data_r <= FIFO_SAMPLES_reg;
            end
            `INT_MAP_REG: begin
                reg_spi_rd_data_r <= INT_MAP_reg;
            end
            `SYNC_REG: begin
                reg_spi_rd_data_r <= SYNC_reg;
            end
            `POWER_CTL_REG: begin
                reg_spi_rd_data_r <= POWER_CTL_reg;
            end
            `SELF_TEST_REG: begin
                reg_spi_rd_data_r <= SELF_TEST_reg;
            end
            `RESET_REG: begin
                reg_spi_rd_data_r <= RESET_reg;
            end
            default: begin
                reg_spi_rd_data_r <= 8'd0;
            end
        endcase
    end
end

assign reg_spi_rd_valid = spi_rd_addr_valid_r;
assign reg_spi_rd_data = reg_spi_rd_data_r & {8{reg_spi_rd_valid}};

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        spi_rd_addr_valid_r <= 1'd0;
    else
        if (spi_rd_addr_valid)
            spi_rd_addr_valid_r <= 1'd1;
        else
            spi_rd_addr_valid_r <= 1'd0;
end


always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        DEVID_AD_reg <= 8'hAD;
    else
        DEVID_AD_reg <= 8'hAD;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        DEVID_MST_reg <= 8'h1D;
    else
        DEVID_MST_reg <= 8'h1D;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        PARTID_reg <= 8'hED;
    else
        PARTID_reg <= 8'hED;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        REVID_reg <= 8'h01;
    else
        REVID_reg <= 8'h01;
end

assign DATA_RDY = xdata_valid | ydata_valid | zdata_valid;
assign Activity = x_activity  | y_activity  | z_activity; 

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        x_act_count <= 8'h00;
    else if ((DATA_RDY) && (xdata_in > {ACT_THRESH_H_reg,ACT_THRESH_L_reg}) )
        x_act_count <= x_act_count + 1;
end

assign  x_activity = ( x_act_count >  ACT_COUNT_reg);

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        y_act_count <= 8'h00;
    else if ((DATA_RDY) && (ydata_in > {ACT_THRESH_H_reg,ACT_THRESH_L_reg}) )
        y_act_count <= y_act_count + 1;
end

assign  y_activity = ( y_act_count >  ACT_COUNT_reg);

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        z_act_count <= 8'h00;
    else if ((DATA_RDY) && (zdata_in > {ACT_THRESH_H_reg,ACT_THRESH_L_reg}) )
        z_act_count <= z_act_count + 1;
end

assign  z_activity = ( z_act_count >  ACT_COUNT_reg);

assign  FIFO_FULL  = FIFO_ENTRIES_reg > FIFO_SAMPLES_reg;

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        status_reg <= 8'h00;
    else
        status_reg[0] <= DATA_RDY;
        status_reg[1] <= FIFO_FULL;
        status_reg[2] <= FIFO_OVR;
        status_reg[3] <= Activity;
        status_reg[4] <= NVM_BUSY;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        FIFO_ENTRIES_reg <= 8'h00;
    else
        FIFO_ENTRIES_reg[6:0] <= FIFO_ENTRIES_in;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        TEMP2_reg <= 8'h00;
    else
        TEMP2_reg <= temp_in[11:8];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        TEMP1_reg <= 8'h00;
    else
        TEMP1_reg <= temp_in[7:0];
end


always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        XDATA3_reg <= 8'h00;
    else 
        XDATA3_reg <= xdata_in[19:12];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        XDATA2_reg <= 8'h00;
    else
        XDATA2_reg <= xdata_in[11:4];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        XDATA1_reg <= 8'h00;
    else
        XDATA1_reg[7:4] <= xdata_in[3:0];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        YDATA3_reg <= 8'h00;
    else
        YDATA3_reg <= ydata_in[19:12];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        YDATA2_reg <= 8'h00;
    else
        YDATA2_reg <= ydata_in[11:4];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        YDATA1_reg <= 8'h00;
    else
        YDATA1_reg[7:4] <= ydata_in[3:0];
end


always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        ZDATA3_reg <= 8'h00;
    else
        ZDATA3_reg <= zdata_in[19:12];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        ZDATA2_reg <= 8'h00;
    else
        ZDATA2_reg <= zdata_in[11:4];
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        ZDATA1_reg <= 8'h00;
    else
        ZDATA1_reg[7:4] <= zdata_in[3:0];
end





always @(posedge mems_clk or negedge rst_n) begin
    if (!rst_n) 
        current_state <= INIT_RESET_0;     
    else
        current_state <= next_state;
end


always @(*) begin
    case(current_state)
        INIT_RESET_0: next_state <= INIT_RESET_1;
        INIT_RESET_1: next_state <= INIT_RESET_2;
        INIT_RESET_2: next_state <= INIT_RESET_3;
        INIT_RESET_3: next_state <= INIT_LOAD;
        INIT_LOAD:    next_state <= LOAD_00;
        LOAD_00: begin
            if(fifo_count_mems_clk_r == 8'd30)
                next_state <= LOAD_01;
            else
                next_state <= LOAD_00;           
        end
        LOAD_01: begin
            if(fifo_count_mems_clk_r == 8'd30)
                next_state <= LOAD_02;
            else
                next_state <= LOAD_01;           
        end
        LOAD_02: begin
                next_state <= LOAD_03;       
        end
        LOAD_03: begin
            if(fifo_count_mems_clk_r == 8'd30)
                next_state <= LOAD_00;
            else
                next_state <= LOAD_03;           
        end    endcase
end

assign reg_fifo_read_en = reg_fifo_read_en_r;


always @(posedge mems_clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_24bits   <= 24'h00;
        FIFO_DATA_reg <=  8'h00;
        reg_fifo_read_en_r <= 1'h0;
    end
    else if(current_state == INIT_RESET_1)
        reg_fifo_read_en_r <= 1'h1;
    else if(current_state == INIT_RESET_2)
        reg_fifo_read_en_r <= 1'h0;
    else if(current_state == INIT_LOAD) begin
        fifo_24bits <= fifo_reg_data;
    end
    else if(current_state == LOAD_00) begin
        reg_fifo_read_en_r <= 1'h0;
        FIFO_DATA_reg <=  fifo_24bits[23:16];
    end
    else if(current_state == LOAD_01) begin
        FIFO_DATA_reg <=  fifo_24bits[15:8];
    end
    else if(current_state == LOAD_02) begin
        FIFO_DATA_reg <=  fifo_24bits[7:0];
    end
    else if(current_state == LOAD_03) begin
        reg_fifo_read_en_r <= 1'h1;
        fifo_24bits <= fifo_reg_data;
    end
end




always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        fifo_count_mems_clk_r <= 8'h00;
    else if(spi_rd_addr_valid && (spi_slave_rd_addr_burst_out == 7'h11))
        fifo_count_mems_clk_r <= fifo_count_mems_clk_r + 1;
    else
        fifo_count_mems_clk_r <= 8'h00;
end




endmodule