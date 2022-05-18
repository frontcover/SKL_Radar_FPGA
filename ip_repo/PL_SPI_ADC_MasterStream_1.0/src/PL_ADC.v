`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/25/2022 01:59:13 PM
// Design Name: 
// Module Name: PL_ADC
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


module PL_ADC(
        input wire i_CMOS_Clk,
        input wire [11:0] i_CMOS_Data,
        output reg [11:0] o_CMOS_Data,
        input wire i_ADC_Work,
        output reg o_ADC_Done,
        output reg o_ADC_Last,
        input wire [31:0] i_Count
    );
    
    reg r_Work = 0;
    reg [19:0] r_Count = 0;
    reg r_Done = 0;
    reg [11:0] r_output = 0;
    reg reset = 0;
    
always @(posedge i_CMOS_Clk)
begin
    if (!i_ADC_Work & r_Done)
    begin
        r_Done = 0;
    end
    if (i_ADC_Work & !r_Done)
    begin
        r_Done = 0;
        r_Work = 1;
//        o_CMOS_Data = i_CMOS_Data;
    end
    
    
    if (r_Work)
    begin
//        r_output = i_CMOS_Data;
//        r_output = 'h929;
        r_output <= r_Count;
//        if (r_Count >= 4096) r_output = r_output >> 12;
        r_Count = r_Count + 1;
        if (r_Count == i_Count - 1)
            o_ADC_Last <= 1;
        else
            o_ADC_Last <= 0;
        if (r_Count >= i_Count)
        begin
            r_Done = 1;
            r_Work = 0;
            r_Count <= 0;
        end
    end
//    else if (r_Work)
//    begin
//        o_ADC_Done = 1;
//        r_Work = 0;
//    end
    
end

always @(*) 
begin
    o_ADC_Done <= r_Done;
    o_CMOS_Data <= r_output;
end

initial
begin
    r_Work = 0;
    r_Count = 0;
    r_output = 'h0;
end

endmodule