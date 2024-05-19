module coverage(rtl_if.cov top_if);
  import dataTypes::*;

  logic [DATA_WIDTH-1:0] MAX_DATA = 2**DATA_WIDTH - 1;
  
  covergroup test_cov @(posedge top_if.CLK);
    Reset:      coverpoint top_if.RESET                          {bins ResetEnabled = {1}; bins ResetDisabled = {0}; }
    Write:      coverpoint top_if.wr_en iff(!top_if.RESET)       {bins WriteEnabled = {1}; bins WriteDisabled = {0}; }
    Read:       coverpoint top_if.rd_en iff(!top_if.RESET)       {bins ReadEnabled = {1}; bins ReadDisabled = {0}; }
    Clear:      coverpoint top_if.clear iff(!top_if.RESET)       {bins ClearEnabled = {1}; bins ClearDisabled = {0}; }
    FullFIFO:   coverpoint top_if.fifo_full iff(!top_if.RESET)   {bins FullFIFOEnabled = {1}; bins FullFIFODisabled = {0}; }
    EmptyFIFO:  coverpoint top_if.fifo_empty iff(!top_if.RESET)  {bins EmptyFIFOEnabled = {1}; bins EmptyFIFODisabled = {0}; }
    ReadData:   coverpoint top_if.rd_data iff(!top_if.RESET)     {bins ReadDataMin = {0}; bins ReadDataMax = {MAX_DATA}; bins ReadDataMid = default; }
    WriteData:  coverpoint top_if.wr_data iff(!top_if.RESET)     {bins WriteDataMin = {0}; bins WriteDataMax = {MAX_DATA}; bins WriteDataMid = default; }
	Error:		coverpoint top_if.error							{bins ErrorEnabled = {1}; bins ErrorDisabled = {0}; }

    cross_evrything: cross Reset, Write, Read, Clear, FullFIFO, EmptyFIFO, ReadData, WriteData, Error;
    cross_writexread: cross Write, Read;
	cross_writexwritedata: cross Write, WriteData;
	cross_writexrddata: cross Write, ReadData;
    cross_writexclear: cross Write, Clear;
    cross_readxreset: cross Read, Reset;
	cross_readxrddata: cross Read, ReadData;
	cross_readxwritedata: cross Read, WriteData;
    cross_readxclear:  cross Read, Clear;
    cross_clearxreset: cross Clear, Reset;
	cross_clearxwritedata: cross Clear, WriteData;
	cross_clearxrddata: cross Clear, ReadData;
    cross_resetxwrite: cross Reset, Write;
	cross_readxempty: cross Read, EmptyFIFO;
	cross_writexempty: cross Write, EmptyFIFO;
	cross_clearxempty: cross Clear, EmptyFIFO;
	cross_readxfull: cross Read, FullFIFO;
	cross_writexfull: cross Write, FullFIFO;
	cross_clearxfull: cross Clear, FullFIFO;
	cross_errorxreset: cross Error, Reset;
	cross_errorxwrite: cross Error, Write;
	cross_errorxread: cross Error, Read;
	cross_errorxclear: cross Error, Clear;
	cross_errorxfull: cross Error, FullFIFO;
	cross_errorxempty: cross Error, EmptyFIFO;
	cross_errorxwrdata: cross Error, WriteData;
	cross_errorxrddata: cross Error, ReadData;
	
  endgroup

  test_cov cvg;

  initial begin
    cvg = new();
  end

endmodule : coverage
