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
    reg         reg_slave_rd_valid;
    reg [7:0]   reg_slave_rd_data;
    // Outputs
    wire        data_out_vld;
    wire [7:0]  data_out;
    wire        cs_n;
    wire        sclk;         
    wire        mosi;     
    wire [7:0]  spi_slave_wr_data;
    wire [6:0]  spi_slave_wr_rd_addr;   
    wire        spi_addr_valid;
    wire        spi_data_valid;
    wire        miso;
    wire        wr_rd_spi;

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

        .reg_slave_rd_data(reg_slave_rd_data),
        .reg_slave_rd_valid(reg_slave_rd_valid),

        .spi_slave_wr_data(spi_slave_wr_data),
        .spi_slave_wr_rd_addr(spi_slave_wr_rd_addr),
        .spi_addr_valid(spi_addr_valid),
        .spi_data_valid(spi_data_valid),

        .miso(miso),
        .wr_rd(wr_rd_spi)
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
        rst_n = 0;
        #(RESET_PERIOD);
        rst_n = 1;
    end

    initial begin
        forever begin
            @(posedge spi_addr_valid);
            #(CLK_PERIOD * 2);
            reg_slave_rd_valid=1;
            reg_slave_rd_data=8'hef;
            #(CLK_PERIOD * 20);
            reg_slave_rd_valid=0;
            #(CLK_PERIOD * 300);

        end
    end



    initial begin
        #(RESET_PERIOD * 2);
        spi_write_task(7'h7f,8'hff);
        #(CLK_PERIOD * 10);
        spi_read_task (7'h7f);
        #(CLK_PERIOD * 10);
        spi_write_burst_task(7'h02,100'd6);
        #(CLK_PERIOD * 10);
        spi_read_burst_task(7'h02,100'd6);
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
                spi_data_master = i+1;
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
