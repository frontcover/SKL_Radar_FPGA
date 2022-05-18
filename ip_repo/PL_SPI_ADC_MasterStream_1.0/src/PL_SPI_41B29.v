`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2021 11:25:18 AM
// Design Name: 
// Module Name: SPI_scr_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define f_Reset     1
`define f_Data      2
`define f_Send      8
`define f_Rece      4

module PL_SPI
  #(parameter CLKS_PER_HALF_BIT = 9
//    parameter CNT_PER_PHRASE = 100000000 //300M
  )
  (
     // Control/Data Signals
   input        i_Clk,       // FPGA Clock

   // Register Value Control
   input        [7:0] i_Cmd_Lim,
   input        [7:0] i_StatusReg,
   input        [7:0] i_TxBuffer,

   output reg   [7:0] o_RxBuffer,
   output reg   [7:0] o_StatusReg,

   // SPI Interface
   output reg   o_SPI_Clk,
   input        i_SPI_MISO,
   output reg   o_SPI_MOSI,
   output reg   o_SPI_CS,
   
//   input        i_CMOS_Clk,
//   input        [13:0] i_CMOS_Data,
//   output reg   [13:0] o_CMOS_Data,
   input        i_ADC_Done,
   output reg   o_AXI_Init,
   output reg   [7:0] o_ADC_State,
   input        i_ADC_Trigger,
    
   output reg   o_StatusRW = 0,
   output reg   [7:0] o_LED_Temp,
   output reg   [7:0] o_Tx_Cnt

   );

  wire w_CPOL;     // Clock polarity
  wire w_CPHA;     // Clock phase
  
//  wire f_Reset;
//  wire f_RdySend;
//  wire f_DataIn;
//  wire f_RdyRece;
  
  reg [7:0] r_Tx_Cnt = 0;
  reg [7:0] r_Cmd_Lim;
  reg [2:0] r_Cmd_Cnt = 0;
  reg [7:0] i_TX_Byte[0:40]; //68
  reg [7:0] r_TX_Byte_Cnt;

  reg r_SPI_MOSI = 0;
  reg r_SPI_CS = 1;
  reg r_SPI_Clk = 0;
  reg r_Leading_Edge = 0;
  reg r_Trailing_Edge = 0;

  reg [7:0]r_SPI_END = 0;
  reg [7:0]r_SPI_START = 0;
  reg [7:0]r_Next = 0;
  reg [7:0] r_TX_Byte;
  reg [7:0] r_RX_Byte;

  reg r_TX = 0;
  reg r_Rx = 0;
  reg r_Send = 0;
  reg r_Tx_DataVaild = 0;
  reg r_Reset = 1;
  reg r_CmdAccept = 1;

  reg [7:0] r_Halfbit_Cnt = 0;
  reg r_Halfbit_state;

  reg [3:0] r_RX_Bit_Count = 3'b111;
  reg [3:0] r_TX_Bit_Count = 4'b0;
 
  reg [7:0] r_StatusReg = 0;
  reg r_StatusRw;
  
  reg r_Lock = 0;
  
  reg [13:0] r_CMOS_value;
  
  reg r_RdyStart = 0;
      
  assign w_CPOL  = 0;
  assign w_CPHA  = 0;
  
//  assign f_Reset = r_StatusRw? i_StatusReg[0]:'b0;
//  assign f_RdySend = r_StatusRw? i_StatusReg[3]:'b0;
//  assign f_DataIn = r_StatusRw? i_StatusReg[1]:'b0;
//  assign f_RdyRece  = i_StatusReg[2];

    
//  clk_wiz_0 ck0(
//    .clk_out1(i_Clk),
//    .resetn(w_Rst),
//    .locked(),
//    .clk_in1(i_clk)
//  );

  task t_preChange;
  begin
    if (r_Halfbit_state == 1)
    begin
      r_Leading_Edge  <= 1;
      r_Trailing_Edge <= 0;
      if (!w_CPHA) r_Tx_DataVaild = 1;
    end
    else
    begin
      r_Trailing_Edge <= 1;
      r_Leading_Edge  <= 0;
      if (w_CPHA) r_Tx_DataVaild = 1;
    end
  end
  endtask

  task t_Change;
  begin
    r_Halfbit_Cnt = 0;
    r_SPI_Clk = r_Halfbit_state;
    if (r_TX_Bit_Count == 0 & r_SPI_Clk == w_CPOL)
    begin
      r_Tx_Cnt = r_Tx_Cnt + 1;
      if (r_Cmd_Cnt == r_Cmd_Lim - 1)
      begin
        t_reset();
        r_SPI_END = 21;  
      end
      else
      begin
        r_TX_Bit_Count = 4'b1000;
        r_TX_Byte = i_TX_Byte[r_Tx_Cnt];
        r_Cmd_Cnt = r_Cmd_Cnt + 1;
      end
    end
    r_Halfbit_state = ~r_Halfbit_state;
  end
  endtask
  
//  task t_nextStage;
//  begin
//    r_Phrase_Cnt = 0;
////    r_Tx_Cnt = 0;
////    r_TX_Byte_Cnt = 6;
//    i_TX_Change_Byte[2] = 'h80 | r_Stage;

//    if (r_Stage == 2)
//      r_Stage = 0;
//    else
//      r_Stage = r_Stage + 1;
    
//    t_reset();
////    r_SPI_Change = 1;
//    if (r_Change_LED) r_Change_LED = 0;
//    else r_Change_LED = 1;
//  end
//  endtask

//  task t_Rstbtn;
//  begin
//    r_Tx_Cnt = 0;
//    r_Next = 0;
//    r_Send = 1;
//    t_reset();
//  end
//  endtask

// Constructing Area
  task t_reset;
  begin
    r_TX_Bit_Count  = 4'b1000;
    r_SPI_START = 2;
    r_Tx_DataVaild = 0;
    r_SPI_Clk = w_CPOL;
    r_SPI_MOSI = 0;
    r_Halfbit_state = w_CPOL;
    r_TX = 0;
    r_Reset = 0;
    r_SPI_END = 0;
    r_Cmd_Cnt = 3'b0;
    r_Rx = 0;
//    r_Cmd_Lim = 3;
    r_StatusReg = i_StatusReg & 'h7E; //tbc
//    o_LED_Temp = 0;
    r_RX_Bit_Count = 3'b111;
  end
  endtask
  
  task t_ReadinTX;
  begin
    r_StatusReg = i_StatusReg;
    r_StatusRw = 0;
    i_TX_Byte[r_TX_Byte_Cnt] = i_TxBuffer;
    r_TX_Byte_Cnt = r_TX_Byte_Cnt + 1;
    r_StatusReg = i_StatusReg & 'h7D;        //Reset Data In bit
//    o_LED_Temp = r_TX_Byte_Cnt;
//    if (o_LED_Temp[7] == 'b0)
//        o_LED_Temp[7]= 1;
//    else if (o_LED_Temp[6] == 'b0)
//        o_LED_Temp[6] = 1;
//    else if (o_LED_Temp[5] == 'b0)
//        o_LED_Temp[5] = 1;
//    else if (o_LED_Temp[4] == 'b0)
//        o_LED_Temp[4] = 1;

//    r_StatusReg = 0;
    r_StatusRw = 1;
  end
  endtask

  always @(posedge i_Clk)
  begin
    r_Cmd_Lim = i_Cmd_Lim;
    if (i_StatusReg & `f_Reset)
    begin
      t_reset();          
      r_TX_Byte_Cnt = 'h0;
      r_Tx_Cnt = 'h0;
    end
    else if (r_CmdAccept)   //Not in SPI communicating
    begin
//      if (r_StatusRw == 0) r_StatusRw = 1;
      if (i_StatusReg & `f_Send)
      begin
        r_StatusReg = i_StatusReg;
        r_StatusRw = 0;
        r_CmdAccept = 0;
        r_Lock = 1;
        r_Send = 1;
//        o_LED_Temp = r_TX_Byte_Cnt;
      end
      else if (i_StatusReg & `f_Data)
      begin
        t_ReadinTX();
      end
//      else
//      begin
//        r_StatusReg = 'h00;
//        r_Lock = 0;
//      end
    end
    else if (r_Send)
    begin
      if (r_SPI_CS && r_SPI_START == 0) //start transmit
      begin
        t_reset();
        r_TX = 1;
        r_SPI_CS = 0;
        r_Send = 0;
//        r_SPI_Clk = 0;
        r_TX_Byte = i_TX_Byte[r_Tx_Cnt];
        r_StatusReg = i_StatusReg & 'hF7;
      end
      else if (r_SPI_CS && r_SPI_START > 0) //ready to start countdown
        r_SPI_START = r_SPI_START - 1;
    end
    else if (r_Tx_DataVaild) // transmit
    begin
      r_TX_Bit_Count = r_TX_Bit_Count -1;
      r_SPI_MOSI = r_TX_Byte[r_TX_Bit_Count];
      r_Tx_DataVaild = 0;
      if ((i_StatusReg & `f_Rece) && r_Cmd_Cnt == 2)
      begin
        r_RX_Byte[r_RX_Bit_Count] = i_SPI_MISO;
        r_RX_Bit_Count = r_RX_Bit_Count - 1;
      end
    end
    else if (!r_Next && !r_TX)
    begin
      if (r_SPI_END == 0) //End transmition
      begin
        r_SPI_CS = 1;
        r_Rx = 0;
        if (r_Tx_Cnt != r_TX_Byte_Cnt)
          r_Next = 21;
        else 
        begin
//          r_Second = 1;
          r_TX_Byte_Cnt = 8'b0;
          r_RX_Bit_Count = 3'b111;
          r_Tx_Cnt = 8'b0;
          r_StatusReg = r_StatusReg | 'h80;
          r_StatusReg = r_StatusReg & 'hF3;
          r_CmdAccept = 1;
          r_StatusRw = 1;
//          o_LED_Temp = r_TX_Byte_Cnt;
        end
      end
      else if (r_SPI_END > 0)  //Last byte to CS high countdown
        r_SPI_END = r_SPI_END - 1;
    end
    else if (r_SPI_CS)
    begin
      if (r_Next == 1) //Send next byte 
      begin
        r_Next = 0;
        r_Send = 1;
      end
      else if (r_Next > 0) //Ready to send next byte countdown
        r_Next = r_Next - 1;

    end
    //tbc
    
    if (r_TX)
    begin
      if (r_Halfbit_Cnt == CLKS_PER_HALF_BIT - 4)
      begin
        t_preChange();
        r_Halfbit_Cnt <= r_Halfbit_Cnt + 1;
      end
      else if (r_Halfbit_Cnt == CLKS_PER_HALF_BIT)
        t_Change();
      else 
        r_Halfbit_Cnt <= r_Halfbit_Cnt + 1;
    end
  end
  
  always @(posedge i_Clk)
  begin
    if (i_ADC_Trigger)
    begin
        r_RdyStart = 1;
        o_AXI_Init = 1;
    end
    else if (r_RdyStart)
    begin
        r_RdyStart = 0;
        o_AXI_Init = 0;
    end
  end
  
  always @(*)
  begin
    o_ADC_State = i_ADC_Done;
  end

//  always @(posedge i_CMOS_Clk)
//  begin
////    r_CMOS_value <= i_CMOS_Data;
//    if (r_CMOS_value >= 10000)
//        r_CMOS_value = 0;
//    else
//        r_CMOS_value <= r_CMOS_value + 1;
   
//    o_LED_Temp <= i_CMOS_Data & 'hFF;
    
//  end
  
// End of Constructing Aera
              
  always @(*)
  begin
     o_SPI_Clk = r_SPI_Clk;
     o_SPI_CS = r_SPI_CS;
     o_SPI_MOSI = r_SPI_MOSI;
     o_RxBuffer = r_RX_Byte;
     o_StatusRW = r_StatusRw;
     o_StatusReg = r_StatusReg;
     o_Tx_Cnt = r_TX_Byte_Cnt;
//     o_CMOS_Data = r_CMOS_value;
  end


  integer i;
  initial
  begin
//      r_TX = 0;
//      r_Reset = 1;
//      r_Tx_DataVaild = 0;
     r_Halfbit_state = w_CPOL;
//      r_Tx_LED = 0;
//      r_SPI_MOSI = 1'b0;
//      r_SPI_CS = 1;
      r_SPI_Clk = w_CPOL;
//      r_Send = 0;
//      r_Setup = 0;
//      r_Rx = 0;
      r_RX_Byte = 'hFF;
//      r_SPI_Change = 0;
//      r_Phrase_Cnt = 0;
//      r_Change_LED = 0;
//      r_Offset = 0;
//      r_TX_Byte_Cnt = 0;
//      o_Tx_LED = r_Tx_LED;
//      o_SPI_Clk = r_SPI_Clk;
//      o_SPI_CS = r_SPI_CS;
//      o_SPI_MOSI = r_SPI_MOSI;
       r_TX_Byte_Cnt = 0;
       r_CmdAccept = 1;
       r_StatusReg = 0;
//       r_StatusReg_Buf = 0;
       r_SPI_START = 2;
       r_TX_Byte = 0;
       r_StatusRw = 1;
       o_StatusRW = r_StatusRw;
       r_Lock = 0;
       r_CMOS_value = 0;
       r_RdyStart = 0;
       for (i = 0;i< 41;i=i+1)
        i_TX_Byte[i] = 0;    
  end
  
endmodule