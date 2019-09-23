`timescale 1ns/1ps

module BRAM_Gen
       #(parameter
         BYTES  = 4,
         DEPTH  = 512,
         AWIDTH = log2(DEPTH)
        ) (
           input  wire               clk0,
           input  wire [AWIDTH-1:0]  address0i,
           input  wire [AWIDTH-1:0]  address0o,
           input  wire               ce0,
           input  wire               we0,
           input  wire               oe0,
           input  wire [BYTES-1:0]   be0,
           input  wire [BYTES*8-1:0] d0,
           output reg  [BYTES*8-1:0] q0,
           input  wire               clk1,
           input  wire [AWIDTH-1:0]  address1i,
           input  wire [AWIDTH-1:0]  address1o,
           input  wire               ce1,
           input  wire               oe1,
           input  wire               we1,
           input  wire [BYTES-1:0]   be1,
           input  wire [BYTES*8-1:0] d1,
           output reg  [BYTES*8-1:0] q1
       );
//------------------------Local signal-------------------
reg  [BYTES*8-1:0] mem[0:DEPTH-1];
//------------------------Task and function--------------
function integer log2;
    input integer x;
    integer n, m;
    begin
        n = 1;
        m = 2;
        while (m < x) begin
            n = n + 1;
            m = m * 2;
        end
        log2 = n;
    end
endfunction
//------------------------Body---------------------------
// read port 0
wire [AWIDTH-1:0] addBuff0;
reg [AWIDTH-1:0] nextAdd0;
wire [BYTES*8-1:0] dataBuff0;
reg [BYTES*8-1:0] nextData0;
reg nextEn0=0;
assign dataBuff0= we0 ? d0 : nextEn0 ? nextData0 : d0;
wire [AWIDTH-1:0] currAdd0;
assign currAdd0= oe0 ? address0o : we0 ? address0i : nextEn0 ? nextAdd0 : address0i;

reg [3:0] x;
always @(posedge clk0) begin
    if (ce0 ) begin
        if(oe0) begin
            q0 <= mem[currAdd0];
            if(we0) begin
                nextAdd0<=address0i;
                nextEn0<=1'b1;
                nextData0<=d0;
            end
        end
        else if(we0||nextEn0) begin
            for(x=0;x<BYTES;x=x+1) begin
                if(be0[x]==1'b1) begin
                    mem[currAdd0][x*8+:8] <= dataBuff0[x*8+:8];
                end
            end
            if (nextEn0==1'b1 && we0 ==1'b0) begin
                nextEn0<=1'b0;
            end
        end
    end
end

// read port 1
wire [AWIDTH-1:0] addBuff1;
reg [AWIDTH-1:0] nextAdd1;
wire [BYTES*8-1:0] dataBuff1;
reg [BYTES*8-1:0] nextData1;
reg nextEn1=0;
assign dataBuff1= we1 ? d1 : nextEn1 ? nextData1 : d1;
wire [AWIDTH-1:0] currAdd1;
assign currAdd1= oe1 ? address1o : we1 ? address1i : nextEn1 ? nextAdd1 : address1i;

reg [3:0] y;
always @(posedge clk0) begin
    if (ce1 ) begin
        if(oe1) begin
            q1 <= mem[currAdd1];
            if(we1) begin
                nextAdd1<=address1i;
                nextEn1<=1'b1;
                nextData1<=d1;
            end
        end
        else if(we1||nextEn1) begin
            for(y=0;y<BYTES;y=y+1) begin
                if(be1[y]==1'b1) begin
                    mem[currAdd1][y*8+:8] <= dataBuff1[y*8+:8];
                end
            end
            if (nextEn1==1'b1 && we1 ==1'b0) begin
                nextEn1<=1'b0;
            end
        end
    end
end

endmodule
