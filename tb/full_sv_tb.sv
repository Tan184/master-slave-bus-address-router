`timescale 1ns / 1ps

//Try adding assertions later to make debugging easier

interface nic_int(input logic clk);
  logic rst;
  logic master_sel;
  logic master_enable;
  logic master_wr_dir;
  logic [15:0] master_addr;
  logic [15:0] master_wdata;
  logic [15:0] master_rdata;

  clocking driver_cb @(posedge clk);
    output rst, master_sel, master_enable, master_wr_dir, master_addr, master_wdata;
    input master_rdata;
  endclocking

  clocking monitor_cb @(posedge clk);
    input rst, master_sel, master_enable, master_wr_dir, master_addr, master_wdata, master_rdata;
  endclocking

  modport DRIVER(
    input master_rdata,
    output rst, master_sel, master_enable, master_wr_dir, master_addr, master_wdata
  );

  modport MONITOR(
    input rst, master_sel, master_enable, master_wr_dir, master_addr, master_wdata, master_rdata
  );

endinterface

class txn;
  rand logic [15:0] addr;
  rand logic [15:0] wdata;
  logic wr_dir;
  logic [15:0] rdata;
  
  //For testing
  constraint fixed_addr { addr == 16'he32c; }

  function void display(string name);
    $display("T=%0t [%s] wr_dir = %0b, addr = %0h, wdata = %0h, rdata = %0h", $time, name, wr_dir, addr, wdata, rdata);
  endfunction

  function txn copy();
    copy = new();
    copy.addr = this.addr;
    copy.wdata = this.wdata;
    copy.wr_dir = this.wr_dir;
    copy.rdata = this.rdata;
  endfunction
endclass


class generator;
  int num = 4;
  int count = 0;
  mailbox gen2drv;
  event ended;

  function new(mailbox gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    txn t;
    int i = 0;
    repeat (num) begin
      
      t = new();
      void'(t.randomize());  //With constrained address
      
      if ((i % 2) == 0) begin //To make sure both write and read operations are conducted
        t.wr_dir = 1;  //Write first
      end else begin
        t.wr_dir = 0; //Read next
      end
      i++;
    
      t.display("GEN");
      gen2drv.put(t);
      count++;
    end
    -> ended;
  endtask
endclass


class driver;
  mailbox gen2drv;
  virtual nic_int vif;

  function new(virtual nic_int vif, mailbox gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task reset();
    wait(vif.rst);
    $display("T=%0t [Driver] Reset Started", $time);
    vif.driver_cb.master_sel <= 0;
    vif.driver_cb.master_enable <= 0;
    vif.driver_cb.master_wr_dir <= 0;
    vif.driver_cb.master_addr <= 0;
    vif.driver_cb.master_wdata <= 0;
    wait(!vif.rst);
    $display("T=%0t [Driver] Reset Ended", $time);
  endtask

  task run();
    forever begin
      txn t;
      gen2drv.get(t);
      drive_txn(t);
    end
  endtask

  task drive_txn(txn t);
    @(vif.driver_cb);
    vif.driver_cb.master_sel    <= 1;
    vif.driver_cb.master_enable <= 0;
    vif.driver_cb.master_wr_dir <= t.wr_dir;
    vif.driver_cb.master_addr   <= t.addr;
    vif.driver_cb.master_wdata  <= t.wdata;

    @(vif.driver_cb);
    vif.driver_cb.master_enable <= 1;
    t.display("DRV");
    
	#1; //To let values settle
    // Reset signals after both write and read operations
    vif.driver_cb.master_sel    <= 0;
    vif.driver_cb.master_enable <= 0;
    vif.driver_cb.master_wr_dir <= 0;
    vif.driver_cb.master_addr   <= 0;
    vif.driver_cb.master_wdata  <= 0;
    @(vif.driver_cb);
  endtask
endclass


class monitor;
  mailbox mon2scr;
  virtual nic_int vif;

  function new(virtual nic_int vif, mailbox mon2scr);
    this.vif = vif;
    this.mon2scr = mon2scr;
  endfunction

  task run();
    forever begin
      txn t = new();
      @(vif.monitor_cb);
      wait(vif.monitor_cb.master_sel);
      t.addr   = vif.monitor_cb.master_addr;
      t.wr_dir = vif.monitor_cb.master_wr_dir;
      t.wdata  = vif.monitor_cb.master_wdata;
      wait(vif.monitor_cb.master_enable);
      if (!t.wr_dir) begin
        @(vif.monitor_cb);
        t.rdata = vif.monitor_cb.master_rdata;
      end
      t.display("MON");
      mon2scr.put(t);
    end
  endtask
endclass

class scoreboard;
  mailbox mon2scr;
  int num_transactions;
  bit [15:0] ref_mem [bit[15:0]];

  function new(mailbox mon2scr);
    this.mon2scr = mon2scr;
  endfunction

  task run();
    forever begin
      txn t;
      mon2scr.get(t);

      if (t.wr_dir) begin
        ref_mem[t.addr] = t.wdata;
        $display("T=%0t [SCR] WRITE: addr=0x%0h, data=0x%0h", $time, t.addr, t.wdata);
      end else begin
        bit[15:0] expected_data;
        if(ref_mem.exists(t.addr)) begin //There should actually be something in there. Will give error/tell if not.
          expected_data = ref_mem[t.addr];
        end else begin
          expected_data = 16'h0000;
        end

        if(t.rdata == expected_data) begin
          $display("T=%0t [SCR] READ PASS: addr=0x%0h, expected=0x%0h, got=0x%0h", $time, t.addr, expected_data, t.rdata);
        end else begin
          $display("T=%0t [SCR] READ FAIL: addr=0x%0h, expected=0x%0h, got=0x%0h", $time, t.addr, expected_data, t.rdata);
        end
      end
      
      num_transactions++;
    end
  endtask
endclass

class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scr;

  mailbox gen2drv;
  mailbox mon2scr;

  virtual nic_int vif;

  function new(virtual nic_int vif);
    this.vif = vif;
    gen2drv = new();
    mon2scr = new();
    gen = new(gen2drv);
    drv = new(vif, gen2drv);
    mon = new(vif, mon2scr);
    scr = new(mon2scr);
  endfunction

  task reset();
    drv.reset();
  endtask

  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      scr.run();
    join_none
  endtask

  task post_test();
    wait(gen.ended.triggered); //To make sure all txns have been generated
    wait(gen.count == scr.num_transactions); //To make sure all txnx have passed through the system
    $display("T=%0t [ENV] Test Completed", $time);
  endtask

  task run();
    reset();
    test();
    post_test();
    $finish;
  endtask
endclass

class test;
  environment env;
  function new(virtual nic_int vif);
    env = new(vif);
  endfunction

  task run();
    env.run();
  endtask
endclass

module testbench;
  logic clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  nic_int vif(clk);

  nic_top dut(
    .clk(clk),
    .rst(vif.rst),
    .master_sel(vif.master_sel),
    .master_enable(vif.master_enable),
    .master_wr_dir(vif.master_wr_dir),
    .master_addr(vif.master_addr),
    .master_wdata(vif.master_wdata),
    .master_rdata(vif.master_rdata)
  );

  initial begin
    test t0;
    vif.rst <= 1;
    #10;
    vif.rst <= 0;
    t0 = new(vif);
    t0.run();
  end

  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
  end
endmodule
