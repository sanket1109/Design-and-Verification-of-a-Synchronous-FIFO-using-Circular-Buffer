// types.sv

package dataTypes;

  parameter FIFO_SIZE = 8;
  parameter DATA_WIDTH = 8;
  parameter RESET_CYCLES = 5;
  parameter CLOCK_PERIOD = 1000;
  parameter MAX_DATA = 2**DATA_WIDTH - 1;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
  } data_packet_sp;

endpackage : dataTypes
