`timescale 1ns/1ps

module BRAM_Gen
       #(
           parameter integer ADDWIDTH =8,
           parameter integer DATAWIDTH =16,
           localparam BYTES  = DATAWIDTH/8,
           localparam DEPTH  = (1<<ADDWIDTH)
       ) (
           input  wire               clk0,
           input  wire [ADDWIDTH-1:0]  address0i,
           input  wire [ADDWIDTH-1:0]  address0o,
           input  wire               we0,
           //           input  wire [BYTES-1:0]   be0,
           input  wire [DATAWIDTH-1:0] d0,
           output reg  [DATAWIDTH-1:0] q0,
           input  wire               clk1,
           input  wire [ADDWIDTH-1:0]  address1i,
           input  wire [ADDWIDTH-1:0]  address1o,
           input  wire               we1,
           input  wire [BYTES-1:0]   be1,
           input  wire [DATAWIDTH-1:0] d1,
           output reg  [DATAWIDTH-1:0] q1
       );
//------------------------Local signal-------------------
reg  [DATAWIDTH-1:0] mem [0:DEPTH-1];
reg [DATAWIDTH-1:0] dataInReg;

reg [5:0] i,j;


always@( posedge clk1 or posedge clk0) begin
    if(we1==1'b1)
        for(i=0;i<BYTES;i=i+1) begin:WriteMem
            if(be1[i+:0]==1'b1)
                mem[address1i] [i*8+7 -: 8]<=d1[(i*8+7) -: 8];
        end
    else if(we0==1'b1) begin
        for(i=0;i<BYTES;i=i+1) begin:WriteMem
            if(be1[i+:0]==1'b1)
                mem[address1i] [i*8+7 -: 8]<=d1[(i*8+7) -: 8];
        end
    end
end


always@(posedge clk1) begin
    q1<=mem[address1o];
end
always@(posedge clk0) begin
    q0<=mem[address0o];
end

endmodule
