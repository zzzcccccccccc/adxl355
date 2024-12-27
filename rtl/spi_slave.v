module spi_slave(
    input         mems_clk,
    input         sclk,
    input         rst_n,
    input         mosi,
    input         cs_n,

    input         reg_spi_rd_valid,
    input  [7:0]  reg_spi_rd_data,      
    
    output [6:0]  spi_wr_rd_addr,
    output        spi_wr_addr_valid,
    output        spi_rd_addr_valid,

    output [7:0]  spi_wr_data,
    output        spi_wr_data_valid,

    output        miso,

    output [99:0] spi_wr_burst_num,
    output [99:0] spi_rd_burst_num        
        
);

reg [9:0] count_bits;
reg [7:0] data_tx_buffer;
reg       sclk_r;


reg       reg_spi_rd_valid_r;
reg [7:0] reg_spi_rd_data_r;

reg       reg_spi_rd_valid_r_x2;

reg [6:0] data_address_buff;
reg       spi_wr_addr_valid_r;
reg       spi_rd_addr_valid_r;


reg [7:0] spi_wr_data_r;
reg       spi_wr_data_valid_r;

reg       wr_rd_r;

reg [99:0] spi_wr_burst_num_r;
reg [99:0] spi_rd_burst_num_r;

wire      wr_rd;

//寄存 sclk 上一个状态值
always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n || cs_n)
        sclk_r <= 1'b0;
    else if(sclk)
        sclk_r <= 1'b1;
    else
        sclk_r <= 1'b0;
end    

//统计加载数
always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n || cs_n)
        count_bits <= 1'b0;
    else if(sclk && !sclk_r)
        count_bits <= count_bits +1;
end    


//获取地址
assign spi_wr_rd_addr = data_address_buff;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        data_address_buff <= 7'b0;
    else if(sclk && !sclk_r) begin
        if (count_bits < 10'd7  )
            data_address_buff[6:0] <= {data_address_buff[5:0],mosi};
    end
        
end

//判断读写
assign wr_rd = wr_rd_r;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        wr_rd_r <= 1'b0;
    else if(sclk && !sclk_r) begin
        if(count_bits == 10'd7 && mosi == 1)
            wr_rd_r <= 1'b1; //read
        else if(count_bits == 10'd7 && mosi == 0)
            wr_rd_r <= 1'b0; //write
    end
end

//获取 write 地址有效
//counter 8 ,
assign spi_wr_addr_valid = spi_wr_addr_valid_r & !wr_rd;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        spi_wr_addr_valid_r <= 1'b0;
    else if(sclk && !sclk_r) begin
        if(count_bits == 4'd7 )
            spi_wr_addr_valid_r <= 1'b1;
        else
            spi_wr_addr_valid_r <= 1'b0;
    end
end

//获取 read 地址有效
//counter 6 ,
assign spi_rd_addr_valid = spi_rd_addr_valid_r & wr_rd;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        spi_rd_addr_valid_r <= 1'b0;
    else if(sclk && !sclk_r) begin
    if(count_bits == 4'd7 || (((count_bits-15)%8 == 0)&& (count_bits >10'd14)))
            spi_rd_addr_valid_r <= 1'b1;
        else
            spi_rd_addr_valid_r <= 1'b0;
    end
end


//write burst 计数情况
assign spi_wr_burst_num = spi_wr_burst_num_r;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        spi_wr_burst_num_r <= 1'b0;
    else if(sclk && !sclk_r) begin
        if(((count_bits-15)%8 == 2)&& (count_bits > 10'd14))
            spi_wr_burst_num_r <= spi_wr_burst_num_r + 1;
    end
end


//read burst 计数情况
assign spi_rd_burst_num = spi_rd_burst_num_r & {100{!(spi_wr_rd_addr == 7'h11)}};

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        spi_rd_burst_num_r <= 1'b0;
    else if(sclk && !sclk_r) begin
        if(((count_bits-15)%8 == 0)&& (count_bits > 10'd14))
            spi_rd_burst_num_r <= spi_rd_burst_num_r + 1;
    end
end


//获取写入的data值
assign spi_wr_data = spi_wr_data_r ;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n )
        spi_wr_data_r <= 8'b0;
    else if(sclk && !sclk_r) begin
        if( count_bits > 4'd7 && wr_rd==0)
            spi_wr_data_r <= {spi_wr_data_r[7:0],mosi};
    end
end

//写入有效值
assign spi_wr_data_valid = spi_wr_data_valid_r;

always @(posedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        spi_wr_data_valid_r <= 1'b0;
    else if((( (count_bits > 10'd15) & ((count_bits-15) % 8==1))) && (wr_rd_r ==0))
            spi_wr_data_valid_r <= 1'b1;
        else
            spi_wr_data_valid_r <= 1'b0;
end


// 来自 reg 模块，表示读取的数已经载入到 slave 接口
always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        reg_spi_rd_valid_r <= 1'b0;
    else if(reg_spi_rd_valid)
        reg_spi_rd_valid_r <= 1'b1;
    else
        reg_spi_rd_valid_r <= 1'b0;
end

always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        reg_spi_rd_valid_r_x2 <= 1'b0;
    else if(reg_spi_rd_valid == 1 & reg_spi_rd_valid_r == 0)
        reg_spi_rd_valid_r_x2 <= 1'b1;
    else
        reg_spi_rd_valid_r_x2 <= 1'b0;
end

// 来自 reg 模块，将载入的 data 送到寄存器中
always @(posedge mems_clk or negedge rst_n) begin
    if(~rst_n)
        reg_spi_rd_data_r <= 8'b0;
    else if(reg_spi_rd_valid)
        reg_spi_rd_data_r <= reg_spi_rd_data;
    else
        reg_spi_rd_data_r <= 8'b0;
end


//miso
assign miso = data_tx_buffer[7];

//发送
always @(negedge mems_clk or negedge rst_n)begin
    if(~rst_n || cs_n)
        data_tx_buffer <= 8'b0;
    else if(reg_spi_rd_valid_r_x2)
        data_tx_buffer <= reg_spi_rd_data_r;
    else if(sclk && !sclk_r)begin
        if(count_bits > 10'd7 )
        data_tx_buffer <= {data_tx_buffer[6:0],1'b0};
    end
end




endmodule