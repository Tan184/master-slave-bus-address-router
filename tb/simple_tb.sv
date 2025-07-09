`timescale 1ns/1ps

module tb_nic_top;

  reg clk;
  reg rst;

  reg        master_sel;
  reg        master_enable;
  reg        master_wr_dir;
  reg [15:0] master_addr;
  reg [15:0] master_wdata;
  wire [15:0] master_rdata;


  nic_top uut (
    .clk           (clk),
    .rst           (rst),
    .master_sel    (master_sel),
    .master_enable (master_enable),
    .master_wr_dir (master_wr_dir),
    .master_addr   (master_addr),
    .master_wdata  (master_wdata),
    .master_rdata  (master_rdata)
  );


  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task do_transaction(
    input bit wr_dir,
    input [15:0] addr,
    input [15:0] wdata
  );
    begin
      // Cycle 1
      master_sel    = 1;
      master_wr_dir = wr_dir;
      master_addr   = addr;
      master_wdata  = wdata;
      master_enable = 0;
      @(posedge clk);

      // Cycle 2
      master_enable = 1;
      @(posedge clk);

      // Deassert
      master_sel    = 0;
      master_enable = 0;
      @(posedge clk); //Deassertion doesn't seem to matter, but this extra clock cycle does. Gives wrong output without this.
    end
  endtask


  initial begin
    // Initialize
    rst           = 1;
    master_sel    = 0;
    master_enable = 0;
    master_wr_dir = 0;
    master_addr   = 0;
    master_wdata  = 0;

    @(posedge clk);
    rst = 0;

    // Write
    $display("[%0t] WRITE: addr=0x0002, data=0xABCD", $time);
    do_transaction(1'b1, 16'h0002, 16'hABCD);

    // Read
    $display("[%0t] READ : addr=0x0002", $time);
    do_transaction(1'b0, 16'h0002, 16'h0000);

    // Record data
    #1; //To let values settle. Similar to that NIC module delay.
    $display("[%0t] READ DATA = 0x%0h", $time, master_rdata);

    // Compare
    if (master_rdata !== 16'hABCD) begin
      $display("ERROR: Expected 0xABCD, got 0x%0h", master_rdata);
    end else begin
      $display("Read-back successful.");
    end

    #10;
    $finish;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
