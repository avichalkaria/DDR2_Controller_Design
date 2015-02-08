module ddr2_controller(
   // Outputs
   dout, raddr, fillcount, notfull, ready, ck_pad, ckbar_pad,
   cke_pad, csbar_pad, rasbar_pad, casbar_pad, webar_pad, ba_pad,
   a_pad, dm_pad, odt_pad, validout, 
   // Inouts
   dq_pad, dqs_pad, dqsbar_pad,
   // Inputs
   clk, reset, read, cmd, din, addr, initddr,sz,op
   );
   
///////////////////////////////task1: determine the parameters ///////////////////////////////////////
   parameter BL = 4'b1000; // Burst Length =8
   parameter BT = 1'b0 ;   // Burst Type = Sequential
   parameter CL =3'b100 ;  // CAS Latency (CL) = 4
   parameter AL =3'b100 ;  // Posted CAS# Additive Latency (AL) = 2
/////////////////////////////////////////////////////////////////////////////////////////////////////

   input 	 clk;
   input 	 reset;
   input 	 read;
   input [2:0] cmd;
   input [15:0] din;
   input [24:0] addr;
   input [1:0] sz; // added by us
   input [2:0] op; //added by us 
   output [15:0] dout;
   output [24:0] raddr;
   output [3:0]  fillcount;
   output        validout;//////////
   output 		 notfull;
   input 		 initddr;
   output 		 ready;

   output 		 ck_pad;
   output 		 ckbar_pad;
   output 		 cke_pad;
   output 		 csbar_pad;
   output 		 rasbar_pad;
   output 		 casbar_pad;
   output 		 webar_pad;
   output [1:0]  ba_pad;
   output [12:0] a_pad;
   inout [15:0]  dq_pad;
   inout [1:0] 	 dqs_pad;
   inout [1:0] 	 dqsbar_pad;
   output [1:0]  dm_pad;
   output 		 odt_pad;
   
   /*autowire*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [15:0]		dataOut;				// From XDFIN of fifo.v
   wire [15:0]			dq_o;					// From XSSTL of SSTL18DDR2INTERFACE.v
   wire [1:0]			dqs_o;					// From XSSTL of SSTL18DDR2INTERFACE.v
   wire [1:0]			dqsbar_o;				// From XSSTL of SSTL18DDR2INTERFACE.v
   wire 					notfull;				// From XDFIN of fifo.v
   //wire [5:0]	CMD_fillcount, RETURN_fillcount;		// From XDFIN of fifo.v
	wire [3:0]	fillcount; //while changing width also change it in tb.v line 74, also output pin above
   wire					full;				// From XDFIN of fifo.v
   // End of automatics
   
   wire 		 ri_i;
   wire 		 ts_i;   
   reg 		 	ck_i;
   wire 		 cke_i;
   wire 		 csbar_i;
   wire 		 rasbar_i;
   wire 		 casbar_i;
   wire 		 webar_i;
   wire [1:0] 	 ba_i;
   wire [12:0] 	 a_i;
   wire [15:0] 	 dq_i;
   wire [1:0] 	 dqs_i;
   wire [1:0] 	 dqsbar_i;
   wire [1:0] 	 dm_i;
   wire 		 odt_i;


   
   reg ck;
   
   wire csbar, init_csbar;
   wire rasbar, init_rasbar;
   wire casbar, init_casbar;
   wire webar, init_webar;
   wire[1:0] ba, init_ba;
   wire[12:0] a,init_a;
   wire[1:0] dm, init_dm;
   wire init_cke;
   wire ri_con;
   
   wire [32:0] CMD_data_in, CMD_data_out;
   wire [40:0] RETURN_data_in, RETURN_data_out;
   wire CMD_empty, CMD_full, RETURN_empty, RETURN_full, IN_empty, IN_full; //IN signals defined by us
   wire  IN_get, CMD_get, RETURN_put;
   wire [15:0] DATA_data_out,DATA_data_in; // defined by us
   
   reg [6:0] clkval;
   reg cflag;
   reg [6:0] clkticker; 
	reg IN_put, CMD_put;
	reg	RETURN_get,validout;
	//wire  RETURN_get;
   // CK divider
       
		   
///////////////////////////////task2: determine the FIFO connections ///////////////////////////////////
  // Input data FIFO
   FIFO #(8,3,16) FIFO_IN (/*autoinst*/
						  .clk					(clk),
						  .reset				(reset),
						  .data_in              (din),
						  .put  				(IN_put),
						  .get					(IN_get),
						  .data_out				(DATA_data_out),
						  .empty_bar			(IN_empty),
	  		   		      .full_bar			    (IN_full),
						  .fillcount			(fillcount)
						  ); 
// Command FIFO						  
      FIFO #(8,3,33) FIFO_CMD (/*autoinst*/
						  .clk					(clk),
						  .reset				(reset),
						  .data_in              (CMD_data_in),
						  .put  				(CMD_put),
						  .get					(CMD_get),
						  .data_out				(CMD_data_out),
						  .empty_bar			(CMD_empty),
	  		   		      .full_bar			    (CMD_full),
						  .fillcount			()
						  ); 
// Return DATA and address FIFO	
	   FIFO #(8,3,41) FIFO_RETURN (/*autoinst*/
						  .clk					(clk),
						  .reset				(reset),
						  .data_in              (RETURN_data_in),
						  .put  				(RETURN_put),
						  .get					(RETURN_get),
						  .data_out				(RETURN_data_out),
						  .empty_bar			(RETURN_empty),
	  		   		      .full_bar			    (RETURN_full),
						  .fillcount			()
						  ); 
						  
/////////////////////////////////////////////////////////////////////////////////////////////////////
   
   // DDR2 Initialization engine
   ddr2_init_engine XINIT (
						   // Outputs
						   .ready				(ready),
						   .csbar				(init_csbar),
						   .rasbar				(init_rasbar),
						   .casbar				(init_casbar),
						   .webar				(init_webar),
						   .ba					(init_ba[1:0]),
						   .a					(init_a[12:0]),
						   //.dm					(init_dm[1:0]),
						   .odt					(init_odt),
						   .ts_con				(init_ts_con),
						   .cke                 (init_cke),
						   // Inputs
						   .clk					(clk),
						   .reset				(reset),
						   .init				(initddr),
						   .ck					(ck)		   );
						   
	// DDR2 Processing Logic					   
	Processing_logic PL0 (
							// Outputs
							.DATA_get			(IN_get), 
							.CMD_get			(CMD_get),
							.RETURN_put			(RETURN_put), 
							.RETURN_address		(RETURN_data_in[40:16]), 
							.RETURN_data		(RETURN_data_in[15:0]),  //construct RETURN_data_in
							.cs_bar				(csbar), 
							.ras_bar			(rasbar), 
							.cas_bar			(casbar), 
							.we_bar				(webar),  // read/write function
							.BA					(ba), 
							.A					(a), 
							.DM					(dm_i[1:0]), //check this out
							.DQS_out			(dqs_i[1:0]), //check this out
							.DQ_out				(dq_i[15:0]), //check this out
							.ts_con				(ts_i), //check this out
							// Inputs
							.clk				(clk), 
							.ck					(ck_i), 
							.reset				(reset), 
							.ready				(ready), 
							.CMD_empty			(CMD_empty), 
							.CMD_data_out		(CMD_data_out), 
							.DATA_data_out		(DATA_data_out), // check this out
							.RETURN_full		(RETURN_full),
							.DQS_in				(dqs_o[1:0]), //check this out
							.DQ_in				(dq_o[15:0]) //check this out
							);


   // Output Mux for control signals
   assign 		 a_i 	  = (ready) ? a      : init_a;
   assign 		 ba_i 	  = (ready) ? ba     : init_ba;

   assign 		 csbar_i  = (ready) ? csbar  : init_csbar;
   assign 		 rasbar_i = (ready) ? rasbar : init_rasbar;
   assign 		 casbar_i = (ready) ? casbar : init_casbar;
   assign 		 webar_i  = (ready) ? webar  : init_webar;

   assign 		 cke_i 	  = init_cke;
   assign 		 odt_i 	  = init_odt;
   
   assign ri_con = 1;
   // added by us
   assign notfull = (CMD_full) & (IN_full);
   assign DATA_data_in = din;
   assign CMD_data_in = {addr,cmd,sz,op}; 
   assign raddr = RETURN_data_out [40:16];
   assign dout = RETURN_data_out [15:0];
   //assign RETURN_get =read;
   //assign dqsbar_i = 1;
   

   SSTL18DDR2INTERFACE XSSTL (/*autoinst*/
							  // Outputs
							  .ck_pad			(ck_pad),
							  .ckbar_pad		(ckbar_pad),
							  .cke_pad			(cke_pad),
							  .csbar_pad		(csbar_pad),
							  .rasbar_pad		(rasbar_pad),
							  .casbar_pad		(casbar_pad),
							  .webar_pad		(webar_pad),
							  .ba_pad			(ba_pad[1:0]),
							  .a_pad			(a_pad[12:0]),
							  .dm_pad			(dm_pad[1:0]),
							  .odt_pad			(odt_pad),
							  .dq_o				(dq_o[15:0]),
							  .dqs_o			(dqs_o[1:0]),
							  //.dqsbar_o			(dqsbar_o[1:0]),
							  // Inouts
							  .dq_pad			(dq_pad[15:0]),
							  .dqs_pad			(dqs_pad[1:0]),
							  //.dqsbar_pad		(dqsbar_pad[1:0]),
							  // Inputs
							  .ri_i				(ri_con),
							  .ts_i				(ts_i),
							  .ck_i				(ck_i),
							  .cke_i			(cke_i),
							  .csbar_i			(csbar_i),
							  .rasbar_i			(rasbar_i),
							  .casbar_i			(casbar_i),
							  .webar_i			(webar_i),
							  .ba_i				(ba_i[1:0]),
							  .a_i				(a_i[12:0]),
							  .dq_i				(dq_i[15:0]),
							  .dqs_i			(dqs_i[1:0]),
							  //.dqsbar_i			(dqsbar_i[1:0]),
							  .dm_i				(dm_i[1:0]),
							  .odt_i			(odt_i));

   		always@(*)
			begin
				if(cflag) 
					begin
						CMD_put=0;
					end							
				else if(((cmd == 3'b001) || (cmd == 3'b010)  || (cmd == 3'b101) || (cmd == 3'b110) || (cmd==3'b011) || (cmd == 3'b100)) && (CMD_full) && (IN_full) && ready)
					begin
						CMD_put=1;
					end
				else 
					begin
						CMD_put = 0;
					end
		/////////////////////////////////			
				if(((cmd == 3'b010)  || (cmd == 3'b101) || (cmd == 3'b110) || (cmd == 3'b100) || (cflag==1'b1) )&& (CMD_full) && (IN_full) && ready)  
					begin
						IN_put=1 ;
					end
				else 
					begin
						IN_put= 0;
					end
					
		////////////////////////	
				
				if ((reset == 1'b1) || (ready == 1'b0)) begin
					RETURN_get = 1'b0;	
				end	
				else if (RETURN_empty == 1) begin
					RETURN_get = 1'b1;
				end
				else begin
					RETURN_get = 1'b0;
				end
			end
			
		 
		always@(posedge clk)
		begin
			if(reset)
			begin
				validout<=0;
				clkticker <=0;
				cflag<=0;
				ck_i <= 0;/////////////////////
			end
			else
			begin
				validout<=RETURN_empty;
				ck_i <= ~ck_i; // 250 MHz Clock
				
				if(cflag && IN_full)//////masterpiece begins here!!!
					begin
						clkticker<=clkticker-1;
						if(clkticker==1)
							begin
								cflag<=0;
							end
					end
				else if((cmd == 3'b100) && (CMD_full) && (IN_full))
					begin
						clkticker <= ((8 * (sz + 1)) - 1);
						cflag <= 1;
					end
				else
					begin
						clkticker<=clkticker;
						cflag<=cflag;
					end

			end
				 
			
		end

endmodule // ddr2_controller
