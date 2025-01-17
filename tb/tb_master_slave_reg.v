`timescale 1ns / 1ps

module tb_spi_master;

    // Parameters
    parameter CLK_PERIOD = 20; // 50MHz Clock
    parameter RESET_PERIOD = 100;

    // Testbench signals
    reg         mems_clk;
    reg         clk;
    reg         rst_n;
    reg         cs_n_in;
    reg         wr_rd; // 1 for read, 0 for write
    reg [7:0]   spi_data_master;      
    reg [6:0]   spi_addr_master;
    wire         reg_spi_rd_valid;
    wire [7:0]   reg_spi_rd_data;
    // Outputs
    wire        data_out_vld;
    wire [7:0]  data_out;
    wire        cs_n;
    wire        sclk;         
    wire        mosi;     
    wire [7:0]  spi_wr_data;
    wire [6:0]  spi_wr_rd_addr;   
    wire        spi_wr_addr_valid;
    wire        spi_rd_addr_valid;
    wire        spi_wr_data_valid;
    wire        miso;
    wire        wr_rd_spi;
    wire [99:0] spi_wr_burst_num;
    wire [99:0] spi_rd_burst_num;

    wire        NVM_BUSY;
    wire        FIFO_OVR;

    wire [23:0] fifo_data_in_24;

    wire        temp_valid;
    wire [11:0] temp_in;

    wire        xdata_valid;
    wire        ydata_valid;
    wire        zdata_valid;


    wire [7:0]  fifo_data_in;
    wire [6:0]  FIFO_ENTRIES_in;
    wire        spi_slave_rd_valid;
    wire [7:0]  regs_to_spi_rd_data;
    wire [2:0]  HPF_CONER;
    wire [3:0]  ODR_LPF;
    wire        ACT_EN2;
    wire        OVR_EN2;
    wire        FULL_EN2;
    wire        RDY_EN2;
    wire        ACT_EN1;
    wire        OVR_EN1;
    wire        FULL_EN1;
    wire        RDY_EN1;
    wire        range;
    wire        DRDY_OFF;
    wire        TEMP_OFF;
    wire        STANDBY;
    wire        fifo_rd_en;
        

    integer     i;
    // Instantiate the SPI Master
    spi_master master (
        .clk(clk),
        .rst_n(rst_n),
        .cs_n_in(cs_n_in),
        .miso(miso),
        .wr_rd(wr_rd),
        .spi_data_master(spi_data_master),      
        .spi_addr_master(spi_addr_master),
        .data_out_vld(data_out_vld),
        .data_out(data_out),
        .cs_n(cs_n),
        .sclk(sclk),         
        .mosi(mosi)        
    );


    spi_slave slave (
        .mems_clk(mems_clk),
        .sclk(sclk),
        .rst_n(rst_n),
        .mosi(mosi),
        .cs_n(cs_n),

        .reg_spi_rd_valid(reg_spi_rd_valid),
        .reg_spi_rd_data(reg_spi_rd_data),

        .spi_wr_rd_addr(spi_wr_rd_addr),
        .spi_wr_addr_valid(spi_wr_addr_valid),
        .spi_rd_addr_valid(spi_rd_addr_valid),

        .spi_wr_data(spi_wr_data),
        .spi_wr_data_valid(spi_wr_data_valid),

        .miso(miso),
        .spi_wr_burst_num(spi_wr_burst_num),
        .spi_rd_burst_num(spi_rd_burst_num)

    );


    register_files u_register_files (
        .mems_clk(mems_clk),
        .rst_n(rst_n),
        .cs_n(cs_n),

        .spi_wr_addr_valid(spi_wr_addr_valid),
        .spi_rd_addr_valid(spi_rd_addr_valid),

        .spi_wr_data_valid(spi_wr_data_valid),

        .spi_wr_burst_num(spi_wr_burst_num),
        .spi_rd_burst_num(spi_rd_burst_num),

        .spi_wr_data(spi_wr_data),
        .spi_wr_rd_addr(spi_wr_rd_addr),

        .NVM_BUSY(NVM_BUSY),
        .FIFO_OVR(FIFO_OVR),


        .temp_valid(temp_valid),
        .temp_in(temp_in),

        .xdata_valid(xdata_valid),
        .ydata_valid(ydata_valid),
        .zdata_valid(zdata_valid),
        .xdata_in(xdata_in),
        .ydata_in(ydata_in),
        .zdata_in(zdata_in),

        .fifo_data_in(fifo_data_in),
        .FIFO_ENTRIES_in(FIFO_ENTRIES_in),

        .reg_spi_rd_valid(reg_spi_rd_valid),
        .reg_spi_rd_data(reg_spi_rd_data),
        .HPF_CONER(HPF_CONER),
        .ODR_LPF(ODR_LPF),
        .ACT_EN2(ACT_EN2),
        .OVR_EN2(OVR_EN2),
        .FULL_EN2(FULL_EN2),
        .RDY_EN2(RDY_EN2),
        .ACT_EN1(ACT_EN1),
        .OVR_EN1(OVR_EN1),
        .FULL_EN1(FULL_EN1),
        .RDY_EN1(RDY_EN1),
        .range(range),
        .DRDY_OFF(DRDY_OFF),
        .TEMP_OFF(TEMP_OFF),
        .STANDBY(STANDBY),
        .fifo_rd_en(fifo_rd_en)
    );


    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        mems_clk = 0;
        forever #(CLK_PERIOD / 2) mems_clk = ~mems_clk;
    end

    // Reset sequence
    initial begin
        rst_n = 1;
        #(RESET_PERIOD);
        rst_n = 0;
        #(RESET_PERIOD);
        rst_n = 1;
    end

/*
    initial begin
        forever begin
            @(posedge spi_wr_addr_valid);
            #(CLK_PERIOD * 2);
            reg_spi_rd_valid=1;
            reg_spi_rd_data=8'hef;
            #(CLK_PERIOD * 20);
            reg_spi_rd_valid=0;
            #(CLK_PERIOD * 300);

        end
    end
*/


    initial begin
        #(RESET_PERIOD * 2);
        spi_write_task(7'h20,8'hff);
        #(CLK_PERIOD * 40);
        spi_read_task (7'h20);
        #(CLK_PERIOD * 40);
        spi_write_burst_task(7'h1E,100'd17);
        #(CLK_PERIOD * 40);
        spi_read_burst_task(7'h1E,100'd17);
        #(CLK_PERIOD * 400);
        spi_read_burst_task(7'h11,100'd3);

        #1000;
        $finish;
    end

    task automatic spi_write_task;
        input [6:0] spi_addr; // SPI 从设备地址 
        input [7:0] spi_data; // SPI 从设备地址 

        begin
            spi_addr_master = spi_addr; // Set the SPI address
            spi_data_master = spi_data; // Set the SPI address
    //        spi_data_master = 8'hff; // Set the SPI address

            wr_rd = 1'b0; // Set the Read/Write control signal
            cs_n_in = 1'b0; // Start sending
            #(CLK_PERIOD * 640);
            cs_n_in = 1'b1; // Stop sending
        end
    endtask

    task automatic spi_write_burst_task;
        input [6:0] spi_addr; // SPI 从设备地址 
        input [99:0] burst_length;

        begin
            spi_addr_master = spi_addr; // Set the SPI address
            spi_data_master = 8'd1; // Set the SPI address
            wr_rd = 1'b0; // Set the Read/Write control signal
            cs_n_in = 1'b0; // Start sending
            #(CLK_PERIOD * 640);//16bits 时间
            for (i = 0; i < burst_length-1; i = i + 1) begin
                spi_data_master = i+2;
                #(CLK_PERIOD * 320); //8 bits 时间
            end
            cs_n_in = 1'b1; // Stop sending
        end
    endtask

    task automatic spi_read_task;
        input [6:0] spi_addr; 
        begin
            spi_addr_master = spi_addr; // Set the SPI address
            wr_rd = 1'b1; // Set the Read/Write control signal
            cs_n_in = 1'b0; // Start sending
            #(CLK_PERIOD * 640);
            cs_n_in = 1'b1; // Stop sending
        end
    endtask

    task automatic spi_read_burst_task;
        input [6:0]  spi_addr; // SPI 从设备地址 
        input [99:0] burst_length;
        begin
            spi_addr_master = spi_addr; // Set the SPI address
            wr_rd = 1'b1; // Set the Read/Write control signal
            cs_n_in = 1'b0; // Start sending
            #(CLK_PERIOD * 320 * (burst_length+1));
            cs_n_in = 1'b1; // Stop sending
        end
    endtask

    // Monitor signals
    initial begin
        $monitor("Time: %0t | cs_n: %b | sclk: %b | mosi: %b | miso: %b | data_out: %h | data_out_vld: %b", 
                 $time, cs_n, sclk, mosi, miso, data_out, data_out_vld);
    end

    initial begin
        $fsdbDumpfile("fifo_sim.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA; // 开启对多维数组的dump
    end


endmodule
