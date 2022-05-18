`define Data_Size 250000
`timescale 1 ns / 1 ps

	module PL_SPI_ADC_MasterStream_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 16,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 4
	)
	(
		// Users to add ports here
        input wire i_CMOS_Clk,
//        input wire [11:0] i_CMOS_Data,
        input wire [11:0] i_CMOS_Data_MSB,
//        input wire [7:0] i_CMOS_Data_LSB,
//        output wire [13:0] o_CMOS_Data,
        input wire i_ADC_Work,
        output wire o_ADC_Done,
        input wire  INIT_AXI_TXN,
        output wire [7:0] o_LED,
        input wire i_Trigger,
        input wire i_Mode,
		output wire [33:0] o_Data_Cnt,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
	// Total number of output data                                                 
	localparam NUMBER_OF_OUTPUT_WORDS = `Data_Size;                                               
//	localparam NUMBER_OF_OUTPUT_WORDS = 256;                                                                            
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 (input integer bit_depth);                                   
	  begin                                                                              
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
	      bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction                                                                          
	                                                                                     
	// WAIT_COUNT_BITS is the width of the wait counter.                                 
	localparam integer WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1);                      
//	localparam integer WAIT_COUNT_BITS = 1;                      
	// bit_num gives the minimum number of bits needed to address 'depth' size of FIFO.  
	localparam bit_num  = clogb2(NUMBER_OF_OUTPUT_WORDS);                                
//	localparam bit_num  = 32;                                
	                                                                                     
	// Define the states of state machine                                                
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO                                      
	parameter [1:0] IDLE = 2'b00,        // This is the initial/idle state               
	                                                                                     
	                INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
	                                // the counter reaches C_M_START_COUNT count,        
	                                // the state machine changes state to SEND_STREAM     
	                SEND_STREAM   = 2'b10; // In this state the                          
	                                     // stream data is output through M_AXIS_TDATA   
	// State variable                                                                    
	reg [1:0] mst_exec_state = 0;                                                            
	// Example design FIFO read pointer                                                  
	reg [bit_num-1:0] read_pointer = 0;                                                      
    reg [bit_num-1:0] write_pointer = 0;
    reg [bit_num-1:0] r_count = 0;
    reg [11:0] r_Receive [NUMBER_OF_OUTPUT_WORDS - 1: 0];
	// AXI Stream internal signals
	//wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	reg [WAIT_COUNT_BITS-1 : 0] 	count = 0;
	//streaming data valid
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay = 0;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay = 0;
	//FIFO implementation signals
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] 	stream_data_out = 0;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;

    reg [7:0] r_LED = 0;
    reg [3:0] r_addon = 0;
    reg r_Parameter_Init = 0;
	// I/O Connections assignments

	assign M_AXIS_TVALID	= axis_tvalid_delay;
	assign M_AXIS_TDATA	= stream_data_out;
//	assign M_AXIS_TDATA	= w_CMOS_Data;
	assign M_AXIS_TLAST	= axis_tlast_delay;
	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};
    assign o_LED = r_LED;

	// Control state machine implementation                             
	always @(posedge M_AXIS_ACLK)                                             
	begin                                                                     
	  if (!M_AXIS_ARESETN)                                                    
	  // Synchronous reset (active low)                                       
	    begin                                                                 
	      mst_exec_state <= IDLE;                                             
	      count    <= 0;                                                      
	    end                                                                   
	  else                                                                    
	    case (mst_exec_state)                                                 
	      IDLE:                                                               
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        //if ( count == 0 )                                                 
	        //  begin
	        if (INIT_AXI_TXN & !tx_done)  
	        begin                   
	            count <= 0;                                     
	            mst_exec_state  <= INIT_COUNTER;  
	            r_Parameter_Init <= 1;
	        end                                                                  
	        else                                                              
	          begin                                                           
	            mst_exec_state  <= IDLE;                                      
	          end                                                             
	                                                                          
	      INIT_COUNTER:                                                       
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        if ( count == C_M_START_COUNT - 1 )                               
	          begin                                                           
	            mst_exec_state  <= SEND_STREAM; 
	            r_Parameter_Init <= 0;                              
	          end                                                             
	        else                                                              
	          begin                                                           
	            count <= count + 1;                                           
	            mst_exec_state  <= INIT_COUNTER;                      
	          end                                                             
	                                                                          
	      SEND_STREAM:                                                        
	        // The example design streaming master functionality starts       
	        // when the master drives output tdata from the FIFO and the slave
	        // has finished storing the S_AXIS_TDATA                          
	        if (tx_done)                                                      
	          begin                                                           
	            mst_exec_state <= IDLE;                                       
	          end                                                             
	        else                                                              
	          begin                                                           
	            mst_exec_state <= SEND_STREAM;                                
	          end                                                             
	    endcase                                                               
	end                                                                       
    reg r_TXN = 0;
    reg r_last = 0;
    reg [bit_num-1:0] r_Data_Cnt = 0;
    
    assign o_Data_Cnt = r_Data_Cnt;
    
    always @(posedge M_AXIS_ACLK)
    begin
        if (INIT_AXI_TXN)                               // start transmit
        begin
            r_TXN <= 1;                                                     
            tx_done <= 1'b0;
            r_last <= 0;
        end
//        else if (r_TXN && tx_en)                        // gen last signal
//        begin
//            r_last <= 1;
//        end
        
        if (M_AXIS_TREADY && (read_pointer == NUMBER_OF_OUTPUT_WORDS))               //end & reset
//        if (M_AXIS_TREADY && (r_last || read_pointer == NUMBER_OF_OUTPUT_WORDS))               //end & reset
        begin
            r_TXN <= 0;
            r_last <= 0;                                                         
            tx_done <= 1'b1; 
            r_Data_Cnt <= r_count;
        end

    end
	//tvalid generation
	//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	//number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && (read_pointer <= NUMBER_OF_OUTPUT_WORDS) && r_TXN);
	// AXI tlast generation                                                                        
	// axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1
	                                                                   
	assign axis_tlast = ((read_pointer == NUMBER_OF_OUTPUT_WORDS-1) || r_last);                                        
	                                                                                               
	                                                                                               
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	// to match the latency of M_AXIS_TDATA                                                        
	always @(posedge M_AXIS_ACLK)                                                                  
	begin                                                                                          
	  if (!M_AXIS_ARESETN)                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= 1'b0;                                                               
	      axis_tlast_delay <= 1'b0;                                                                
	    end                                                                                        
	  else                                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end                                                                                        
	end                                                                                            

	//read_pointer pointer

    always @ (posedge M_AXIS_ACLK)
    begin
        if (!tx_done && write_pointer <= NUMBER_OF_OUTPUT_WORDS - 1 && read_pointer < write_pointer)
        begin
	        if (i_Mode)
	        begin
                r_Receive[write_pointer]<= i_CMOS_Data_MSB;
            end
            else
                r_Receive[write_pointer] = r_count;
        end
    end

    always@(posedge M_AXIS_ACLK)                                               
    begin                                                                            
        if(!M_AXIS_ARESETN)                                                            
        begin
            write_pointer <= 0;                                                                        
            read_pointer <= 0;                                                           
        end                                                                          
        else if (INIT_AXI_TXN || r_TXN)  
        begin
            if (axis_tvalid)
            begin 
                r_count = r_count + 1;
                if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1)                                
                begin
                    write_pointer <= write_pointer + 1;                                                                      
                    if (tx_en)                                                               
                    // read pointer is incremented after every read from the FIFO          
                    // when FIFO read signal is enabled.                                   
                    begin                                                                  
                        read_pointer <= read_pointer + 1;                                                    
                    end                                                                    
                end                                                                        
            end  
        end
        else if (tx_done)
        begin
            read_pointer <= 0;
            write_pointer <= 0;     
            r_count <= 0;
        end                                                                    
    end                                                                              
    

	//FIFO read enable generation 

	assign tx_en = M_AXIS_TREADY && axis_tvalid;   
	                                                     
	    // Streaming output data is read from FIFO       
	    always @( posedge M_AXIS_ACLK )                  
	    begin                                            
	      if(!M_AXIS_ARESETN)                            
	        begin                                        
	          stream_data_out <= 1;                      
	        end                                          
	      else if (tx_en)// && M_AXIS_TSTRB[byte_index]  
	        begin                                        
//	          stream_data_out <= read_pointer + 16'b1 + r_addon;   
//                stream_data_out <= w_CMOS_Data;
                stream_data_out <= r_Receive[read_pointer];
	        end                                          
	    end       
    
//    assign o_ADC_Done = 1;
	// Add user logic here
	always @(*)
	begin
	   r_LED[0] = M_AXIS_TREADY;
	   r_LED[1] = axis_tvalid;
	   r_LED[2] = (read_pointer == 0);
	   r_LED[3] = tx_done;
	   r_LED[4] = (read_pointer == NUMBER_OF_OUTPUT_WORDS);
	   r_LED[5] = tx_en;
	   r_LED[6] = read_pointer > 0;
//	   r_LED[5-:2] = r_addon;
	   r_LED[7] = mst_exec_state == SEND_STREAM;
//       r_LED[5] = read_pointer <= NUMBER_OF_OUTPUT_WORDS-1;
	end
	// User logic ends

	endmodule