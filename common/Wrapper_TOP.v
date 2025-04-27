module Wrapper_TOP #(
  parameter CORE              = 0, 
  parameter DATA_WIDTH        = 32,
  parameter ADDRESS_BITS      = 32,
  parameter MEM_ADDRESS_BITS  = 14,
  parameter SCAN_CYCLES_MIN   = 0,
  parameter SCAN_CYCLES_MAX   = 1000
) (
  input clock,
  input reset,

  input start,
  input [ADDRESS_BITS-1:0] program_address,

  output [ADDRESS_BITS-1:0] PC,

  input scan
);

// PC from cut out linked to  big boy

wire [ADDRESS_BITS-1:0] PC_OUT_FROM_cut_out;
assign PC = PC_OUT_FROM_cut_out;


// outputs from BRAM memory linked as wires to cut out

wire [DATA_WIDTH-1  :0] i_mem_data_out;
wire [ADDRESS_BITS-1:0] i_mem_address_out;
wire i_mem_valid;
wire i_mem_ready;
wire [DATA_WIDTH-1  :0] d_mem_data_out;
wire [ADDRESS_BITS-1:0] d_mem_address_out;
wire d_mem_valid;
wire d_mem_ready;


// outputs from cut out linked as wires to memory BRAM

wire i_mem_read;
wire [ADDRESS_BITS-1:0] i_mem_address_in;
wire d_mem_read;
wire d_mem_write;
wire [DATA_WIDTH/8-1:0] d_mem_byte_en;
wire [ADDRESS_BITS-1:0] d_mem_address_in;
wire [DATA_WIDTH-1  :0] d_mem_data_in;

// IO to/from regFile
wire [31:0]reg_file_write_data;
wire [4:0]reg_file_read_sel1;
wire [4:0]reg_file_read_sel2;
wire [4:0]reg_file_write_sel;

wire [31:0]reg_file_read_data1;
wire [31:0]reg_file_read_data2;

wire reg_file_write_enable;

single_cycle_BRAM_top my_top (
  clock,
  reset,
  start,

  program_address,
  PC_OUT_FROM_cut_out,
  scan,
  i_mem_data_out,
  

  i_mem_address_out,
  i_mem_valid,
  i_mem_ready,

  d_mem_data_out,
  d_mem_address_out,
  d_mem_valid,
  d_mem_ready,

  

  i_mem_read,
  i_mem_address_in,

  d_mem_read,
  d_mem_write,
  d_mem_byte_en,
  d_mem_address_in,
  d_mem_data_in,

  reg_file_write_data,
  reg_file_read_sel1,
  reg_file_read_sel2,
  reg_file_write_sel,
  reg_file_write_enable,
  reg_file_read_data1,
  reg_file_read_data2
);


dual_port_BRAM_memory_subsystem #(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDRESS_BITS(ADDRESS_BITS),
  .MEM_ADDRESS_BITS(MEM_ADDRESS_BITS),
  .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
  .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
) memory (
  .clock(clock),
  .reset(reset),
  //instruction memory
  .i_mem_read(i_mem_read),
  .i_mem_address_in(i_mem_address_in),
  .i_mem_data_out(i_mem_data_out),
  .i_mem_address_out(i_mem_address_out),
  .i_mem_valid(i_mem_valid),
  .i_mem_ready(i_mem_ready),
  //data memory
  .d_mem_read(d_mem_read),
  .d_mem_write(d_mem_write),
  .d_mem_byte_en(d_mem_byte_en),
  .d_mem_address_in(d_mem_address_in),
  .d_mem_data_in(d_mem_data_in),
  .d_mem_data_out(d_mem_data_out),
  .d_mem_address_out(d_mem_address_out),
  .d_mem_valid(d_mem_valid),
  .d_mem_ready(d_mem_ready),

  .scan(scan)
);

regFile #(
  .REG_DATA_WIDTH(32),
  .REG_SEL_BITS(5)
) registers (
  .clock(clock),
  .reset(reset),
  .read_sel1(reg_file_read_sel1),
  .read_sel2(reg_file_read_sel2),
  .wEn(reg_file_write_enable),
  .write_sel(reg_file_write_sel),
  .write_data(reg_file_write_data),
  .read_data1(reg_file_read_data1),
  .read_data2(reg_file_read_data2)
);

endmodule


