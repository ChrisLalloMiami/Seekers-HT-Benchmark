/** @module : dual_port_BRAM_memory_subsystem
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

 *  Copyright (c) 2021 STAM Center (ASCS Lab/CAES Lab/STAM Center/ASU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

module dual_port_BRAM_memory_subsystem #(
  parameter DATA_WIDTH       = 32,
  parameter ADDRESS_BITS     = 32,
  parameter MEM_ADDRESS_BITS = 12,
  parameter SCAN_CYCLES_MIN  = 0,
  parameter SCAN_CYCLES_MAX  = 1000
) (
  input      clock,
  input      reset,
  //instruction memory
  input      i_mem_read,
  input      [ADDRESS_BITS-1:0] i_mem_address_in,
  output     [DATA_WIDTH-1  :0] i_mem_data_out,
  output reg [ADDRESS_BITS-1:0] i_mem_address_out,
  output reg i_mem_valid,
  output     i_mem_ready,
  //data memory
  input      d_mem_read,
  input      d_mem_write,
  input      [DATA_WIDTH/8-1:0] d_mem_byte_en,
  input      [ADDRESS_BITS-1:0] d_mem_address_in,
  input      [DATA_WIDTH-1  :0] d_mem_data_in,
  output     [DATA_WIDTH-1  :0] d_mem_data_out,
  output reg [ADDRESS_BITS-1:0] d_mem_address_out,
  output reg d_mem_valid,
  output     d_mem_ready,
  //scan signal
  input      scan
);

//define the log2 function
function integer log2;
input integer value;
begin
  value = value-1;
  for (log2=0; value>0; log2=log2+1)
    value = value >> 1;
end
endfunction


localparam NUM_BYTES = DATA_WIDTH/8;

dual_port_BRAM_byte_en #(
  .CORE(0),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(MEM_ADDRESS_BITS-log2(NUM_BYTES)),
  .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
  .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
) memory (
  .clock(clock),
  .reset(reset),
  // Port // instruction fetch
  .readEnable_1(i_mem_read),
  .writeEnable_1(1'b0),
  .writeByteEnable_1({NUM_BYTES{1'b0}}),
  .address_1(i_mem_address_in[MEM_ADDRESS_BITS-1:log2(NUM_BYTES)]),
  .writeData_1({DATA_WIDTH{1'b0}}),
  .readData_1(i_mem_data_out),
  // Port 2 // data memory operations
  .readEnable_2(d_mem_read),
  .writeEnable_2(d_mem_write),
  .writeByteEnable_2(d_mem_byte_en),
  .address_2(d_mem_address_in[MEM_ADDRESS_BITS-1:log2(NUM_BYTES)]),
  .writeData_2(d_mem_data_in),
  .readData_2(d_mem_data_out),
  // scan signal
  .scan(scan)
);

//assign outputs
always @(posedge clock)begin
  i_mem_valid       <= i_mem_read;
  i_mem_address_out <= i_mem_address_in;
  d_mem_valid       <= d_mem_read;
  d_mem_address_out <= d_mem_address_in;
end

assign i_mem_ready = 1'b1;
assign d_mem_ready = 1'b1;

endmodule

module dual_port_BRAM_byte_en #(
  parameter CORE = 0,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter INIT_FILE_BASE = "",
  parameter SCAN_CYCLES_MIN = 0,
  parameter SCAN_CYCLES_MAX = 1000
) (
  input  clock,
  input  reset,

  // Port 1
  input  readEnable_1,
  input  writeEnable_1,
  input  [DATA_WIDTH/8-1:0] writeByteEnable_1,
  input  [ADDR_WIDTH-1:0] address_1,
  input  [DATA_WIDTH-1:0] writeData_1,
  output [DATA_WIDTH-1:0] readData_1,

  // Port 2
  input  readEnable_2,
  input  writeEnable_2,
  input  [DATA_WIDTH/8-1:0] writeByteEnable_2,
  input  [ADDR_WIDTH-1:0] address_2,
  input  [DATA_WIDTH-1:0] writeData_2,
  output [DATA_WIDTH-1:0] readData_2,

  input  scan
);

localparam MEM_DEPTH = 1 << ADDR_WIDTH;
localparam NUM_BYTES = DATA_WIDTH/8;


genvar i;
generate
for(i=0; i<NUM_BYTES; i=i+1) begin : BYTE_LOOP

  if(INIT_FILE_BASE != "") begin : IF_INIT
    // Override the init file parameter by prepending the byte number to the
    // base file name
    dual_port_BRAM #(
      .CORE(CORE),
      .DATA_WIDTH(8),
      .ADDR_WIDTH(ADDR_WIDTH),
      .INIT_FILE({"0"+i,INIT_FILE_BASE}),
      .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
      .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
    ) BRAM_byte (
      .clock(clock),
      .reset(reset),

      // Port
      .readEnable_1(readEnable_1),
      .writeEnable_1(writeEnable_1 & writeByteEnable_1[i]),
      .address_1(address_1),
      .writeData_1(writeData_1[(8*i)+7:8*i]),
      .readData_1(readData_1[(8*i)+7:8*i]),

      // Port 2
      .readEnable_2(readEnable_2),
      .writeEnable_2(writeEnable_2 & writeByteEnable_2[i]),
      .address_2(address_2),
      .writeData_2(writeData_2[(8*i)+7:8*i]),
      .readData_2(readData_2[(8*i)+7:8*i]),

      .scan(scan)
    );
  end
  else begin : ELSE_INIT
    // Do not override the INIT_FILE parameter
    dual_port_BRAM #(
      .CORE(CORE),
      .DATA_WIDTH(8),
      .ADDR_WIDTH(ADDR_WIDTH),
      .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
      .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
    ) BRAM_byte (
      .clock(clock),
      .reset(reset),

      // Port
      .readEnable_1(readEnable_1),
      .writeEnable_1(writeEnable_1 & writeByteEnable_1[i]),
      .address_1(address_1),
      .writeData_1(writeData_1[(8*i)+7:8*i]),
      .readData_1(readData_1[(8*i)+7:8*i]),

      // Port 2
      .readEnable_2(readEnable_2),
      .writeEnable_2(writeEnable_2 & writeByteEnable_2[i]),
      .address_2(address_2),
      .writeData_2(writeData_2[(8*i)+7:8*i]),
      .readData_2(readData_2[(8*i)+7:8*i]),

      .scan(scan)
    );
  end
end


endgenerate

// reg [31: 0] cycles;
// always @ (negedge clock) begin
//   cycles <= reset? 0 : cycles + 1;
//   if (scan & ((cycles >=  SCAN_CYCLES_MIN) & (cycles <= SCAN_CYCLES_MAX)))begin
//     $display ("------ Core %d Dual Port BRAM Byte En Unit - Current Cycle %d --------", CORE, cycles);
//     $display ("| Read 1       [%b]", readEnable_1);
//     $display ("| Write 1      [%b]", writeEnable_1);
//     $display ("| Write Byte 1 [%b]", writeByteEnable_1);
//     $display ("| Address 1    [%h]", address_1);
//     $display ("| Read Data 1  [%h]", readData_1);
//     $display ("| Write Data 1 [%h]", writeData_1);
//     $display ("| Read 2       [%b]", readEnable_2);
//     $display ("| Write 2      [%b]", writeEnable_2);
//     $display ("| Write Byte 2 [%b]", writeByteEnable_2);
//     $display ("| Address 2    [%h]", address_2);
//     $display ("| Read Data 2  [%h]", readData_2);
//     $display ("| Write Data 2 [%h]", writeData_2);
//     $display ("----------------------------------------------------------------------");
//   end
// end

endmodule

module dual_port_BRAM #(
  parameter CORE = 0,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 8,
  parameter INIT_FILE  = "",
  parameter SCAN_CYCLES_MIN = 0,
  parameter SCAN_CYCLES_MAX = 1000
) (
  input  clock,
  input  reset,

  // Port 1
  input  readEnable_1,
  input  writeEnable_1,
  input  [ADDR_WIDTH-1:0] address_1,
  input  [DATA_WIDTH-1:0] writeData_1,
  output reg [DATA_WIDTH-1:0] readData_1,

  // Port 2
  input  readEnable_2,
  input  writeEnable_2,
  input  [ADDR_WIDTH-1:0] address_2,
  input  [DATA_WIDTH-1:0] writeData_2,
  output reg [DATA_WIDTH-1:0] readData_2,

  input  scan

);

localparam RAM_DEPTH = 1 << ADDR_WIDTH;

reg [DATA_WIDTH-1:0] readData_r_1;
reg [DATA_WIDTH-1:0] readData_r_2;
reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

wire valid_writeEnable_2;

assign valid_writeEnable_2 =  writeEnable_2 & ~(writeEnable_1 & (address_1 == address_2));

initial begin
  if(INIT_FILE != "")
    $readmemh(INIT_FILE, ram);
end

// Port 1
always@(posedge clock) begin
  if(writeEnable_1)
    // Blocking Write to read new data on read during write
    ram[address_1] = writeData_1;
  if(readEnable_1)
    readData_1 <= ram[address_1];

end

// Port 2
always@(posedge clock)begin
  if(valid_writeEnable_2)
    // Blocking Write to read new data on read during write
    ram[address_2] = writeData_2;
  if(readEnable_2)
    readData_2 <= ram[address_2];
end

// reg [31: 0] cycles;
// always @ (negedge clock) begin
//   cycles <= reset? 0 : cycles + 1;
//   if (scan & ((cycles >=  SCAN_CYCLES_MIN) & (cycles <= SCAN_CYCLES_MAX)))begin
//     $display ("------ Core %d BRAM Unit - Current Cycle %d --------", CORE, cycles);
//     $display ("| Read 1       [%b]", readEnable_1);
//     $display ("| Write 1      [%b]", writeEnable_1);
//     $display ("| Address 1    [%h]", address_1);
//     $display ("| Read Data 1  [%h]", readData_1);
//     $display ("| Write Data 1 [%h]", writeData_1);
//     $display ("| Read 2       [%b]", readEnable_2);
//     $display ("| Write 2      [%b]", writeEnable_2);
//     $display ("| Valid Write 2[%b]", valid_writeEnable_2);
//     $display ("| Address 2    [%h]", address_2);
//     $display ("| Read Data 2  [%h]", readData_2);
//     $display ("| Write Data 2 [%h]", writeData_2);
//     $display ("----------------------------------------------------------------------");
//   end
// end

endmodule
