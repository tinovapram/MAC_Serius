`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2019 01:00:13 PM
// Design Name: 
// Module Name: crc16
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
`default_nettype wire

module crc16(
    input [7:0] dataIn,
    output [15:0] crcOut,
    input clock,
    input reset
    );
    
    reg [15:0] crcTable [0:255]         ;
    reg [15:0] crcOutReg=16'h0000;
    
    wire [7:0] memAdd;
    assign memAdd=crcOutReg[15:8]^dataIn;
    wire [15:0] memData;
    
    initial begin
    $readmemh("./crc_tab.mem", crcTable);
    end        
    
    always@(posedge clock) begin
        if(reset==0) begin
            crcOutReg<=0;
        end
        else begin
            crcOutReg<={crcOutReg[7:0],8'h00}^crcTable[memAdd];            
        end        
    end
    assign crcOut=crcOutReg;    
    
endmodule
