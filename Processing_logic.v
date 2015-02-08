//Aakash Barbhaya
//Avichal Karia
//Kathan P. Shah

module Processing_logic(
   // Outputs
   DATA_get, 
   CMD_get,
   RETURN_put, 
   RETURN_address, RETURN_data,  //construct RETURN_data_in
   cs_bar, ras_bar, cas_bar, we_bar,  // read/write function
   BA, A, DM,
   DQS_out, DQ_out,
   ts_con,
   // Inputs
   clk, ck, reset, ready, 
   CMD_empty, CMD_data_out, DATA_data_out,
   RETURN_full,
   DQS_in, DQ_in
   );

   parameter BL = 4'b1000; // Burst Lenght = 8
   parameter BT = 1'b0;   // Burst Type = Sequential
   parameter CL = 3'b100;  // CAS Latency (CL) = 4
   parameter AL = 3'b100;  // Posted CAS# Additive Latency (AL) = 4

   
   input 	 clk, ck, reset, ready;
   input 	 CMD_empty, RETURN_full;
   input [32:0]	 CMD_data_out;
   input [15:0]  DATA_data_out;
   input [15:0]  DQ_in;
   input [1:0]   DQS_in;
 
   output reg CMD_get;
   output reg		 DATA_get, RETURN_put;
   output reg [24:0] RETURN_address;
   output wire [15:0] RETURN_data;
   output reg	cs_bar, ras_bar, cas_bar, we_bar;
   output reg [1:0]	 BA;
   output reg [12:0] A;
   output reg [1:0]	 DM;
   output reg [15:0]  DQ_out;
   output reg [1:0]   DQS_out;
   output reg ts_con;
   

   reg listen;

   reg DM_flag;
   reg [2:0] OPCODE;
   reg [2:0] Pointer;
   reg [1:0] blkcounter;
   reg [6:0] counter;
   reg [5:0] state;		
   reg [15:0] ref_counter;
   reg [1:0] size;
   reg Atomic;
   reg [15:0] RETURN_data_temp1;
   wire [15:0] RETURN_data_temp;
   reg [15:0] DATA_data_out_temp1;
   reg [15:0] DATA_data_out_temp2;
   
	
   parameter IDLE=0,FETCH=1, DEC_ACT=2, READ=3, WRITE=4, WAIT_ACT=5, Refresh = 7, Refresh_counter = 8,IDLE_temp=9,Wait_to_dec1=10, Wait_to_dec2=11, BlockWr=12,BlockRd=13,Wait_to_BlockWr=14, Wait_to_BlockRd=15,AtomicWR=16, AtomicRD = 17;
   parameter NOP=3'b000, SREAD=3'b001, SWRITE=3'b010,BWRITE=3'b100, BREAD=3'b011, AWRITE =3'b110,AREAD = 3'b101; 
   
    parameter SUB = 3'b000, NAND =3'b001, ADD = 3'b010, XOR = 3'b011, NOR = 3'b100, FLIP = 3'b101, SRA = 3'b110, SLA = 3'b111;

always @(posedge clk)
    if(reset)
	  begin
	    state<=IDLE;
		counter <= 0; 
		ref_counter <= 0;
		DATA_get <= 0;
		CMD_get <= 0;
		listen <= 0;
		DM_flag <= 0;
		blkcounter<=0;
		RETURN_put <= 0;
		size<=0;
		Atomic <= 0;
	  end
	else
	  begin
		
		/*if (ready == 1'b1) begin
			ref_counter <= ref_counter + 1;	
		end*/
		
		case(state)

// ----------------------refresh-------------------------------------------------------------

			/*Refresh_counter: begin
							//{cs_bar, ras_bar, cas_bar, we_bar} <= 4'b1111;		//deactivate banks 	
								if(ref_counter > 16'h4BA0)
								begin
									state <= Refresh;
									ref_counter <= 0;
								end
								else
								begin
									state <= IDLE_temp;
								end
							 end
			
			IDLE_temp: begin
						state <= IDLE;
					   end	
					   
			Refresh: begin
					counter <= counter + 1;
					 if(counter==6'b000001)	
					 begin
					 {cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;		//NOP
					 end
					 else if(counter==6'b000011)	
					 begin
					 {cs_bar, ras_bar, cas_bar, we_bar}<=4'b0010;		//Precharge
					 A[10] <= 1;
					 //BA <= 2'b01 ;
					 end
					 else if(counter==6'b000101)	
				 	 begin
					 {cs_bar, ras_bar, cas_bar, we_bar} <= 4'b0111;		//NOP
					 end
					 else if(counter==6'b001101)	
					 begin
					 {cs_bar, ras_bar, cas_bar, we_bar}<=4'b0001;		//Refresh
					 end
					 else if(counter==6'b001111)
					 begin
					 {cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;		//NOP
					 end
					 else if(counter==6'b111110) 
					 begin
					 state<=IDLE;
					 counter<=0;
					 end 
					 else
					 begin
					 state<=Refresh;
					 end
					end */

//-------------------------------------------------------------------------------------------		
				
			IDLE: 	begin 																			//wait here till initialization is complete
						if(ready)
							begin
							CMD_get<=0;
							state<=FETCH;
							end
					end
					
					
			FETCH:	begin 																			//fetch instruction
						/*if(ref_counter > 16'h4BA0)
								begin
									counter <= 0;
									state <= Refresh;
									ref_counter <= 0;
								end */
						//CMD_get<=0;		
						 if(CMD_empty)
								begin 
									CMD_get<=1;
									state <= Wait_to_dec1;
								end
						/*if(CMD_empty)   // initial state
							begin
								CMD_get<=0;
								state<=DEC_ACT; 
							end*/
					end					
			Wait_to_dec1: begin
							CMD_get<=0;
							state<=Wait_to_dec2;
						 end
						 
			Wait_to_dec2:begin
							CMD_get<=0;
							state<=DEC_ACT;
						 end
		
					
			DEC_ACT:	begin																		//decoding and activating
						CMD_get<=0;
	
						if(CMD_data_out[7:5]==SREAD)
							begin 																	//scalar read 
								if(RETURN_full == 1'b1)
									begin	
										{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;				//activating						
										A <= CMD_data_out[32:20];									//row address
										BA <= CMD_data_out[19:18];									//bank address
										RETURN_address<=CMD_data_out[32:8];							//save address back to return address
										RETURN_put <= 0;											//make it one on successful read
										counter<=0;													//initializing counter
										state<=READ;
									end
								else
									begin
										state<=DEC_ACT;
									end
							end
							
						else if(CMD_data_out[7:5]==SWRITE)
							begin 																	//scalar write
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;						//activating
								A <=CMD_data_out[32:20];											//row address
								BA <=CMD_data_out[19:18];											//bank address
								counter<=0;
								state<=WRITE;
								ts_con<=1'b1;
							end
						
						else if(CMD_data_out[7:5]==BWRITE)
							begin 																	//scalar write
								/*{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;						//activating
								A <=CMD_data_out[32:20];											//row address
								BA <=CMD_data_out[19:18];											//bank address
								//blkcounter<=CMD_data_out[4:3]+1;///////////size+1
								counter<=0;
								//state<=BlockWr;
								ts_con<=1'b1;*/
								state <= Wait_to_BlockWr;
							end

						else if(CMD_data_out[7:5]==BREAD)
							begin 																	//scalar read 
								if(RETURN_full == 1'b1)////////change karna padenga
									begin	
										
										RETURN_address<=CMD_data_out[32:8];							//save address back to return address
										RETURN_put <= 0;											//make it one on successful read
										//blkcounter<=CMD_data_out[4:3]+1;                            // added   										
										state<=Wait_to_BlockRd;
									end
								else
									begin
										state<=DEC_ACT;
									end
							end
							
							else if(CMD_data_out[7:5]==AREAD)
							begin 																	//scalar read 
								if(RETURN_full == 1'b1)////////change karna padenga
									begin	
										Atomic <= 0; 
										{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;				//activating						
										A <= CMD_data_out[32:20];									//row address
										BA <= CMD_data_out[19:18];									//bank address
										RETURN_address<=CMD_data_out[32:8];							//save address back to return address
										RETURN_put <= 0;											//make it one on successful read
										counter<=0;													//initializing counter
										state<=AtomicRD;									//make it one on successful read
										OPCODE <= CMD_data_out[2:0];
									end
								else
									begin
										state<=DEC_ACT;
									end
							end	
							
							
							
							else if(CMD_data_out[7:5]==AWRITE)
							begin 																	//scalar read 
								if(RETURN_full == 1'b1)////////change karna padenga
									begin	
										Atomic <= 1;
										{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;				//activating						
										A <= CMD_data_out[32:20];									//row address
										BA <= CMD_data_out[19:18];									//bank address
										RETURN_address<=CMD_data_out[32:8];							//save address back to return address
										RETURN_put <= 0;											//make it one on successful read
										counter<=0;													//initializing counter
										state<=AtomicWR;									//make it one on successful read
										OPCODE <= CMD_data_out[2:0];
										
									end
								else
									begin
										state<=DEC_ACT;
									end
							end	
							
							
						else if(CMD_data_out[7:5]==NOP)
							begin
								state <= IDLE;
							end
							
						else
							begin
								state <= IDLE; 
							end				
						end
						
						
			READ: 		begin
						
						counter<=counter+1;

						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						// NOP
								end
								
							3:	begin 																//issue read command
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
								A[9:0] <=CMD_data_out[17:8]; 									//colmn address check this out
								A[10]<=1'b1; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
															
							19: begin
								listen <= 1'b1;														//Make Listen high
								end
								
							20: begin
								listen <= 1'b0;												     	//Make Listen Low
								end
						
							21:	begin 																//tras =24 and trp = 50 here: assumption
								RETURN_put <= 1'b1;         										//start fetching
								Pointer <= 0;
								end
								
							22: begin
								RETURN_put <= 1'b0;  												// clear FIFO put
								end	
								
							62:	begin 																//put tras + trp count:
									counter <= 0;
									state<=IDLE;
								end
						endcase
						end
			WRITE: 		begin
						counter<=counter+1;
						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						// NOP
								end
								
							3:	begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
								A[9:0] <=CMD_data_out[17:8]; 									
								A[10]<=1'b1; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
								
							16: begin
								DATA_get <= 1'b1;
								DQS_out <= 2'b00;
								end
								
							17: begin
								DQS_out <= 2'b00;
								DM_flag <= 1'b1;
								DATA_get <= 1'b0;
								end
								
							18: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b0;
								end
								
							19: begin
								DQS_out <= 2'b00;
								end
								
							20: begin
								DQS_out <= 2'b11;
								end
								
							21: begin
								DQS_out <= 2'b00;
								end
								
							22: begin
								DQS_out <= 2'b11;
								end
								
							23: begin
								DQS_out <= 2'b00;
								end
								
							24: begin
								DQS_out <= 2'b11;
								end
								
							25: begin
								DQS_out <= 2'b00;
								end
								
							26: begin
								DQS_out <= 2'b00;
								ts_con<=1'b0;
								end
								
							62:	begin
									counter <= 0;
									state<= IDLE;
								end
						endcase
						end	
						
						
						
							
						
								
		AtomicRD:	begin //READ
						
						counter<=counter+1;

						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						// NOP
								end
								
							3:	begin 																//issue read command
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
								A[9:0] <=CMD_data_out[17:8]; 									//colmn address check this out
								A[10]<=1'b0; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
															
							19: begin
								listen <= 1'b1;														//Make Listen high
								DATA_get <= 1'b1;
								end
								
							20: begin
								listen <= 1'b0;												     	//Make Listen Low
								DATA_get <= 1'b0;
								end
						
							21:	begin 																//tras =24 and trp = 50 here: assumption
								         										
								//RETURN_data_temp <= RETURN_data;
								Pointer <= 0;
								DATA_get <= 1'b0;
								RETURN_put <= 1'b1; 
								
									if (OPCODE == SUB) begin
									RETURN_data_temp1 <= DATA_data_out - RETURN_data_temp;
									end
									else if (OPCODE == NAND) begin
									RETURN_data_temp1 <= ~(DATA_data_out & RETURN_data_temp);
									end
									else if (OPCODE == ADD) begin
									RETURN_data_temp1 <= DATA_data_out + RETURN_data_temp;
									end
									else if (OPCODE == XOR) begin
									RETURN_data_temp1 <= DATA_data_out ^ RETURN_data_temp;
									end
									else if (OPCODE == NOR) begin
									RETURN_data_temp1 <= ~(DATA_data_out | RETURN_data_temp);
									end
									else if (OPCODE == FLIP) begin
									RETURN_data_temp1 <= ~(RETURN_data_temp);
									end
									else if (OPCODE == SRA) begin
									RETURN_data_temp1 <= {RETURN_data_temp[15:1],1'b0};
									end
									else if (OPCODE == SLA) begin
									RETURN_data_temp1 <= {1'b0,RETURN_data_temp[14:0]};
									end
									else begin
									RETURN_data_temp1 <= RETURN_data_temp;
									end
								end
								
							22:	begin
								RETURN_put <= 1'b0;
								end
								
							
							63:	begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
								A[9:0] <=CMD_data_out[17:8]; 									
								A[10]<=1'b1; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								ts_con<=1'b1;
								Atomic <= 1;
								end
								
							65:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
								
							76: begin
								
								DQS_out <= 2'b00;
								DATA_data_out_temp2 <= RETURN_data_temp1;
								end
								
							77: begin
								DQS_out <= 2'b00;
								DM_flag <= 1'b1;
								
								
								end
								
							78: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b0;
								end
								
							79: begin
								DQS_out <= 2'b00;
								end
								
							80: begin
								DQS_out <= 2'b11;
								end
								
							81: begin
								DQS_out <= 2'b00;
								end
								
							82: begin
								DQS_out <= 2'b11;
								end
								
							83: begin
								DQS_out <= 2'b00;
								end
								
							84: begin
								DQS_out <= 2'b11;
								end
								
							85: begin
								DQS_out <= 2'b00;
								end
								
							86: begin
								DQS_out <= 2'b00;
								ts_con<=1'b0;
								end
								
								
								
								
								
							
			
							122:	begin 																//put tras + trp count:
									counter <= 0;
									state<=IDLE;
									Atomic <= 0;
								end
			
						endcase
						end					
						
		AtomicWR:	begin //READ
						
						counter<=counter+1;

						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						// NOP
								end
								
							3:	begin 																//issue read command
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
								A[9:0] <=CMD_data_out[17:8]; 									//colmn address check this out
								A[10]<=1'b0; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
															
							19: begin
								listen <= 1'b1;														//Make Listen high
								DATA_get <= 1'b1;
								end
								
							20: begin
								listen <= 1'b0;												     	//Make Listen Low
								DATA_get <= 1'b0;
								end
						
							21:	begin 																//tras =24 and trp = 50 here: assumption
								         										
								//RETURN_data_temp <= RETURN_data;
								Pointer <= 0;
								DATA_get <= 1'b0;
								
								
									if (OPCODE == SUB) begin
									RETURN_data_temp1 <= DATA_data_out - RETURN_data_temp;
									end
									else if (OPCODE == NAND) begin
									RETURN_data_temp1 <= ~(DATA_data_out & RETURN_data_temp);
									end
									else if (OPCODE == ADD) begin
									RETURN_data_temp1 <= DATA_data_out + RETURN_data_temp;
									end
									else if (OPCODE == XOR) begin
									RETURN_data_temp1 <= DATA_data_out ^ RETURN_data_temp;
									end
									else if (OPCODE == NOR) begin
									RETURN_data_temp1 <= ~(DATA_data_out | RETURN_data_temp);
									end
									else if (OPCODE == FLIP) begin
									RETURN_data_temp1 <= ~(RETURN_data_temp);
									end
									else if (OPCODE == SRA) begin
									RETURN_data_temp1 <= {RETURN_data_temp[15:1],1'b0};
									end
									else if (OPCODE == SLA) begin
									RETURN_data_temp1 <= {1'b0,RETURN_data_temp[14:0]};
									end
									else begin
									RETURN_data_temp1 <= RETURN_data_temp;
									end
								end
								
							
							63:	begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
								A[9:0] <=CMD_data_out[17:8]; 									
								A[10]<=1'b1; 														//autoprecharge
								BA <=CMD_data_out[19:18];
								ts_con<=1'b1;
								end
								
							65:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
								
							76: begin
								
								DQS_out <= 2'b00;
								DATA_data_out_temp2 <= RETURN_data_temp1;
								end
								
							77: begin
								DQS_out <= 2'b00;
								DM_flag <= 1'b1;
								
								
								end
								
							78: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b0;
								end
								
							79: begin
								DQS_out <= 2'b00;
								end
								
							80: begin
								DQS_out <= 2'b11;
								end
								
							81: begin
								DQS_out <= 2'b00;
								end
								
							82: begin
								DQS_out <= 2'b11;
								end
								
							83: begin
								DQS_out <= 2'b00;
								end
								
							84: begin
								DQS_out <= 2'b11;
								end
								
							85: begin
								DQS_out <= 2'b00;
								end
								
							86: begin
								DQS_out <= 2'b00;
								ts_con<=1'b0;
								end
								
								
								
								
								
							
			
							122:	begin 																//put tras + trp count:
									counter <= 0;
									state<=IDLE;
									Atomic <= 0;
								end
			
						endcase
						end	

			Wait_to_BlockWr: begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;						//activating
								A <=CMD_data_out[32:20];											//row address
								BA <=CMD_data_out[19:18];											//bank address
								//blkcounter<=CMD_data_out[4:3]+1;///////////size+1
								counter<=0;
								//state<=BlockWr;
								ts_con<=1'b1;
								state <= BlockWr;
							 end	
			BlockWr: 		begin
						counter<=counter+1;
						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;								// NOP
								//blkcounter<=blkcounter-1;
								end
								
							3:	begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
								A[9:0] <=CMD_data_out[17:8]; 										//colmn address check this out
								if (CMD_data_out[4:3] != 2'b00) begin
									A[10]<=0;
								end
								else begin
									A[10]<=1;
								end
								BA <=CMD_data_out[19:18];
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
//--------------------------------------------------------------------------------------------
							11: begin
								 if (CMD_data_out[4:3] != 2'b00) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
									A[9:0] <=CMD_data_out[17:8] + 8; 										//colmn address check this out
																							//autoprecharge
									BA <=CMD_data_out[19:18];
								 end
								 if(CMD_data_out[4:3]==1) begin
									A[10]<=1;
								 end
								 else begin
									A[10]<=0;
								 end								
								
								end
							13: begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111; 						//NOP
								end	
//----------------------------------------------------------------------------------------------								
							16: begin
								DATA_get <= 1'b1;
								DQS_out <= 2'b00;
								end
								
							17: begin
								DQS_out <= 2'b00;
								DM_flag <= 1'b1;
								end
//---------------------------------start of first block---------------------------------------------								
							18: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b1;
								end
								
							19: begin
								if (CMD_data_out[4:3] == 2'b10 || CMD_data_out[4:3] == 2'b11) begin //size>16
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
									A[9:0] <=CMD_data_out[17:8] + 16; 										//colmn address check this out
																							//autoprecharge
									BA <=CMD_data_out[19:18];
								 end
								if (CMD_data_out[4:3] == 2'b11) begin
									A[10]<=1'b0; 
								end
								else begin
									A[10]<=1'b1;
								end
								DQS_out <= 2'b00;
								end
								
							20: begin
								DQS_out <= 2'b11;
								end
								
							21: begin
								if (CMD_data_out[4:3] > 2'b01) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end	
								DQS_out <= 2'b00;
								end
								
							22: begin
								DQS_out <= 2'b11;
								end
								
							23: begin
								DQS_out <= 2'b00;
								end
								
							24: begin
								DQS_out <= 2'b11;
								 if (CMD_data_out[4:3] == 2'b00) begin
									DATA_get <= 1'b0;
								 end	
								end
								
							25: begin
								DQS_out <= 2'b00;
									if (CMD_data_out[4:3] == 2'b00) begin
									//DATA_get <= 1'b0;
									DM_flag <= 1'b0;
									counter <= 50;
									end	
								end
//---------------------------------------end of first block---------------------------------------------								

//---------------------------------start of second block---------------------------------------------								
							26: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b1;
								end
								
								
							27: begin
								if (CMD_data_out[4:3] == 2'b11) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0100;						//issue write command
									A[9:0] <=CMD_data_out[17:8] + 24; 									//colmn address check this out
									A[10]<=1'b1; 														//autoprecharge
									BA <=CMD_data_out[19:18];
								 end
								DQS_out <= 2'b00;
								end
								
							28: begin
								DQS_out <= 2'b11;
								end
								
							29: begin
								if (CMD_data_out[4:3] > 2'b10) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end								
								
								DQS_out <= 2'b00;
								end
								
							30: begin
								DQS_out <= 2'b11;
								end
								
							31: begin
									
								
								DQS_out <= 2'b00;
								end
								
							32: begin
								DQS_out <= 2'b11;
								 if (CMD_data_out[4:3] == 2'b01) begin
									DATA_get <= 1'b0;
								 end	
								end
								
							33: begin
								DQS_out <= 2'b00;
									if (CMD_data_out[4:3] == 2'b01) begin
									//DATA_get <= 1'b0;
									DM_flag <= 1'b0;
									counter <= 50;
									end
								end
//---------------------------------------end of second block---------------------------------------------								

//---------------------------------start of third block---------------------------------------------								
							34: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b1;
								end
								
							35: begin
								DQS_out <= 2'b00;
								end
								
							36: begin
								DQS_out <= 2'b11;
								end
								
							37: begin
								DQS_out <= 2'b00;
								end
								
							38: begin
								DQS_out <= 2'b11;
								end
								
							39: begin
								DQS_out <= 2'b00;
								end
								
							40: begin
								DQS_out <= 2'b11;
								 if (CMD_data_out[4:3] == 2'b10) begin
									DATA_get <= 1'b0;
								 end
								end
								
							41: begin
								DQS_out <= 2'b00;
									if (CMD_data_out[4:3] == 2'b10) begin
									//DATA_get <= 1'b0;
									DM_flag <= 1'b0;
									counter <= 50;
									end
								end
//---------------------------------------end of third block---------------------------------------------								

//---------------------------------start of fourth block---------------------------------------------								
							42: begin
								DQS_out <= 2'b11;
								DM_flag <= 1'b1;
								end
								
							43: begin
								DQS_out <= 2'b00;
								end
								
							44: begin
								DQS_out <= 2'b11;
								end
								
							45: begin
								DQS_out <= 2'b00;
								end
								
							46: begin
								DQS_out <= 2'b11;
								end
								
							47: begin
								DQS_out <= 2'b00;
								end
								
							48: begin
								DQS_out <= 2'b11;
								DATA_get <= 1'b0;
								end
								
							49: begin
								DQS_out <= 2'b00;								
								//DATA_get <= 1'b0;
								DM_flag <= 1'b0;
								end
//---------------------------------------end of fourth block---------------------------------------------								
							
							
							50: begin
								DQS_out <= 2'b00;
								ts_con<=1'b0;
								end
								
							85:	begin
									counter <= 0;
									
									//if(blkcounter==0)
									//begin
										state<=IDLE;
									//end
								end					
								
						endcase
						end
		Wait_to_BlockRd:begin				
							{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0011;				//activating						
							A <= CMD_data_out[32:20];									//row address
							BA <= CMD_data_out[19:18];									//bank address
							counter<=0;													//initializing counter
							state<=BlockRd;
						end
		BlockRd: 		begin
						
						counter<=counter+1;

						case(counter)
							1:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						// NOP
								end
								
							3:	begin 																//issue read command
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
								A[9:0] <=CMD_data_out[17:8];	 									//colmn address check this out
								BA <=CMD_data_out[19:18];
								if(CMD_data_out[4:3] == 2'b00) begin
									A[10]<=1;
								end
								else begin
									A[10]<=0;
								end
								end
								
							5:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
								
							13: begin
								if(CMD_data_out[4:3] != 2'b00) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
									A[9:0] <=CMD_data_out[17:8]+8;
								end
								if(CMD_data_out[4:3] == 2'b01) begin
									A[10]<=1;
								end
								else begin
									A[10]<=0;
								end
								end
								
							15:  begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;						//NOP
								end
								
							19: begin
								listen <= 1'b1;														//Make Listen high
								end
								
							20: begin
								listen <= 1'b0;												     	//Make Listen Low
								end
						
							21:	begin 																//tras =24 and trp = 50 here: assumption
								RETURN_put <= 1'b1;         										//start fetching
								Pointer <= 0;
								
								end
								
							22: begin
								Pointer <=1; 
								RETURN_address <= RETURN_address + 1;
								end
									
							23: begin
								RETURN_address <= RETURN_address + 1;
								if(CMD_data_out[4:3] == 2'b10 || CMD_data_out[4:3] == 2'b11) begin
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
								A[9:0] <=CMD_data_out[17:8]+16;
								end
								Pointer <=2;
								if(CMD_data_out[4:3] == 2'b10) begin
									A[10]<=1;
								end
								else begin
									A[10]<=0;
								end
								end

							24: begin
								Pointer <=3;
								RETURN_address <= RETURN_address + 1;
								end

							25: begin
								Pointer <=4;
								RETURN_address <= RETURN_address + 1;
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;
								end
								
							26: begin
								Pointer <=5;
								RETURN_address <= RETURN_address + 1;
								end
							27: begin
								Pointer <=6;
								RETURN_address <= RETURN_address + 1;
								end

							28: begin
								Pointer <=7;
								RETURN_address <= RETURN_address + 1;
								if (CMD_data_out[4:3] == 2'b00) begin
									counter <= 59;
								end	
								end

							29: begin
								listen<=1;
								RETURN_put<=0;
								end								

							30: begin
								listen<=0;
								end
								
							31: begin
								RETURN_put<=1;
								Pointer <=0;
								RETURN_address <= RETURN_address + 1;
								end

							32: begin
								Pointer <=1;
								RETURN_address <= RETURN_address + 1;
								end
							
							33: begin
								RETURN_address <= RETURN_address + 1;
								if(CMD_data_out[4:3] == 2'b11) begin
									{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0101;
									A[9:0] <=CMD_data_out[17:8]+24;
								end
								Pointer <=2;
								A[10]<=1;
								end
							
							34: begin
								Pointer <=3;
								RETURN_address <= RETURN_address + 1;
								end
								
							35: begin
								Pointer <=4;
								{cs_bar, ras_bar, cas_bar, we_bar}<=4'b0111;
								RETURN_address <= RETURN_address + 1;
								end
							
							36: begin
								Pointer <=5;
								RETURN_address <= RETURN_address + 1;
								end
							
							37: begin
								Pointer <=6;
								RETURN_address <= RETURN_address + 1;
								end
								
							38: begin
								RETURN_address <= RETURN_address + 1;
								Pointer <=7;
								if (CMD_data_out[4:3] == 2'b01) begin
									counter <= 59;
								end	
								end
								
							39: begin
								listen<=1;
								RETURN_put<=0;
								
								end								

							40: begin
								listen<=0;
								end
								
							41: begin
								RETURN_put<=1;
								Pointer <=0;
								RETURN_address <= RETURN_address + 1;
								end

							42: begin
								Pointer <=1;
								RETURN_address <= RETURN_address + 1;
								end
							
							43: begin
								Pointer <=2;
								RETURN_address <= RETURN_address + 1;
								end
							
							44: begin
								Pointer <=3;
								RETURN_address <= RETURN_address + 1;
								end
								
							45: begin
								Pointer <=4;
								RETURN_address <= RETURN_address + 1;
								end
							
							46: begin
								Pointer <=5;
								RETURN_address <= RETURN_address + 1;
								end
							
							47: begin
								Pointer <=6;
								RETURN_address <= RETURN_address + 1;
								end
								
							48: begin
								RETURN_address <= RETURN_address + 1;
								Pointer <=7;
								if (CMD_data_out[4:3] == 2'b10) begin
									counter <= 59;
								end	
								end
							
							49: begin
								listen<=1;
								RETURN_put<=0;
								end								

							50: begin
								listen<=0;
								end
								
							51: begin
								RETURN_put<=1;
								Pointer <=0;
								RETURN_address <= RETURN_address + 1;
								end

							52: begin
								Pointer <=1;
								RETURN_address <= RETURN_address + 1;
								end
							
							53: begin
								Pointer <=2;
								RETURN_address <= RETURN_address + 1;
								end
							
							54: begin
								Pointer <=3;
								RETURN_address <= RETURN_address + 1;
								end
								
							55: begin
								Pointer <=4;
								RETURN_address <= RETURN_address + 1;
								end
							
							56: begin
								Pointer <=5;
								RETURN_address <= RETURN_address + 1;
								end
							
							57: begin
								Pointer <=6;
								RETURN_address <= RETURN_address + 1;
								end
								
							58: begin
								Pointer <=7;
								RETURN_address <= RETURN_address + 1;
								end
							
							59: begin
								RETURN_put<=0;
								end
							
							85:	begin 																//put tras + trp count:
									counter <= 0;
									//if(blkcounter==0)
									//begin
										state<=IDLE;
									//end
								end
						endcase
						end
		endcase		
	  end


	  
ddr2_ring_buffer8 ring_buffer(RETURN_data_temp, listen, DQS_in[0], Pointer[2:0], DQ_in, reset);

assign RETURN_data = (Atomic) ? RETURN_data_temp1 : RETURN_data_temp;

always @(negedge clk)
  begin
	if (Atomic)begin
	DQ_out <= DATA_data_out_temp2;
	end
	else begin
    DQ_out <= DATA_data_out;
    end
	if(DM_flag)
        DM <= 2'b00;
    else
        DM <= 2'b11;	
  end
 
endmodule // ddr2_controller


