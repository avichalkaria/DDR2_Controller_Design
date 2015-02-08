//Kathan P. Shah
//fifo_kp

module FIFO (clk, reset, data_in, put, get, data_out, empty_bar, full_bar, fillcount);

parameter DEPTH = 64; 
parameter DEPTH_LOG2 = 6;
parameter WIDTH = 8;

input [WIDTH-1:0] data_in;
input put, get;
input reset, clk;

output [WIDTH-1:0] data_out;
output empty_bar, full_bar;
output [DEPTH_LOG2:0] fillcount; //if it is full,we need onemore bit
wire [WIDTH-1:0] data_out;
wire empty_bar, full_bar;

reg [DEPTH_LOG2:0] fillcount; //if it is full,we need onemore bit
reg [DEPTH_LOG2-1:0] wr_ptr, rd_ptr;
reg [WIDTH-1:0] mem [DEPTH-1:0];
reg [WIDTH-1:0] data_out_temp;

always @(posedge clk) 
  begin
    if(reset)
	  begin
	    wr_ptr<=0;
		rd_ptr<=0;
		fillcount<=0;		
	  end
	else
	  begin
		if(put==1 && full_bar==1 && get == 0)
			begin
				mem[wr_ptr]<=data_in;
				wr_ptr<=wr_ptr+1;
				fillcount<=fillcount+1;
			end
		
		if(get==1 && empty_bar==1 && put ==0)
			begin
				data_out_temp<=mem[rd_ptr];
				rd_ptr<=rd_ptr+1;
				fillcount<=fillcount-1;
			end
			
		if(put==1 && get == 1)
			begin
				mem[wr_ptr]<=data_in;
				wr_ptr<=wr_ptr+1;
				data_out_temp<=mem[rd_ptr];
				rd_ptr<=rd_ptr+1;
				fillcount<=fillcount;
			end	
		//can be optimized when there is simultaneous read and write

	  end
  end

assign full_bar = (fillcount==DEPTH)?0:1;
assign empty_bar =(fillcount==0)?0:1; 
assign data_out = data_out_temp;
		    
	
endmodule 