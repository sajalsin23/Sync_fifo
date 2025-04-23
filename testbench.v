`timescale 1ns / 1ps

module tb_Synchronous_FIFO;

  parameter WIDTH = 32;
  parameter DEPTH = 16;

  reg clk, reset;
  reg wr_en, rd_en;
  reg [WIDTH-1:0] data_in;
  wire [WIDTH-1:0] data_out;
  wire full, empty;

  // Instantiate FIFO
  Synchronous_FIFO #(WIDTH, DEPTH) dut (
    .clk(clk),
    .reset(reset),
    .d_in(data_in),
    .w_enb(wr_en),
    .r_enb(rd_en),
    .d_out(data_out),
    .full(full),
    .empty(empty)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // VCD dump
  initial begin
    $dumpfile("fifo_simple.vcd");
    $dumpvars(0, tb_Synchronous_FIFO);
  end

  // Main test procedure
  initial begin
    reset = 0; wr_en = 0; rd_en = 0; data_in = 0;
    #10 reset = 1; // Apply reset

    // ✅ 1. Write data into FIFO
    repeat (DEPTH) begin
      @(posedge clk);
      wr_en = 1;
      data_in = $random;
    end
    @(posedge clk); wr_en = 0;
    $display("Write done. Full = %b", full);

$display("\n--- Overflow test (write beyond full) ---");
    @(posedge clk);
    wr_en = 1; data_in = 32'hDEADBEEF;
    @(posedge clk);
    wr_en = 0;
    if (full)
      $display("Overflow blocked correctly (no write occurred).");
    else
      $display("⚠️ Overflow error: FIFO accepted data when full!");

    $display("\n--- Read until EMPTY ---");

    // ✅ 2. Read data from FIFO
    repeat (DEPTH) begin
      @(posedge clk);
      rd_en = 1;
    end
    @(posedge clk); rd_en = 0;
    $display("Read done. Empty = %b", empty);

    $display("\n--- Underflow test (read beyond empty) ---");
    @(posedge clk);
    rd_en = 1;
    @(posedge clk);
    rd_en = 0;
    if (empty)
      $display("Underflow blocked correctly (no read occurred).");
    else
      $display("⚠️ Underflow error: Read occurred when FIFO was empty!");

    $display("\n--- Simultaneous write/read ---");
    data_in = 32'hAABBCCDD;
    
    // ✅ 3. Simultaneous write & read
    @(posedge clk);
    wr_en = 1; rd_en = 1;
    @(posedge clk);
    wr_en = 0; rd_en = 0;
    $display("Simultaneous write/read tested.");

    $display("\n--- Reset check ---");
    // ✅ 4. Reset check
    @(posedge clk); reset = 0;
    @(posedge clk); reset = 1;
    if (empty && !full)
      $display("Reset successful. FIFO is empty.");
    else
      $display("⚠️ Reset error: FIFO not cleared correctly!");

    #10 $finish;
  end

endmodule
