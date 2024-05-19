import dataTypes::*;

class random_packet;
	rand bit [DATA_WIDTH-1 : 0] data;
	constraint c {
    		data dist { 0:=40, [1:MAX_DATA-1]:=20, MAX_DATA:=40 };
  	}
endclass : random_packet

class tester;
	virtual rtl_if vif;
  	random_packet test_packet;

  	function new(virtual rtl_if top_if);
    		vif = top_if;
  	endfunction : new

	task execute();
		vif.reset_FIFO();
		repeat(1000) begin
			randsequence(stimulus)
				stimulus: reset | write | read | clear | bypass | write_full | read_empty | clear_empty | write_back2back | read_back2back | clear_back2back | bypass_back2back | write_clear | write_read | write_reset | read_write | read_clear |read_reset | clear_read | clear_write | clear_reset | reset_read | reset_write | reset_clear | fifoempty_read | fifoempty_clear | fifofull_write | fifoempty_rdclr | write_clr_conc | reset_other_con | random_inp;
				reset:		{vif.reset_FIFO();};
				write: 		{ test_packet = new(); 
						assert(test_packet.randomize()); 
						vif.write_FIFO(test_packet.data); };
						
				read: 		{vif.read_FIFO();};
				
				clear: 		{vif.clear_FIFO();};
				
				bypass: 	{test_packet = new(); 
						assert(test_packet.randomize());
						vif.bypass_FIFO(test_packet.data);};
						
				write_full: 	{repeat(FIFO_SIZE) begin test_packet = new();
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				read_empty: 	{vif.read_until_empty();};
				
				clear_empty:	{vif.clear_until_empty();};
				
				write_back2back:{repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				read_back2back:	{vif.read_back2back($urandom_range(1,FIFO_SIZE));};
				
				clear_back2back:{vif.clear_back2back($urandom_range(1,FIFO_SIZE));};

				bypass_back2back:{repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.bypass_FIFO(test_packet.data); end};
				
				write_clear:	{repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end
						repeat($urandom_range(1,FIFO_SIZE)) vif.clear_FIFO();};
				
				write_read:	{repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end
						repeat($urandom_range(1,FIFO_SIZE)) vif.read_FIFO();};
				
				write_reset:	{repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end
						vif.reset_FIFO();};
				
				read_write:	{repeat($urandom_range(1,FIFO_SIZE)) vif.clear_FIFO();
						repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				read_clear:	{vif.read_clear_back2back($urandom_range(1, FIFO_SIZE),$urandom_range(1, FIFO_SIZE));};					
				
				read_reset:	{vif.read_reset_back2back($urandom_range(1, FIFO_SIZE));};
				
				clear_write:	{repeat($urandom_range(1,FIFO_SIZE)) vif.clear_FIFO();
						repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				clear_read:	{vif.clear_read_back2back($urandom_range(1,FIFO_SIZE), $urandom_range(1, FIFO_SIZE));};
				
				clear_reset:	{vif.clear_reset_back2back($urandom_range(1, FIFO_SIZE));};
				
				reset_write:	{vif.reset_FIFO();
						repeat($urandom_range(1,FIFO_SIZE)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				reset_read:	{vif.reset_read_back2back($urandom_range(1, FIFO_SIZE));};
				
				reset_clear:	{vif.reset_clear_back2back($urandom_range(1, FIFO_SIZE));};
				
				fifoempty_read: {vif.fifoempty_read();};
				
				fifoempty_clear:{vif.fifoempty_clear();};
				
				fifoempty_rdclr:{vif.fifoempty_read_clear();};
				
				fifofull_write: {repeat($urandom_range(FIFO_SIZE+1, FIFO_SIZE+4)) begin test_packet = new(); 
						assert(test_packet.randomize());
						vif.write_FIFO(test_packet.data); end};
				
				write_clr_conc: {vif.write_clear_conc();};
				
				reset_other_con:{vif.reset_other_conc();};
				
				random_inp:	{test_packet = new();
						assert(test_packet.randomize());
						randomize_control();
						vif.random_input(test_packet.data, vif.wr_en, vif.rd_en, vif.clear, vif.RESET);};
				
			endsequence
		end
		vif.reset_FIFO();
		$stop;
	endtask : execute

	function void randomize_control();
		vif.rd_en = $urandom_range(0,99) < 60;
		vif.wr_en = $urandom_range(0,99) < 90;
		vif.clear = $urandom_range(0,99) < 20;
		vif.RESET = $urandom_range(0,99) < 10;
	endfunction : randomize_control
endclass : tester

class checkers;
	virtual rtl_if vif;
	int error=0;
	
	function new(virtual rtl_if top_if);
    		vif = top_if;
  	endfunction : new
	
	task execute();
		logic [DATA_WIDTH-1:0] fifo [$];
		logic [DATA_WIDTH-1:0] predicted_rd_data, clear_data;
		logic predicted_fifo_full, predicted_fifo_empty, predicted_error=0;
		logic readen=0;
		
		fork
			forever begin : negedge_operations
			
			@(negedge vif.CLK);
			if(predicted_rd_data !== vif.rd_data | predicted_fifo_empty !== vif.fifo_empty | predicted_fifo_full !== vif.fifo_full | predicted_error !== vif.error) 
				begin
				error++;
				$display("%t	%t		rst: %b    clr: %b    wr: %b    wr_data: %x    rd: %b",$time/CLOCK_PERIOD,$time,vif.RESET, vif.clear,vif.wr_en,vif.wr_data,vif.rd_en);
				$display("size: %d	readen: %d",fifo.size(),readen);
				$display("Actual: %x	Predicted: %x",vif.rd_data,predicted_rd_data);
				$display("Actual: %b	Predicted: %b",vif.fifo_empty,predicted_fifo_empty);
				$display("Actual: %b	Predicted: %b",vif.fifo_full,predicted_fifo_full);
				$display("Actual: %b	Predicted: %b",vif.error,predicted_error);
				end
				
			//RESET
			if(vif.RESET)
				begin
				//WITHOUT ERROR
				if(!vif.wr_en & !vif.rd_en & !vif.clear)
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			//INITIAL CONDITION
			else if(vif.clear==='x & vif.rd_en==='x & vif.wr_en==='x)
				begin
				predicted_rd_data = 'x;
				predicted_fifo_empty = 'x;
				predicted_fifo_full = 'x;
				predicted_error = 1'b0;
				end
				
			//NO INPUTS
			else if(!vif.RESET & !vif.wr_en & !vif.rd_en & !vif.clear)
				begin
				if(predicted_fifo_full==='x)
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b0;
					end
				else
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				end
				
			//WRITE
			else if(vif.wr_en & !vif.rd_en)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.rd_en & !vif.clear & predicted_fifo_full===1'b0)
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					end
				end
					
			//READ
			else if(vif.rd_en & !vif.wr_en)
				begin
				//WITHOUT ERROR (1st read)
				if(!vif.RESET & !vif.clear & !readen & predicted_fifo_empty===1'b0)
					begin
					//predicted_rd_data = fifo.pop_back();
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = predicted_fifo_full;
					predicted_error = 1'b0;
					end	
				//WITHOUT ERROR (next reads)
				else if(!vif.clear & readen & predicted_fifo_empty===1'b0)
					begin
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = predicted_fifo_full;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			//CLEAR
			else if(vif.clear)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.wr_en & !vif.rd_en & predicted_fifo_empty===1'b0)
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = 1'b0;
					predicted_error = 1'b0;
					end
				//ERROR ASSERTED
				else if(!vif.RESET & !vif.wr_en & !vif.rd_en & predicted_fifo_empty===1'b1)
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = 1'b1;
					predicted_fifo_full = 1'b0;
					predicted_error = 1'b1;
					end
				//WITH ERROR
				else
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			//BYPASS
			else if(vif.rd_en & vif.wr_en)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.clear & predicted_fifo_empty===1'b1)
					begin
					predicted_rd_data = vif.wr_data;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			else
				begin
				predicted_rd_data = 'x;
				predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
				predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
				predicted_error = 1'b0;
				end
			end : negedge_operations
			
			forever begin : posedge_operations
			
			@(posedge vif.CLK);
			if(vif.rd_en & !vif.wr_en & !vif.clear & !readen & !vif.RESET)
				begin
				predicted_rd_data = fifo.pop_back();
				predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
				predicted_fifo_full = predicted_fifo_full;
				predicted_error = 1'b0;
				end
				
			readen = (vif.rd_en & !vif.wr_en & !vif.clear) ? 1'b1 : 1'b0;
			
			//RESET
			if(vif.RESET)
				begin
				//WITHOUT ERROR
				if(!vif.wr_en & !vif.rd_en & !vif.clear)
					begin
					fifo.delete();
					predicted_rd_data = 'x;
					predicted_fifo_empty = 1'b1;
					predicted_fifo_full = 1'b0;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end

			//INITIAL CONDITION
			else if(vif.clear==='x & vif.rd_en==='x & vif.wr_en==='x)
				begin
				predicted_rd_data = 'x;
				predicted_fifo_empty = 'x;
				predicted_fifo_full = 'x;
				predicted_error = 1'b0;
				end
				
			//NO INPUTS
			else if(!vif.RESET & !vif.wr_en & !vif.rd_en & !vif.clear)
				begin
				if(predicted_fifo_full==='x)
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b0;
					end
				else
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				end
			
			//WRITE
			else if(vif.wr_en & !vif.rd_en)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.rd_en& !vif.clear & predicted_fifo_full===1'b0)
					begin
					fifo.push_front(vif.wr_data);
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()>=FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b1;
					end
				end
				
			//READ
			else if(vif.rd_en & !vif.wr_en)
				begin
				//WITHOUT ERROR (1st read)
				if(!vif.RESET & vif.clear & !readen & predicted_fifo_empty===1'b0)
					begin
					//predicted_rd_data = fifo.pop_back();
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//WITHOUT ERROR (next reads)
				else if(!vif.RESET & !vif.clear & readen & predicted_fifo_empty===1'b0)
					begin
					predicted_rd_data = fifo.pop_back();
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end	
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			//CLEAR
			else if(vif.clear)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.wr_en & !vif.rd_en & predicted_fifo_empty===1'b0)
					begin
					clear_data = fifo.pop_front();
					predicted_rd_data = 'x;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//ERROR ASSERTED
				else if(!vif.RESET & !vif.wr_en & !vif.rd_en & predicted_fifo_empty===1'b1)
					begin
					predicted_rd_data = 'x;
					predicted_fifo_empty = 1'b1;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b1;
					end
				//WITH ERROR
				else
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
			
			//BYPASS
			else if(vif.rd_en & vif.wr_en)
				begin
				//WITHOUT ERROR
				if(!vif.RESET & !vif.clear & predicted_fifo_empty===1'b1)
					begin
					predicted_rd_data = vif.wr_data;
					predicted_fifo_empty = fifo.size()==0 ? 1'b1 : 1'b0;
					predicted_fifo_full = fifo.size()==FIFO_SIZE ? 1'b1 : 1'b0;
					predicted_error = 1'b0;
					end
				//WITH ERROR
				else 
					begin
					predicted_rd_data = 'x;
					predicted_error = 1'b1;
					end
				end
				
			else
				begin
				predicted_error = 1'b0;
				end
			end : posedge_operations
		join
	endtask : execute
endclass : checkers

class testbench;
  tester tester_h;
  checkers checker_h;

  function new(virtual rtl_if top_if);
    tester_h = new(top_if);
    checker_h = new(top_if);
  endfunction : new

  task run();
    fork
      tester_h.execute();
      checker_h.execute();
    join_none
  endtask : run

endclass : testbench

// top_tb.svh
// Top-level testbench

module top_tb
  import dataTypes::*;
  ();

  rtl_if top_if();

  coverage cov(top_if.cov);                           //coverage instantiation

  top_rtl #(.SIZE(FIFO_SIZE)) top_dut(top_if.dut);

  testbench testbench_h;

  initial begin
  $dumpfile("dump.vcd");
  $dumpvars;
	testbench_h = new(top_if);
	testbench_h.run();
	
	if(testbench_h.checker_h.error==0) 
		begin
		$display("\n");
		$display("****************************   Congrats!! No errors found   ****************************");
		$display("\n");
		end
  end

  final begin
    $display("\n\t Test End\n");
  end 

endmodule : top_tb