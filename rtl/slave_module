//Slave
module slave(
  input wire clk,
  input wire rst,
  input wire sel,
  input wire enable,
  input wire wr_dir, //0 for read, 1 for write
  input wire [15:0] addr,
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
