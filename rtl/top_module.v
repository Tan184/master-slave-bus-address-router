//Slave module

module slave(
  input wire clk,
  input wire rst,
  input wire sel,
  input wire enable,
  input wire wr_dir, //0 for read, 1 for write
  input wire [13:0] addr,
  input wire [15:0] wdata,
  output reg [15:0] rdata
);
  
  reg [15:0] memory [16383:0]; //16K memory elements, each 16 bits wide
  integer i;
    
  always @(posedge clk or posedge rst) begin
    if (rst) begin //Reset
      rdata <= {16{1'b0}};
    end
    else if (sel) begin
      if (wr_dir) begin //Write
        // Write happens immediately when wr_dir is 1, regardless of enable
        memory[addr] <= wdata;
      end else if (wr_dir == 0 && enable) begin //Read
        // Read only happens when enable is 1 (second cycle)
        rdata <= memory[addr];
      end
    end
  end
endmodule


//___________________________________________________________________
//___________________________________________________________________


// NIC module

// NIC module
module nic(
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

  wire [1:0] slave_select = master_addr[15:14];

  always @(posedge clk) begin
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
      
      // Only propagate wdata during write operations
      if (master_wr_dir) begin
        {slave3_wdata, slave2_wdata, slave1_wdata, slave0_wdata}  <= (master_wdata << (16*master_addr[15:14]));
      end
      
      case (slave_select)
        2'b00: begin
          master_rdata  <= slave0_rdata;
        end

        2'b01: begin
          master_rdata  <= slave1_rdata;
        end

        2'b10: begin
          master_rdata  <= slave2_rdata;
        end

        2'b11: begin
          master_rdata  <= slave3_rdata;
        end

        default: begin
          master_rdata <= 16'h0000;
        end   
      endcase
    end
  end

endmodule


//___________________________________________________________________
//___________________________________________________________________


module nic_top(
  input wire clk,
  input wire rst,
  
  input wire master_sel,
  input wire master_enable,
  input wire master_wr_dir,
  input wire [15:0] master_addr,
  input wire [15:0] master_wdata,
  output reg [15:0] master_rdata
);
  
  //Slave signals
  wire slave0_sel, slave0_enable, slave0_wr_dir;
  wire [13:0] slave0_addr;
  wire [15:0] slave0_wdata, slave0_rdata;
  
  wire slave1_sel, slave1_enable, slave1_wr_dir;
  wire [13:0] slave1_addr;
  wire [15:0] slave1_wdata, slave1_rdata;
  
  wire slave2_sel, slave2_enable, slave2_wr_dir;
  wire [13:0] slave2_addr;
  wire [15:0] slave2_wdata, slave2_rdata;
  
  wire slave3_sel, slave3_enable, slave3_wr_dir;
  wire [13:0] slave3_addr;
  wire [15:0] slave3_wdata, slave3_rdata;
  
  nic nic_module(
    .clk(clk),
    .rst(rst),
    
    // Master interface
    .master_sel(master_sel),
    .master_enable(master_enable),
    .master_wr_dir(master_wr_dir),
    .master_addr(master_addr),
    .master_wdata(master_wdata),
    .master_rdata(master_rdata),
    
    // Slave 0 interface
    .slave0_sel(slave0_sel),
    .slave0_enable(slave0_enable),
    .slave0_wr_dir(slave0_wr_dir),
    .slave0_addr(slave0_addr),
    .slave0_wdata(slave0_wdata),
    .slave0_rdata(slave0_rdata),
    
    // Slave 1 interface
    .slave1_sel(slave1_sel),
    .slave1_enable(slave1_enable),
    .slave1_wr_dir(slave1_wr_dir),
    .slave1_addr(slave1_addr),
    .slave1_wdata(slave1_wdata),
    .slave1_rdata(slave1_rdata),
    
    // Slave 2 interface
    .slave2_sel(slave2_sel),
    .slave2_enable(slave2_enable),
    .slave2_wr_dir(slave2_wr_dir),
    .slave2_addr(slave2_addr),
    .slave2_wdata(slave2_wdata),
    .slave2_rdata(slave2_rdata),
    
    // Slave 3 interface
    .slave3_sel(slave3_sel),
    .slave3_enable(slave3_enable),
    .slave3_wr_dir(slave3_wr_dir),
    .slave3_addr(slave3_addr),
    .slave3_wdata(slave3_wdata),
    .slave3_rdata(slave3_rdata)
  );
  
  //Slave 0
  slave slave_0(
    .clk(clk),
    .rst(rst),
    
    .sel(slave0_sel),
    .enable(slave0_enable),
    .wr_dir(slave0_wr_dir),
    .addr(slave0_addr),
    .wdata(slave0_wdata),
    .rdata(slave0_rdata)
  );
  
  //Slave 1
  slave slave_1(
    .clk(clk),
    .rst(rst),
    
    .sel(slave1_sel),
    .enable(slave1_enable),
    .wr_dir(slave1_wr_dir),
    .addr(slave1_addr),
    .wdata(slave1_wdata),
    .rdata(slave1_rdata)
  );
  
  //Slave 2
  slave slave_2(
    .clk(clk),
    .rst(rst),
    
    .sel(slave2_sel),
    .enable(slave2_enable),
    .wr_dir(slave2_wr_dir),
    .addr(slave2_addr),
    .wdata(slave2_wdata),
    .rdata(slave2_rdata)
  );
  
  //Slave 3
  slave slave_3(
    .clk(clk),
    .rst(rst),
    
    .sel(slave3_sel),
    .enable(slave3_enable),
    .wr_dir(slave3_wr_dir),
    .addr(slave3_addr),
    .wdata(slave3_wdata),
    .rdata(slave3_rdata)
  );
  
endmodule
