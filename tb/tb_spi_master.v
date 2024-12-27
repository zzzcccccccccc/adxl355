`timescale 1ns / 1ps

module tb_spi_master;

    // Parameters
    parameter CLK_PERIOD = 20; // 50MHz Clock
    parameter RESET_PERIOD = 100;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg miso;
    reg wr_rd; // 1 for read, 0 for write
    reg [6:0] spi_data_master;      
    reg send_start;   
    reg [7:0] spi_addr_master;

    // Outputs
    wire data_out_vld;
    wire [7:0] data_out;
    wire cs_n;
    wire sclk;         
    wire mosi;        

    // Instantiate the SPI Master
    spi_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .miso(miso),
        .wr_rd(wr_rd),
        .spi_data_master(spi_data_master),      
        .send_start(send_start),   
        .spi_addr_master(spi_addr_master),
        .data_out_vld(data_out_vld),
        .data_out(data_out),
        .cs_n(cs_n),
        .sclk(sclk),         
        .mosi(mosi)        
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Reset sequence
    initial begin
        rst_n = 0;
        #(RESET_PERIOD);
        rst_n = 1;
    end

    initial begin
        #(RESET_PERIOD * 2);
        spi_write_task(7'h01,8'h33);
        spi_read_task (7'h01);

        spi_write_burst_task(7'h02,100'd4);
        spi_read_burst_task(7'h02,100'd4);
        #1000;
        $finish;
    end

task automatic spi_write_task;
        input [6:0] spi_addr;
        input [7:0] spi_data;

        begin
            spi_addr_master = spi_addr;
            spi_data_master = 8'hff;

            wr_rd = 1'b0;
            cs_n_in = 1'b0;
            #(CLK_PERIOD * 640);  //写入 16bits * 40
            cs_n_in = 1'b1;
        end
    endtask

    task automatic spi_write_burst_task;
        input [6:0] spi_addr;
        input [99:0] burst_length;

        begin
            spi_addr_master = spi_addr;
            spi_data_master = spi_data;
            wr_rd = 1'b0;
            cs_n_in = 1'b0;
            #(CLK_PERIOD * 640);  //写入 16bits * 40
            for (i = 0; i < burst_length-1; i = i + 1) begin
                spi_data_master = i;
                #(CLK_PERIOD * 320);  //写入 8bits * 40
            end
            cs_n_in = 1'b1;
        end
    endtask

    task automatic spi_read_task;
        input [6:0] spi_addr;
        begin
            spi_addr_master = spi_addr;
            wr_rd = 1'b1;
            cs_n_in = 1'b0;
            #(CLK_PERIOD * 640); //写入 16bits * 40
            cs_n_in = 1'b1;
        end
    endtask

    task automatic spi_read_burst_task;
        input [6:0] spi_addr;
        input [99:0] burst_length;
        begin
            spi_addr_master = spi_addr;
            wr_rd = 1'b1;
            cs_n_in = 1'b0;
            #(CLK_PERIOD * 320 * burst_length);
            cs_n_in = 1'b1;
        end
    endtask
    // Monitor signals
    initial begin
        $monitor("Time: %0t | cs_n: %b | sclk: %b | mosi: %b | miso: %b | data_out: %h | data_out_vld: %b", 
                 $time, cs_n, sclk, mosi, miso, data_out, data_out_vld);
    end

endmodule
