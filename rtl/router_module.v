// router
module router(
  input wire clk,
  input wire rst,

  // Master
  input wire master_sel,
  input wire master_enable,
  input wire master_wr_dir,
  input wire [15:0] master_addr,
  input wire [15:0] master_wdata,
  output reg [15:0] master_rdata,

  // Slave 0
  output reg slave0_sel,
  output reg slave0_enable,
  output reg slave0_wr_dir,
  output reg [13:0] slave0_addr,
  output reg [15:0] slave0_wdata,
  input wire [15:0] slave0_rdata,

  // Slave 1
  output reg slave1_sel,
  output reg slave1_enable,
  output reg slave1_wr_dir,
  output reg [13:0] slave1_addr,
  output reg [15:0] slave1_wdata,
  input wire [15:0] slave1_rdata,

  // Slave 2
  output reg slave2_sel,
  output reg slave2_enable,
  output reg slave2_wr_dir,
  output reg [13:0] slave2_addr,
  output reg [15:0] slave2_wdata,
  input wire [15:0] slave2_rdata,

  // Slave 3
  output reg slave3_sel,
  output reg slave3_enable,
  output reg slave3_wr_dir,
  output reg [13:0] slave3_addr,
  output reg [15:0] slave3_wdata,
  input wire [15:0] slave3_rdata
);

  wire [1:0] slave_select = master_addr[15:14];// causing delay & issues
  //wire [13:0] local_addr = master_addr[13:0]; 

  always @(posedge clk /*or posedge rst*/) begin //implement synchronous reset
    if (rst) begin
      // Reset all slave signals and master read data
      slave0_sel    <= 1'b0;
      slave0_enable <= 1'b0;
      slave0_wr_dir <= 1'b0;
      slave0_addr   <= 14'h0000;
      slave0_wdata  <= 16'h0000;

      slave1_sel    <= 1'b0;
      slave1_enable <= 1'b0;
      slave1_wr_dir <= 1'b0;
      slave1_addr   <= 14'h0000;
      slave1_wdata  <= 16'h0000;

      slave2_sel    <= 1'b0;
      slave2_enable <= 1'b0;
      slave2_wr_dir <= 1'b0;
      slave2_addr   <= 14'h0000;
      slave2_wdata  <= 16'h0000;

      slave3_sel    <= 1'b0;
      slave3_enable <= 1'b0;
      slave3_wr_dir <= 1'b0;
      slave3_addr   <= 14'h0000;
      slave3_wdata  <= 16'h0000;

      master_rdata  <= 16'h0000;
      
    end else begin
      
      {slave3_sel, slave2_sel, slave1_sel, slave0_sel}    <= (master_sel<<master_addr[15:14]);
      {slave3_enable, slave2_enable, slave1_enable, slave0_enable} <= (master_enable<<master_addr[15:14]);
      {slave3_wr_dir, slave2_wr_dir, slave1_wr_dir, slave0_wr_dir} <= (master_wr_dir<<master_addr[15:14]);
      {slave3_addr, slave2_addr, slave1_addr, slave0_addr}   <= (master_addr[13:0] << (14*master_addr[15:14]));
      {slave3_wdata, slave2_wdata, slave1_wdata, slave0_wdata}  <= (master_wdata << (16*master_addr[15:14]));
      
      case (slave_select)	
        2'b00: begin // Slave 0
          master_rdata  <= slave0_rdata; // read
        end

        2'b01: begin // Slave 1
          master_rdata  <= slave1_rdata; // read
        end

        2'b10: begin // Slave 2
          master_rdata  <= slave2_rdata; // read
        end

        2'b11: begin // Slave 3
          master_rdata  <= slave3_rdata; // read
        end

        default: begin
          master_rdata <= 16'h0000;
        end   
      endcase
    end
  end
  
  /*always @* begin //can try instead of above case block - not verified
    if (master_sel && master_enable && !master_wr_dir) begin
      case (slave_select)
        2'b00: master_rdata = slave0_rdata;
        2'b01: master_rdata = slave1_rdata;
        2'b10: master_rdata = slave2_rdata;
        2'b11: master_rdata = slave3_rdata;
        default: master_rdata = 16'h0000;
      endcase
    end else begin
      master_rdata = 16'h0000;
    end
  end*/

endmodule
