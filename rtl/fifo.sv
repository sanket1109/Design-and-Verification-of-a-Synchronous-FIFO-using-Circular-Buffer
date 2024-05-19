//////////////////////////////////////////////////////
//AUTHORS:
//Sanket Patil: sanket2@pdx.edu
//Balaji Rao Vavintaparthi: balaji2@pdx.edu
//////////////////////////////////////////////////////

// fifo.sv

module fifo
  import dataTypes::*;
#(
  parameter SIZE = 16
)(
  rtl_if rif
);
  localparam PTR_WIDTH = $clog2(SIZE);
  logic [PTR_WIDTH-1:0] rd_pointer = '0;   //write pointer
  logic [PTR_WIDTH-1:0] wr_pointer = '0;   //read pointer
  logic [DATA_WIDTH-1:0] FIFO [SIZE-1:0];  //FIFO
  logic wren_next, clear_next, rden_next; 

  logic [PTR_WIDTH-1:0] rdptr = '0;
  logic empty_fifo;

always_ff@(posedge rif.CLK)
	begin
	//RESET condition
	if(rif.RESET & !rif.clear & !rif.wr_en & !rif.rd_en)
		begin
		FIFO <= '{default:'x};     //fill the FIFO with x when reset
		empty_fifo <= 1'b1;        //FIFO should be empty
		rif.fifo_full <= 1'b0;     //FIFO shouldn't be full
		wr_pointer <= 0;           //set the write pointer to zero when reset
		clear_next <= 0;
		wren_next <= 0;
		end

	//CLEAR when FIFO is not EMPTY
	else if(rif.clear & !rif.fifo_empty & !rif.wr_en & !rif.rd_en & !rif.RESET)
		begin
		rif.fifo_full <= 1'b0;                                             //FIFO can't be full when clear signal is asserted
		wr_pointer <= wr_pointer == 0 ? SIZE - 1 : wr_pointer - 1'b1;      //decrement the write pointer
		if(wr_pointer == 0)  empty_fifo <= rd_pointer == (SIZE - 1) ? 1'b1 : 1'b0;
		else                 empty_fifo <= wr_pointer - 1'b1 == rd_pointer ? 1'b1 : 1'b0;
		clear_next <= 0;
		wren_next <= 0;
		end

	//CLEAR when FIFO is EMPTY
	else if(rif.clear & rif.fifo_empty & !rif.wr_en & !rif.rd_en & !rif.RESET)
		begin
		clear_next <= rif.clear;
		rif.fifo_full <= 1'b0;
		empty_fifo <= 1'b1;
		wren_next <= 0;
		end

	//WRITE when FIFO is not FULL
	else if(rif.wr_en & !rif.rd_en & !rif.clear & !rif.fifo_full & !rif.RESET)
		begin
		empty_fifo <= 1'b0;                                                //FIFO can't be empty when write signal is asserted
		FIFO[wr_pointer] <= rif.wr_data;                                   //write the data to FIFO
		wr_pointer <= wr_pointer == SIZE-1 ? 0 : wr_pointer + 1'b1;        //increment the write pointer
		if(wr_pointer == SIZE-1)   rif.fifo_full <= rd_pointer == 0 ? 1'b1 : 1'b0;
		else                       rif.fifo_full <= wr_pointer + 1'b1 == rd_pointer ? 1'b1 : 1'b0;
		clear_next <= 0;
		wren_next <= 0;
		end

	//WRITE when FIFO is FULL
	else if(rif.wr_en & !rif.rd_en & !rif.clear & rif.fifo_full & !rif.RESET)
		begin
		rif.fifo_full <= 1'b1;             //FIFO will be full
		wren_next <= rif.wr_en;
		clear_next <= 0;
		end

	//READ when FIFO is not EMPTY
	else if(rif.rd_en & !rif.wr_en & !rif.clear & !rif.fifo_empty & !rif.RESET)
		begin
		rif.fifo_full <= 1'b0;             //FIFO can't be full when read signal is asserted
		if(rd_pointer == SIZE-1)   empty_fifo <= wr_pointer == 0 ? 1'b1 : 1'b0;
		else                       empty_fifo <= rd_pointer + 1'b1 == wr_pointer ? 1'b1 : 1'b0;
		clear_next <= 0;
		wren_next <= 0;
		rden_next <= 1;
		end

	//READ when FIFO is EMPTY
	else if(rif.rd_en & !rif.wr_en & !rif.clear & rif.fifo_empty & !rif.RESET)  
		begin
		empty_fifo <= 1'b1;                //FIFO will be empty 
		rif.fifo_full <= 1'b0;
		clear_next <= 0;
		wren_next <= 0;
		rden_next <= 1;
		end
		
	//BYPASS
	else if(rif.fifo_empty & rif.rd_en & rif.wr_en & !rif.clear & !rif.RESET)
		begin
		rif.fifo_full <= 1'b0;
		clear_next <= 0;
		wren_next <= 0;
		end

	else 
		begin
		FIFO <= FIFO;
		clear_next <= 0;
		wren_next <= 0;
		end

	rdptr <= rd_pointer;
	end

always_comb
	begin
	
	if(rif.fifo_empty & rif.rd_en & rif.wr_en & !rif.clear & !rif.RESET)         rif.rd_data = rif.wr_data;      //bypass logic
	else if(rif.rd_en & !rif.wr_en & !rif.fifo_empty & !rif.clear & !rif.RESET)      		rif.rd_data = FIFO[rdptr];      //read the data from FIFO
	else                                                   		rif.rd_data = 'x;               //read x if read not asserted

	if(rif.RESET & rif.fifo_empty & !rif.wr_en & !rif.rd_en & !rif.clear) 	rif.error = 1'b0;
	else if(!rif.RESET & !rif.wr_en & !rif.rd_en & !rif.clear) 		rif.error = 1'b0;
	else if(rif.RESET & (rif.wr_en | rif.rd_en | rif.clear)) 		rif.error = 1'b1;		//Any command to read, write or clear when Reset is asserted.
	else if(rif.fifo_empty & rif.clear & !rif.rd_en & !rif.wr_en)		rif.error = 1'b1;		//when fifo is empty and we try to clear
	else if(rif.fifo_empty & clear_next & !rif.rd_en & !rif.wr_en)		rif.error = 1'b1;
	else if(rif.fifo_empty & rif.rd_en & rif.wr_en & !rif.clear)		rif.error = 1'b0;
	else if(rif.fifo_empty & rif.rd_en & rif.clear)				rif.error = 1'b1;		//when fifo is empty and we try to read and clear
	else if(!rif.fifo_empty & rif.rd_en & rif.wr_en & !rif.clear)				rif.error = 1'b1;
	else if(rif.fifo_empty & rif.rd_en & !rif.wr_en & !rif.clear)		rif.error = 1'b1;		//when fifo is empty and we try to read
	else if(rif.fifo_full & wren_next)					rif.error = 1'b1;		//when fifo is full and we try to write
	else if(rif.wr_en & rif.clear)						rif.error = 1'b1;		//when write and clear signal is asserted
	else 									rif.error = 1'b0;

	if(rif.RESET & !rif.wr_en & !rif.rd_en & !rif.clear)                                      rd_pointer = 0;                                             //set the read pointer to zero if reset
	else if(rif.rd_en & !rif.wr_en & !rif.fifo_empty & !rif.RESET)  rd_pointer = rd_pointer == SIZE-1 ? 0 : rd_pointer + 1'b1;  //increment the read pointer if read asserted
	else                                               rd_pointer = rd_pointer;

	if((rd_pointer == wr_pointer) & rif.rd_en & !rif.clear & !rif.wr_en & !rif.RESET & rif.fifo_full!=='x) 	rif.fifo_empty = 1'b1;
	else													rif.fifo_empty = empty_fifo;

	end
	

	//**********************************ASSERTIONS*******************************************	
	//-----------------------------------RESET-----------------------------------------------
	//Reset without error
	property p_reset;
    		@(posedge rif.CLK)
    		rif.RESET & !rif.wr_en & !rif.rd_en & !rif.clear |-> ##1  ((rd_pointer == '0) & (wr_pointer == '0) & (rif.fifo_empty) & (!rif.fifo_full));
	endproperty: p_reset
	a_reset: assert property(p_reset)	else $error("Reset failed"); 
	
	//Reset with error
	property p_reset_error;
   		@(posedge rif.CLK)
    		rif.RESET & (rif.wr_en | rif.rd_en | rif.clear) |-> rif.error;
	endproperty: p_reset_error
	a_reset_error: assert property(p_reset_error)	else $error("Reset error failed"); 
	
	//-----------------------------------WRITE---------------------------------------------
	//Write pointer should not chnage when FIFO is full and write is asserted
	property p_write_fifofull;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en & !rif.clear & rif.wr_en & rif.fifo_full) |=>  (wr_pointer == $past(wr_pointer));
    	endproperty: p_write_fifofull
    	a_write_fifofull: assert property(p_write_fifofull)	else $error("Write pointer changed when FIFO was full and write was asserted");
	
	//Write pointer should increment when FIFO is not full and write is asserted
	property p_write_not_fifofull;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en & !rif.clear & rif.wr_en & !rif.fifo_full) |=>  (wr_pointer == $past(wr_pointer)+1'b1);
    	endproperty: p_write_not_fifofull
    	a_write_not_fifofull: assert property(p_write_not_fifofull)	else $error("Write pointer did not increment by 1 when FIFO was not full and write was asserted");
	
	//Error signal should be asserted when fifo is full and write is asserted
	property p_write_fifofull_error;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en && !rif.clear && rif.wr_en && rif.fifo_full) |=> (rif.error == 1);
	endproperty: p_write_fifofull_error
	a_write_fifofull_error: assert property(p_write_fifofull_error)	else $error("Error signal did not get asserted when FIFO is full is full and write is asserted");

	//FIFO should not be empty when write is asserted
	property p_write_fifoempty_low;
   		@(negedge rif.CLK) disable iff(rif.RESET) 
    		(!rif.rd_en & rif.wr_en & !rif.clear) |-> (!rif.fifo_empty);
  	endproperty: p_write_fifoempty_low
  	a_write_fifoempty_low: assert property(p_write_fifoempty_low)	else $error("Fifo empty signal did not get low when write signal gets high");

	//FIFO should be full when pointers are same and write is asserted
	property p_write_pointer_full;
    		@(posedge rif.CLK) disable iff(rif.RESET)
     		((wr_pointer+1'b1 == rd_pointer) & !rif.rd_en & !rif.clear & rif.wr_en) |=>  (rif.fifo_full);
  	endproperty: p_write_pointer_full
  	a_write_pointer_full: assert property(p_write_pointer_full)	else $error("Fifo full signal did not get asserted when pointers are equal and write is asserted");
	
	//------------------------------------READ--------------------------------------------
	//Read pointer should not change when FIFO is empty and read is asserted
	property p_read_fifoempty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(rif.rd_en & !rif.clear & !rif.wr_en & rif.fifo_empty) |=>  (rd_pointer == $past(rd_pointer));
    	endproperty: p_read_fifoempty
   	a_read_fifoempty: assert property(p_read_fifoempty)	else $error("Read pointer changed when FIFO was empty and read was asserted");
	
	//Read pointer should increment when FIFO is not empty and read is asserted
	property p_read_not_fifoempty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(rif.rd_en & !rif.clear & !rif.wr_en & !rif.fifo_empty) |=>  (rd_pointer == $past(rd_pointer)+1'b1);
    	endproperty: p_read_not_fifoempty
    	a_read_not_fifoempty: assert property(p_read_not_fifoempty)	else $error("Read pointer did not increment by 1 when FIFO was not empty and read was asserted");

	//FIFO should not be full when read is asserted
	property p_read_fifofull_low;
   		@(posedge rif.CLK) disable iff(rif.RESET) 
    		(rif.rd_en & !rif.wr_en & !rif.clear & rif.fifo_full) |=> (!rif.fifo_full);
  	endproperty: p_read_fifofull_low
  	a_read_fifofull_low: assert property(p_read_fifofull_low)	else $error("Fifo full signal did not get low when read signal gets high");

	//Read data should be known when FIFO is not empty and read is asserted
	property p_read_rddata;
   		@(posedge rif.CLK) disable iff(rif.RESET)
      		(!rif.wr_en & rif.rd_en & !rif.fifo_empty & !rif.clear) |-> !$isunknown(rif.rd_data);
 	endproperty: p_read_rddata
  	a_read_rddata: assert property(p_read_rddata)	else $error("Read data should be known when read is asserted and FIFO is not empty");

	//FIFO should be empty when pointers are same and read is asserted
	property p_read_pointer_empty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
     		((wr_pointer == rd_pointer) & rif.rd_en & !rif.clear & !rif.wr_en) |->  (rif.fifo_empty);
  	endproperty: p_read_pointer_empty
  	a_read_pointer_empty: assert property(p_read_pointer_empty)	else $error("Fifo empty signal did not get asserted when pointers are equal and read is asserted"); 
	
	//----------------------------------CLEAR------------------------------------------------
	//Write pointer should not change when FIFO is empty and clear is asserted
	property p_clear_fifoempty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en & rif.clear & !rif.wr_en & rif.fifo_empty) |=>  (wr_pointer == $past(wr_pointer));
    	endproperty: p_clear_fifoempty
    	a_clear_fifoempty: assert property(p_clear_fifoempty)	else $error("Write pointer changed when FIFO was empty and clear was asserted");
	
	//Write pointer should increment when FIFO is not full and write is asserted
	property p_clear_not_fifoempty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en & rif.clear & !rif.wr_en & !rif.fifo_empty) |=>  (wr_pointer == $past(wr_pointer)-1'b1);
    	endproperty: p_clear_not_fifoempty
    	a_clear_not_fifoempty: assert property(p_clear_not_fifoempty)	else $error("Write pointer did not decrement by 1 when FIFO was not empty and clear was asserted");
	
	//Error signal should be asserted when fifo is empty and clear is asserted
	property p_clear_fifoempty_error;
    		@(posedge rif.CLK) disable iff(rif.RESET)
    		(!rif.rd_en & clear_next & !rif.wr_en & rif.fifo_empty) |-> rif.error;
	endproperty: p_clear_fifoempty_error
	a_clear_fifoempty_error: assert property(p_clear_fifoempty_error)	else $error("Error signal did not get asserted when FIFO is empty and clear is asserted");

	//FIFO should not be full when clear is asserted
	property p_clear_fifofull_low;
   		@(posedge rif.CLK) disable iff(rif.RESET) 
    		(!rif.rd_en & !rif.wr_en & rif.clear & rif.fifo_full) |=> (!rif.fifo_full);
  	endproperty: p_clear_fifofull_low
  	a_clear_fifofull_low: assert property(p_clear_fifofull_low)	else $error("Fifo full signal did not get low when clear signal gets high");

	//FIFO should be empty when pointers are same and read is asserted
	property p_clear_pointer_empty;
    		@(posedge rif.CLK) disable iff(rif.RESET)
     		((wr_pointer-1'b1 == rd_pointer) & !rif.rd_en & rif.clear & !rif.wr_en) |=>  (rif.fifo_empty);
  	endproperty: p_clear_pointer_empty
  	a_clear_pointer_empty: assert property(p_clear_pointer_empty)	else $error("Fifo empty signal did not get asserted when pointers are equal and clear is asserted"); 

	//----------------------------------BYPASS----------------------------------------------------
	//Read data should be equal to write data
	property p_bypass;
   		@(posedge rif.CLK) disable iff(rif.RESET)
      		(rif.wr_en & rif.rd_en & rif.fifo_empty & !rif.clear) |-> (rif.rd_data == rif.wr_data);
 	endproperty: p_bypass
  	a_bypass: assert property(p_bypass)	else $error("Read data and Write data is not same during bypass condition");

	//Pointers do not change 
	property p_bypass_pointer;
   		@(negedge rif.CLK) disable iff(rif.RESET)
      		(rif.wr_en & rif.rd_en & rif.fifo_empty & !rif.clear) |-> (($past(rd_pointer)==rd_pointer) & ($past(wr_pointer)==wr_pointer));
 	endproperty: p_bypass_pointer
  	a_bypass_pointer: assert property(p_bypass_pointer)	else $error("Pointers did not remain same during bypass condition");

endmodule : fifo
