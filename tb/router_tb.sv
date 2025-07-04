`timescale 1ns / 1ps

module testbench();
  logic clk, rst;
  
  logic master_sel, master_enable, master_wr_dir;
  logic [15:0] master_addr;
  logic [15:0] master_wdata;
  logic [15:0] master_rdata;
  
  logic slave0_sel, slave0_enable, slave0_wr_dir;
  logic [13:0] slave0_addr;
  logic [15:0] slave0_wdata;
  logic [15:0] slave0_rdata;
  
  logic slave1_sel, slave1_enable, slave1_wr_dir;
  logic [13:0] slave1_addr;
  logic [15:0] slave1_wdata;
  logic [15:0] slave1_rdata;

  logic slave2_sel, slave2_enable, slave2_wr_dir;
  logic [13:0] slave2_addr;
  logic [15:0] slave2_wdata;
  logic [15:0] slave2_rdata;

  logic slave3_sel, slave3_enable, slave3_wr_dir;
  logic [13:0] slave3_addr;
  logic [15:0] slave3_wdata;
  logic [15:0] slave3_rdata;

  router dut(
    .clk(clk),
    .rst(rst),

    .master_sel(master_sel),
    .master_enable(master_enable),
    .master_wr_dir(master_wr_dir),
    .master_addr(master_addr),
    .master_wdata(master_wdata),
    .master_rdata(master_rdata),

    .slave0_sel(slave0_sel),
    .slave0_enable(slave0_enable),
    .slave0_wr_dir(slave0_wr_dir),
    .slave0_addr(slave0_addr),
    .slave0_wdata(slave0_wdata),
    .slave0_rdata(slave0_rdata),

    .slave1_sel(slave1_sel),
    .slave1_enable(slave1_enable),
    .slave1_wr_dir(slave1_wr_dir),
    .slave1_addr(slave1_addr),
    .slave1_wdata(slave1_wdata),
    .slave1_rdata(slave1_rdata),

    .slave2_sel(slave2_sel),
    .slave2_enable(slave2_enable),
    .slave2_wr_dir(slave2_wr_dir),
    .slave2_addr(slave2_addr),
    .slave2_wdata(slave2_wdata),
    .slave2_rdata(slave2_rdata),

    .slave3_sel(slave3_sel),
    .slave3_enable(slave3_enable),
    .slave3_wr_dir(slave3_wr_dir),
    .slave3_addr(slave3_addr),
    .slave3_wdata(slave3_wdata),
    .slave3_rdata(slave3_rdata)
  );

  //Simulated slave memories
  logic [15:0] mem0 [0:16383];
  logic [15:0] mem1 [0:16383];
  logic [15:0] mem2 [0:16383];
  logic [15:0] mem3 [0:16383];
  
  wire [1:0] slave_select = master_addr[15:14];
  wire [13:0] local_addr  = master_addr[13:0];

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //Write happens when sel=1, wr_dir=1.
  always_ff @(posedge clk) begin
    if (master_sel && master_wr_dir) begin
      case (slave_select)
        2'b00: mem0[local_addr] <= master_wdata;
        2'b01: mem1[local_addr] <= master_wdata;
        2'b10: mem2[local_addr] <= master_wdata;
        2'b11: mem3[local_addr] <= master_wdata;
      endcase
    end
  end

  //Read only happens when sel=1, en=1, wr_dir=0.
  always_comb begin
    if (master_sel && master_enable && !master_wr_dir) begin
      case (slave_select)
        2'b00: slave0_rdata = mem0[local_addr];
        2'b01: slave1_rdata = mem1[local_addr];
        2'b10: slave2_rdata = mem2[local_addr];
        2'b11: slave3_rdata = mem3[local_addr];
      endcase
    end
  end

  // Write operation
  task write_operation(input [15:0] addr, input [15:0] data);
  begin
    @(posedge clk);
    master_sel = 1;
    master_wr_dir = 1;
    master_enable = 0;
    master_addr = addr;
    master_wdata = data;

    @(posedge clk);
    master_enable = 1;

    $display($time, " WRITE: Addr=0x%04X Data=0x%04X | S0_sel=%b S1_sel=%b S2_sel=%b S3_sel=%b",
      addr, data, slave0_sel, slave1_sel, slave2_sel, slave3_sel);
    
    //master_sel = 0; //To reset values for next operation
    //master_enable = 0;
    //master_wr_dir = 0;
    
  end
  endtask

  // Read operation
  task read_operation(input [15:0] addr, input [15:0] expected);
    fork
     
      begin
        @(posedge clk);
        master_sel = 1;
        master_wr_dir = 0;
        master_enable = 0;
        master_addr = addr;

        @(posedge clk);
        master_enable = 1;
      end
      
      begin
        @(posedge clk)
        wait(master_sel == 1 && master_enable == 1);
        
        #1; //To let non-blocking assignments settle.
        $display($time, " READ : Addr=0x%04X Data=0x%04X (expected=0x%04X) | S0_sel=%b S1_sel=%b S2_sel=%b S3_sel=%b",
                 addr, master_rdata, expected, slave0_sel, slave1_sel, slave2_sel, slave3_sel);

        if (master_rdata !== expected)
          $display("ERROR: Above data mismatched");
    
      //master_sel = 0; //To reset values for next operation
      //master_enable = 0;
      end
    join
  endtask

  // Test sequence
  initial begin
    //Reset
    @(posedge clk);
    rst = 1;
    master_sel = 0;
    master_enable = 0;
    master_wr_dir = 0;
    master_addr = 16'h0000;
    master_wdata = 16'h0000;

    @(posedge clk);
    rst = 0;

    //Write
    write_operation(16'h1030, 16'h1111);
    write_operation(16'h4591, 16'h2222);
    write_operation(16'h9000, 16'h3333);
    write_operation(16'hC00E, 16'h4444);

    //@(posedge clk);

    //Read
    read_operation(16'h1030, 16'h1111);
    read_operation(16'h4591, 16'h2222);
    read_operation(16'h9000, 16'h3333);
    read_operation(16'hC00E, 16'h4444);

    $finish;
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, testbench);
  end

endmodule
