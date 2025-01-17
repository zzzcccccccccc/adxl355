`timescale 1ns / 1ps

module tb_spi_master;
    parameter DATA_WIDTH = 24;
    parameter ADDR_WIDTH = 4;
    parameter DEPTH = 1 << ADDR_WIDTH;

    // Parameters
    parameter CLK_PERIOD = 20; // 50MHz Clock
    parameter RESET_PERIOD = 100;
    parameter adc_ClockPeriod = 100;  // 时钟周期为10ns

    // 输入输出信号声明
    reg                adc_clk;
    reg                rst_n;

    // cic滤波器输入输出
    reg  signed [4:0]  dat_in;
    wire signed [19:0] dat_out;
    wire signed        adc_clk_vld_out;

    // Testbench signals
    reg         mems_clk;
    reg         clk;
    reg         rst_n;
    reg         cs_n_in;
    reg         wr_rd; // 1 for read, 0 for write
    reg [7:0]   spi_data_master;      
    reg [6:0]   spi_addr_master;

    wire         wr_en;
    reg  [19:0]    filter_fifo_data;

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
    wire        fifo_reg_fifo_read_en;

    wire                     full;    
    wire                     empty;    
    wire [DATA_WIDTH-1:0]    fifo_reg_data;
    
        

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


    register_files my_register_files_inst (
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

        .fifo_reg_data(fifo_reg_data),

        .FIFO_ENTRIES_in(FIFO_ENTRIES_in),

        .reg_spi_rd_valid(reg_spi_rd_valid),
        .reg_spi_rd_data(reg_spi_rd_data),

        .reg_fifo_read_en(reg_fifo_read_en),
    
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
        .STANDBY(STANDBY)
    );

    synchronous_fifo #(
        .DATA_WIDTH(24),
        .ADDR_WIDTH(4)
    ) my_fifo_inst (
        .clk(mems_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .reg_fifo_read_en(reg_fifo_read_en),
        .filter_fifo_data(filter_fifo_data),

        .full(full),
        .empty(empty),
        .fifo_reg_data(fifo_reg_data),
        .fifo_sample_num(FIFO_ENTRIES_in)
    );


    adc_top u_adc_top (
        .clk         ( adc_clk         ),
        .rstn        ( rst_n       ),
        .dat_in      ( dat_in      ),
        .dat_out     ( filter_fifo_data  ),
        .clk_vld_out ( wr_en )
    );


    // 时钟信号生成
    initial begin
        adc_clk = 0;
        forever #(adc_ClockPeriod / 2) adc_clk = ~adc_clk;
    end


    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        mems_clk = 0;
        forever #(CLK_PERIOD / 2) mems_clk = ~mems_clk;
    end

    // 定义文件句柄和文件名
    integer file;
    integer scan_file;
    reg signed [31:0] data;
    reg signed [31:0] data_in;

    assign dat_in = data_in;

    // 初始化并读取文件
    initial begin
        rst_n = 0;
        #adc_ClockPeriod rst_n = 1;

        // 打开文件
        file = $fopen("/home/summer/Desktop/demo/cic_filter/adc_out.txt", "r");

        // 初始化data_in
        data_in = 0;

        // 读取文件中的数据
        while (!$feof(file)) begin
            scan_file = $fscanf(file, "%d", data);
            if (scan_file == 1) begin
                @(posedge adc_clk);
                data_in = data;
            end
        end

        $fclose(file);

        #adc_ClockPeriod
        $finish;
    end


    // Reset sequence
    initial begin
        rst_n = 1;
        #(RESET_PERIOD);
        rst_n = 0;
        #(RESET_PERIOD);
        rst_n = 1;
    end

    // 时钟信号生成
    initial begin
        adc_clk = 0;
        forever #(adc_ClockPeriod / 2) adc_clk = ~adc_clk;
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
/*
    initial begin
        @(posedge rst_n);
        repeat (48) begin
            #50;
            wr_en = 1;
            filter_fifo_data = $random % (1 << DATA_WIDTH);
            #10;
            wr_en = 0;
        end

    end
*/

    initial begin
        #(RESET_PERIOD * 5);
//        spi_write_task(7'h20,8'hff);
        #(CLK_PERIOD * 400000);

        #(CLK_PERIOD * 40);
        spi_read_task (7'h20);
        #(CLK_PERIOD * 40);
        spi_write_burst_task(7'h1E,100'd17);
        #(CLK_PERIOD * 40);
        spi_read_burst_task(7'h1E,100'd17);
        #(CLK_PERIOD * 40);
        spi_read_burst_task(7'h1E,100'd17);
        #(CLK_PERIOD * 400);
        spi_read_burst_task(7'h11,100'd9);
        #(CLK_PERIOD * 400);
        spi_read_burst_task(7'h11,100'd9);

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
