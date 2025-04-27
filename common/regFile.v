module regFile #(
  parameter REG_DATA_WIDTH = 32,
  parameter REG_SEL_BITS = 5
) (
  input clock,
  input reset,
  input wEn,
  input [REG_DATA_WIDTH-1:0] write_data,
  input [REG_SEL_BITS-1:0] read_sel1,
  input [REG_SEL_BITS-1:0] read_sel2,
  input [REG_SEL_BITS-1:0] write_sel,
  output[REG_DATA_WIDTH-1:0] read_data1,
  output[REG_DATA_WIDTH-1:0] read_data2
);

(* ram_style = "distributed" *)
reg [REG_DATA_WIDTH-1:0] register_file[0:(1<<REG_SEL_BITS)-1];


always @(posedge clock)
  if(reset==1)
    register_file[0] <= 0;
  else
    if (wEn & write_sel != 0) register_file[write_sel] <= write_data;

//----------------------------------------------------
// Drive the outputs
//----------------------------------------------------

assign  read_data1 = register_file[read_sel1];
assign  read_data2 = register_file[read_sel2];

endmodule
