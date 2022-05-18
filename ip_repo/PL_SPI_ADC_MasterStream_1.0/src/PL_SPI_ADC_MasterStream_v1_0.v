
`timescale 1 ns / 1 ps

	module PL_SPI_ADC_MasterStream_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 16,
		parameter integer C_M00_AXIS_START_COUNT	= 2
	)
	(
		// Users to add ports here
        output wire  o_SPI_Clk,
        input wire   i_SPI_MISO,
        output wire  o_SPI_MOSI,
        output wire  o_SPI_CS,
        
        input wire i_CMOS_Clk,
        input wire [11:0] i_CMOS_Data,
        input wire i_ADC_Work,
        output wire [7:0] o_LED,
//        output wire o_DMA_Reset,
        input wire i_Trigger,
        input wire i_Mode,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);
    wire  m00_axi_init_axi_txn;
    wire  w_ADC_Done;
    wire  w_ADC_Work;
    wire  w_Done_Clean;
    wire  w_Data_Cnt;
// Instantiation of Axi Bus Interface S00_AXI
	PL_SPI_ADC_MasterStream_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) PL_SPI_ADC_MasterStream_v1_0_S00_AXI_inst (
		.o_SPI_Clk(o_SPI_Clk),
	    .i_SPI_MISO(i_SPI_MISO),
	    .o_SPI_MOSI(o_SPI_MOSI),
	    .o_SPI_CS(o_SPI_CS),
	    .i_AXI_Done(),
	    .o_AXI_Init(m00_axi_init_axi_txn),
        .i_ADC_Done(w_ADC_Done),
        .o_ADC_Work(w_ADC_Work),
        .i_Data_Cnt(w_Data_Cnt),
        .i_Trigger(i_Trigger),
//        .o_LED(o_LED),
//        .o_Done_Clean(w_Done_Clean),
	
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	PL_SPI_ADC_MasterStream_v1_0_M00_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
	) PL_SPI_ADC_MasterStream_v1_0_M00_AXIS_inst (
		.i_CMOS_Clk(i_CMOS_Clk),
	    .i_CMOS_Data_MSB(i_CMOS_Data),
//	    .i_CMOS_Data_LSB(i_CMOS_Data[7:0]),
//	    .i_ADC_Work(i_ADC_Work),
        .i_ADC_Work(w_ADC_Work),
	    .o_ADC_Done(w_ADC_Done),
        .INIT_AXI_TXN(m00_axi_init_axi_txn),
        .o_LED(o_LED),
        .i_Mode(i_Mode),
        .o_Data_Cnt(w_Data_Cnt),
//        .i_Trigger(i_Trigger),
//        .i_Done_Clean(w_Done_Clean),
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(s00_axi_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready)
	);

	// Add user logic here

	// User logic ends

	endmodule