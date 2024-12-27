module synchronous_fifo#(
    parameter   DATA_WIDTH = 24,
    parameter   ADDR_WIDTH = 4,
    parameter   DEPTH = 1 << ADDR_WIDTH
)(
    input                      clk,
    input                      rst_n,
    input                      wr_en,
    input                      reg_fifo_read_en,
    input  [DATA_WIDTH-1:0]    filter_fifo_data,

    output                     full,    
    output                     empty,    
    output [DATA_WIDTH-1:0]    fifo_reg_data,
    output                     fifo_reg_data_valid,
    output [DEPTH-1:0]         fifo_sample_num
);
    integer                 i;   
    reg [DATA_WIDTH-1:0]    fifo_reg_data_r;
    reg [DATA_WIDTH-1:0]    fifo_reg_data;
    reg [ADDR_WIDTH:0]    wr_ptr;
    reg [ADDR_WIDTH:0]    rd_ptr;
    reg [DATA_WIDTH-1:0]    ram[DEPTH-1:0];
    reg                     fifo_reg_data_valid_r;
    reg                     reg_fifo_read_en_r;
    reg                     rd_en_r;
    reg [DEPTH-1:0]         fifo_sample_num_r;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_fifo_read_en_r <= 0;
        end else if (reg_fifo_read_en)
            reg_fifo_read_en_r <=  1 ;
        else
            reg_fifo_read_en_r <= 0;

    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en_r <= 0;
        end else if (!reg_fifo_read_en_r && reg_fifo_read_en)
            rd_en_r <= 1 ;
        else
            rd_en_r <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en)
            wr_ptr <= wr_ptr + 1 ;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (wr_en && full)
            rd_ptr <= rd_ptr + 1 ;
        else if (rd_en_r)
            rd_ptr <= rd_ptr + 1 ;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0;i < DEPTH;i++)
                ram[i] <= {DATA_WIDTH{1'b0}};
        end else if (wr_en)
            ram[wr_ptr] <= filter_fifo_data;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_reg_data_r <= 0;
        end else if (rd_en_r)
            fifo_reg_data_r <= ram[rd_ptr] ;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_sample_num_r <= 0;
        else if (full)
            fifo_sample_num_r <= DEPTH;
        else if (wr_en && !rd_en_r)  
            fifo_sample_num_r <= fifo_sample_num_r + 1'b1;
        else if (rd_en_r && !wr_en)  
            fifo_sample_num_r <= fifo_sample_num_r - 1'b1;
    end

    assign fifo_reg_data = fifo_reg_data_r;
    assign empty    = wr_ptr == rd_ptr;
    assign full     = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) && (wr_ptr[ADDR_WIDTH]!=rd_ptr[ADDR_WIDTH]);
    assign fifo_sample_num = fifo_sample_num_r;


endmodule