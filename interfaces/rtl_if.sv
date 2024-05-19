// rtl_if.sv

interface rtl_if
  import dataTypes::*;
  ();

  logic CLK;
  logic RESET;
  logic clear;
  logic rd_en;
  logic wr_en;
  data_packet_sp wr_data;
  data_packet_sp rd_data;
  logic fifo_empty;
  logic fifo_full;
  logic error;

  modport dut (
    input CLK, RESET, clear, rd_en, wr_en, wr_data,
    output rd_data, fifo_empty, fifo_full, error
  );

  modport cov (
    input CLK, RESET, clear, rd_en, wr_en, wr_data, rd_data, fifo_empty, fifo_full, error
  );

  initial begin : CLK_driver
    CLK = 0;
    forever #(CLOCK_PERIOD/2) CLK = ~CLK;
  end : CLK_driver

  /*initial begin
    	$monitor("%t  %t   RST=%b  clear = %b   wr_en = %b   wr_data = %x   rd_en = %b   rd_data = %x   fifo_empty = %b   fifo_full = %b  error = %b", $time/CLOCK_PERIOD, $time, RESET, clear, wr_en, wr_data, rd_en, rd_data, fifo_empty, fifo_full, error);
  end*/
  
  //RESET task
  task reset_FIFO();
	//RESET = 1'b0;	wr_en = 1'b0;	rd_en = 1'b0;	clear = 1'b0;	wr_data = '0;
	//repeat(RESET_CYCLES)@(negedge CLK);
  	RESET = 1'b1;	wr_en = 1'b0;	rd_en = 1'b0;	clear = 1'b0;	wr_data = '0;
	repeat(RESET_CYCLES)@(negedge CLK);
  endtask : reset_FIFO

  //Single write task
  task write_FIFO(input data_packet_sp writedata);
	RESET = 1'b0;	rd_en = 1'b0;	wr_en = 1'b1;	clear = 1'b0;	
	wr_data = writedata;
        @(negedge CLK);	
  endtask : write_FIFO

  //Single read task
  task read_FIFO();
	rd_en = 1'b1;	wr_en = 1'b0;	clear = 1'b0;	RESET = 1'b0;	
        @(negedge CLK);
  endtask : read_FIFO

  //Single clear task
  task clear_FIFO();
	RESET = 1'b0;	rd_en = 1'b0;	wr_en = 1'b0;	clear = 1'b1;
        @(negedge CLK);	
  endtask : clear_FIFO

  //Bypass task
  task bypass_FIFO(input data_packet_sp writedata);
	read_until_empty();
	RESET = 1'b0;	rd_en = 1'b1;	wr_en = 1'b1;	clear = 1'b0;
	wr_data = writedata;
        @(negedge CLK);	
  endtask : bypass_FIFO

  //Read until empty task
  task read_until_empty();
	repeat(FIFO_SIZE) read_FIFO();
  endtask : read_until_empty

  //Clear until empty task
  task clear_until_empty();
	repeat(FIFO_SIZE) clear_FIFO();
  endtask : clear_until_empty

  //Back to back read task
  task read_back2back(input int readloop);
	repeat(readloop) read_FIFO();
  endtask : read_back2back

  //Back to back clear task
  task clear_back2back(input int loop);
	repeat(loop) clear_FIFO();
  endtask : clear_back2back
 
  //Multiple Read and then reset task
  task read_reset_back2back(input int readloop);
	repeat(readloop) read_FIFO();
	reset_FIFO();
  endtask : read_reset_back2back

  //Multiple Read and then multiple clear task 
  task read_clear_back2back(input int readloop, clearloop);
	repeat(readloop) read_FIFO();
	repeat(clearloop) clear_FIFO();
  endtask : read_clear_back2back

  //Multiple Clear and then reset task
  task clear_reset_back2back(input int clearloop);
	repeat(clearloop) clear_FIFO();
	reset_FIFO();
  endtask : clear_reset_back2back

  //Multiple Clear and then multiple read task 
  task clear_read_back2back(input int readloop, clearloop);
	repeat(clearloop) clear_FIFO();
	repeat(readloop) read_FIFO();
  endtask : clear_read_back2back

  //Reset and then multiple clear task
  task reset_clear_back2back(input int clearloop);
	reset_FIFO();
	repeat(clearloop) clear_FIFO();
  endtask : reset_clear_back2back

  //Reset and then multiple read task
  task reset_read_back2back(input int readloop);
	reset_FIFO();
	repeat(readloop) read_FIFO();
  endtask : reset_read_back2back


  //FIFO empty and read task
  task fifoempty_read();
	read_until_empty();
	repeat($urandom_range(1,8))read_FIFO();
  endtask : fifoempty_read

  //FIFO empty and clear task
  task fifoempty_clear();
	read_until_empty();
	clear_FIFO();
  endtask : fifoempty_clear

  //FIFO empty and read and clear task
  task fifoempty_read_clear();
	read_until_empty();
	clear = 1'b1;
	@(negedge CLK);
  endtask : fifoempty_read_clear

  //write and clear task
  task write_clear_conc();
	RESET = 1'b0;	rd_en = 1'b0;	wr_en = 1'b1;	clear = 1'b1;
	@(negedge CLK);
  endtask : write_clear_conc

  //Reset and other control signal task
  task reset_other_conc();
	RESET = 1'b1;	rd_en = 1'b1;	wr_en = 1'b1;	clear = 1'b1;
	@(negedge CLK);
  endtask : reset_other_conc

  //random inputs task
  task random_input(input data_packet_sp writedata, input logic wren, rden, clr, rst);
	RESET = rst;	rd_en = rden;	wr_en = wren;	clear = clr;
	@(negedge CLK);
  endtask : random_input

endinterface : rtl_if
