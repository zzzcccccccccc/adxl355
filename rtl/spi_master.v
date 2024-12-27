module spi_master(
    input         clk,
    input         rst_n,
    input         cs_n_in,
    input         miso,
    input         wr_rd,
    input  [7:0]  spi_data_master,      
    input  [6:0]  spi_addr_master,
    
    output        data_out_vld,
    output [7:0]  data_out,
    output        cs_n,
    output        sclk,         
    output        mosi        
);
reg [7:0]   bit_cnt;
reg         read_tag;
reg         cs_n_r;
reg [6:0]   clk_cnt;
reg [15:0]  data_tx_r;
reg [7:0]   data_rx_r;
reg         sclk_r;
reg         data_out_vld_r;

assign cs_n = cs_n_in;

// Divede the clk clock to generate reference clock
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        clk_cnt <= 7'b0;
    else if(clk_cnt == 7'd39)
        clk_cnt <= 7'b0;
    else 
        clk_cnt <= clk_cnt + 1'b1;
end

// set the rise time duration of sclk_r

assign sclk = sclk_r;

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        sclk_r <= 7'b0;
    else if(clk_cnt == 7'd19 || clk_cnt == 7'd39)
        sclk_r <= ~sclk_r;
end

// calculate the number of transisation bits
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        bit_cnt <= 7'b0;
    else if(cs_n_in && clk_cnt == 7'd39)
        bit_cnt <= 7'd0;
    else if(clk_cnt == 7'd39)
        bit_cnt <= bit_cnt + 1;
end

assign mosi = data_tx_r[15];

/*
如果是 read，则发送首个地址即可
如果是 write
当 cs_n 低电平时，初始状态时加载数值
隔 16 个 bits cs_n 依然时低电平，加载第二个数据
接下来每 8 bits 检测 cs_n 为低电平，就加载一次
*/


always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        data_tx_r <= 16'b0;
    else if( wr_rd == 1'd1 && !cs_n_in && bit_cnt ==7'd0)
        data_tx_r <= {spi_addr_master,1'd1,8'd0};  //read quest
    else if( wr_rd == 1'd0 && !cs_n_in && bit_cnt ==7'd0)
        data_tx_r <= {spi_addr_master,1'd0,spi_data_master}; //write quest
    else if( wr_rd == 1'd0 && !cs_n_in && bit_cnt > 7'd15 && ((bit_cnt - 15) % 8 == 1))
        data_tx_r <= {spi_data_master,8'b0};
    else if(clk_cnt == 7'd9 )
        data_tx_r <= {data_tx_r[14:0],1'd0};
end

//indicate transition bytes final
assign data_out_vld = data_out_vld_r;

always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        data_out_vld_r <= 1'b0;
    else if(bit_cnt >= 7'd15 && ((bit_cnt-15) % 8 == 0) && (clk_cnt == 7'd39 )&& (wr_rd == 1'd1))
        data_out_vld_r <= 1'b1;
    else   
        data_out_vld_r <= 1'b0;
end

assign data_out = data_rx_r;

//recieve the data frm slave 
always @ (posedge clk or negedge rst_n) begin
    if(~rst_n || cs_n_in)
        data_rx_r <= 8'b0;
    else if(bit_cnt > 7'd7 && clk_cnt == 7'd19 && read_tag)
        data_rx_r <= {data_rx_r[7:0],miso};
    
end

//indicate read
always @ (posedge clk or negedge rst_n)begin
    if(~rst_n || cs_n_in)
        read_tag <=0 ;
    else if (wr_rd)
        read_tag <= 1;
end    

endmodule
