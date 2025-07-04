`timescale 1ns / 1ps

module testbench();
  
  logic clk, rst, sel, enable, wr_dir;
  logic [15:0] addr;
  logic [15:0] wdata;
  logic [15:0] rdata;
  
  slave dut(
    .clk(clk),
    .rst(rst),
    .sel(sel),
    .enable(enable),
    .wr_dir(wr_dir),
    .addr(addr),
    .wdata(wdata),
    .rdata(rdata)
  );
  
  initial begin 
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin 
    //Initialize reset
    rst = 1;
    sel = 0;
    enable = 0;
    wr_dir = 0;
    addr = 0;
    wdata = 0;
    @(posedge clk);
    rst = 0;
  end
  
  initial begin 
    @(negedge rst);
    @(posedge clk);
    
    //Write operation
    sel = 1;
    enable = 0;  
    wr_dir = 1;
    addr = 16'h1234;
    wdata = 16'h1111;
    @(posedge clk);  
    
    enable = 1;  
    @(posedge clk); 
    
    
    //Read operation
    enable = 0;  
    wr_dir = 0;
    @(posedge clk); 
    
    enable = 1;  
    @(posedge clk);  
    //@(posedge clk); 
    
    if (rdata !== 16'h1111) begin
      $display("ERROR: Expected 1111, got %h.", rdata);
    end else begin
      $display("OK: Data match for first address");
    end
    
    
    //Write to new address
    enable = 0;  
    wr_dir = 1;
    addr = 16'h0110;
    wdata = 16'h3FFF;
    @(posedge clk);  
    
    enable = 1;  
    @(posedge clk);  
    
    
    //Read from new address
    enable = 0; 
    wr_dir = 0;
    @(posedge clk); 
    
    enable = 1; 
    @(posedge clk);  
    //@(posedge clk);
    
    if (rdata !== 16'h3FFF) begin
      $display("ERROR: New address read mismatch. Expected 3FFF, got %h.", rdata);
    end else begin
      $display("OK: New address data matches");
    end
    
    
    //Reset test
    rst = 1;
    @(posedge clk);
    if (rdata !== 16'h0000) begin
      $display("ERROR: Reset failed, received %h", rdata);
    end else begin
      $display("OK: Reset works");
    end
    @(posedge clk);
    $finish;
  end
  
  initial begin 
    $dumpfile("waveform.vcd");
    $dumpvars();
  end
  
endmodule
