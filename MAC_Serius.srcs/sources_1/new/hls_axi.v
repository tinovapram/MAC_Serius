// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.1 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
`timescale 1ns/1ps
module test_AXILiteS_s_axi
       #(parameter
         C_S_AXI_ADDR_WIDTH = 13,
         C_S_AXI_DATA_WIDTH = 32
        )(
           input  wire                          ACLK,
           input  wire                          ARESET,
           input  wire                          ACLK_EN,
           input  wire [C_S_AXI_ADDR_WIDTH-1:0] AWADDR,
           input  wire                          AWVALID,
           output wire                          AWREADY,
           input  wire [C_S_AXI_DATA_WIDTH-1:0] WDATA,
           input  wire [C_S_AXI_DATA_WIDTH/8-1:0] WSTRB,
           input  wire                          WVALID,
           output wire                          WREADY,
           output wire [1:0]                    BRESP,
           output wire                          BVALID,
           input  wire                          BREADY,
           input  wire [C_S_AXI_ADDR_WIDTH-1:0] ARADDR,
           input  wire                          ARVALID,
           output wire                          ARREADY,
           output wire [C_S_AXI_DATA_WIDTH-1:0] RDATA,
           output wire [1:0]                    RRESP,
           output wire                          RVALID,
           input  wire                          RREADY,
           input  wire [8:0]                    txReg_address0,
           input  wire                          txReg_ce0,
           input  wire                          txReg_we0,
           input  wire [31:0]                   txReg_d0,
           output wire [31:0]                   txReg_q0,
           input  wire [8:0]                    rxReg_address0,
           input  wire                          rxReg_ce0,
           input  wire                          rxReg_we0,
           input  wire [31:0]                   rxReg_d0,
           output wire [31:0]                   rxReg_q0
       );
//------------------------Address Info-------------------
// 0x0800 ~
// 0x0fff : Memory 'txReg' (512 * 32b)
//          Word n : bit [31:0] - txReg[n]
// 0x1000 ~
// 0x17ff : Memory 'rxReg' (512 * 32b)
//          Word n : bit [31:0] - rxReg[n]
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

//------------------------Parameter----------------------
localparam
    ADDR_TXREG_BASE = 13'h0000,
    ADDR_TXREG_HIGH = 13'h07ff,
    ADDR_RXREG_BASE = 13'h0800,
    ADDR_RXREG_HIGH = 13'h0fff,
    WRIDLE          = 2'd0,
    WRDATA          = 2'd1,
    WRRESP          = 2'd2,
    WRRESET         = 2'd3,
    RDIDLE          = 2'd0,
    RDDATA          = 2'd1,
    RDRESET         = 2'd2,
    ADDR_BITS         = 13;

//------------------------Local signal-------------------
reg  [1:0]                    wstate = WRRESET;
reg  [1:0]                    wnext;
reg  [ADDR_BITS-1:0]          waddr;
wire [31:0]                   wmask;
wire                          aw_hs;
wire                          w_hs;
reg  [1:0]                    rstate = RDRESET;
reg  [1:0]                    rnext;
reg  [31:0]                   rdata;
wire                          ar_hs;
wire [ADDR_BITS-1:0]          raddr;
// memory signals
wire [8:0]                    int_txReg_address0;
wire                          int_txReg_ce0;
wire                          int_txReg_we0;
wire [3:0]                    int_txReg_be0;
wire [31:0]                   int_txReg_d0;
wire [31:0]                   int_txReg_q0;
wire [8:0]                    int_txReg_address1;
wire                          int_txReg_ce1;
wire                          int_txReg_we1;
wire [3:0]                    int_txReg_be1;
wire [31:0]                   int_txReg_d1;
wire [31:0]                   int_txReg_q1;
reg                           int_txReg_read;
reg                           int_txReg_write;
wire [8:0]                    int_rxReg_address0;
wire                          int_rxReg_ce0;
wire                          int_rxReg_we0;
wire [3:0]                    int_rxReg_be0;
wire [31:0]                   int_rxReg_d0;
wire [31:0]                   int_rxReg_q0;
wire [8:0]                    int_rxReg_address1;
wire                          int_rxReg_ce1;
wire                          int_rxReg_we1;
wire [3:0]                    int_rxReg_be1;
wire [31:0]                   int_rxReg_d1;
wire [31:0]                   int_rxReg_q1;
reg                           int_rxReg_read;
reg                           int_rxReg_write;

//------------------------Instantiation------------------
// int_txReg
test_AXILiteS_s_axi_ram #(
                            .BYTES    ( 4 ),
                            .DEPTH    ( 512 )
                        ) int_txReg (
                            .clk0     ( ACLK ),
                            .address0 ( int_txReg_address0 ),
                            .ce0      ( int_txReg_ce0 ),
                            .we0      ( int_txReg_we0 ),
                            .be0      ( int_txReg_be0 ),
                            .d0       ( int_txReg_d0 ),
                            .q0       ( int_txReg_q0 ),
                            .clk1     ( ACLK ),
                            .address1 ( int_txReg_address1 ),
                            .ce1      ( int_txReg_ce1 ),
                            .we1      ( int_txReg_we1 ),
                            .be1      ( int_txReg_be1 ),
                            .d1       ( int_txReg_d1 ),
                            .q1       ( int_txReg_q1 )
                        );
// int_rxReg
test_AXILiteS_s_axi_ram #(
                            .BYTES    ( 4 ),
                            .DEPTH    ( 512 )
                        ) int_rxReg (
                            .clk0     ( ACLK ),
                            .address0 ( int_rxReg_address0 ),
                            .ce0      ( int_rxReg_ce0 ),
                            .we0      ( int_rxReg_we0 ),
                            .be0      ( int_rxReg_be0 ),
                            .d0       ( int_rxReg_d0 ),
                            .q0       ( int_rxReg_q0 ),
                            .clk1     ( ACLK ),
                            .address1 ( int_rxReg_address1 ),
                            .ce1      ( int_rxReg_ce1 ),
                            .we1      ( int_rxReg_we1 ),
                            .be1      ( int_rxReg_be1 ),
                            .d1       ( int_rxReg_d1 ),
                            .q1       ( int_rxReg_q1 )
                        );

//------------------------AXI write fsm------------------
assign AWREADY = (wstate == WRIDLE);
assign WREADY  = (wstate == WRDATA);
assign BRESP   = 2'b00;  // OKAY
assign BVALID  = (wstate == WRRESP);
assign wmask   = { {8{WSTRB[3]}}, {8{WSTRB[2]}}, {8{WSTRB[1]}}, {8{WSTRB[0]}} };
assign aw_hs   = AWVALID & AWREADY;
assign w_hs    = WVALID & WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRRESET;
    else if (ACLK_EN)
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (aw_hs)
            waddr <= AWADDR[ADDR_BITS-1:0];
    end
end

//------------------------AXI read fsm-------------------
assign ARREADY = (rstate == RDIDLE);
assign RDATA   = rdata;
assign RRESP   = 2'b00;  // OKAY
assign RVALID  = (rstate == RDDATA) & !int_txReg_read & !int_rxReg_read;
assign ar_hs   = ARVALID & ARREADY;
assign raddr   = ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDRESET;
    else if (ACLK_EN)
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (RREADY & RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

// rdata
always @(posedge ACLK) begin
    if (ACLK_EN) begin
        if (ar_hs) begin
            rdata <= 1'b0;
        end
        else if (int_txReg_read) begin
            rdata <= int_txReg_q1;
        end
        else if (int_rxReg_read) begin
            rdata <= int_rxReg_q1;
        end
    end
end


//------------------------Register logic-----------------

//------------------------Memory logic-------------------
// txReg
assign int_txReg_address0 = txReg_address0;
assign int_txReg_ce0      = txReg_ce0;
assign int_txReg_we0      = txReg_we0;
assign int_txReg_be0      = {4{txReg_we0}};
assign int_txReg_d0       = txReg_d0;
assign txReg_q0           = int_txReg_q0;
assign int_txReg_address1 = ar_hs? raddr[10:2] : waddr[10:2];
assign int_txReg_ce1      = ar_hs | (int_txReg_write & WVALID);
assign int_txReg_we1      = int_txReg_write & WVALID;
assign int_txReg_be1      = WSTRB;
assign int_txReg_d1       = WDATA;
// rxReg
assign int_rxReg_address0 = rxReg_address0;
assign int_rxReg_ce0      = rxReg_ce0;
assign int_rxReg_we0      = rxReg_we0;
assign int_rxReg_be0      = {4{rxReg_we0}};
assign int_rxReg_d0       = rxReg_d0;
assign rxReg_q0           = int_rxReg_q0;
assign int_rxReg_address1 = ar_hs? raddr[10:2] : waddr[10:2];
assign int_rxReg_ce1      = ar_hs | (int_rxReg_write & WVALID);
assign int_rxReg_we1      = int_rxReg_write & WVALID;
assign int_rxReg_be1      = WSTRB;
assign int_rxReg_d1       = WDATA;
// int_txReg_read
always @(posedge ACLK) begin
    if (ARESET)
        int_txReg_read <= 1'b0;
    else if (ACLK_EN) begin
        if (ar_hs && raddr >= ADDR_TXREG_BASE && raddr <= ADDR_TXREG_HIGH)
            int_txReg_read <= 1'b1;
        else
            int_txReg_read <= 1'b0;
    end
end

// int_txReg_write
always @(posedge ACLK) begin
    if (ARESET)
        int_txReg_write <= 1'b0;
    else if (ACLK_EN) begin
        if (aw_hs && AWADDR[ADDR_BITS-1:0] >= ADDR_TXREG_BASE && AWADDR[ADDR_BITS-1:0] <= ADDR_TXREG_HIGH)
            int_txReg_write <= 1'b1;
        else if (WVALID)
            int_txReg_write <= 1'b0;
    end
end

// int_rxReg_read
always @(posedge ACLK) begin
    if (ARESET)
        int_rxReg_read <= 1'b0;
    else if (ACLK_EN) begin
        if (ar_hs && raddr >= ADDR_RXREG_BASE && raddr <= ADDR_RXREG_HIGH)
            int_rxReg_read <= 1'b1;
        else
            int_rxReg_read <= 1'b0;
    end
end

// int_rxReg_write
always @(posedge ACLK) begin
    if (ARESET)
        int_rxReg_write <= 1'b0;
    else if (ACLK_EN) begin
        if (aw_hs && AWADDR[ADDR_BITS-1:0] >= ADDR_RXREG_BASE && AWADDR[ADDR_BITS-1:0] <= ADDR_RXREG_HIGH)
            int_rxReg_write <= 1'b1;
        else if (WVALID)
            int_rxReg_write <= 1'b0;
    end
end


endmodule


`timescale 1ns/1ps

    module test_AXILiteS_s_axi_ram
    #(parameter
      BYTES  = 4,
      DEPTH  = 256,
      AWIDTH = log2(DEPTH)
     ) (
        input  wire               clk0,
        input  wire [AWIDTH-1:0]  address0,
        input  wire               ce0,
        input  wire               we0,
        input  wire [BYTES-1:0]   be0,
        input  wire [BYTES*8-1:0] d0,
        output reg  [BYTES*8-1:0] q0,
        input  wire               clk1,
        input  wire [AWIDTH-1:0]  address1,
        input  wire               ce1,
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
always @(posedge clk0) begin
    if (ce0)
        q0 <= mem[address0];
end

// read port 1
always @(posedge clk1) begin
    if (ce1)
        q1 <= mem[address1];
end

genvar i;
generate
    for (i = 0; i < BYTES; i = i + 1) begin : gen_write
        // write port 0
        always @(posedge clk0) begin
            if (ce0 & we0 & be0[i]) begin
                mem[address0][8*i+7:8*i] <= d0[8*i+7:8*i];
            end
        end
        // write port 1
        always @(posedge clk1) begin
            if (ce1 & we1 & be1[i]) begin
                mem[address1][8*i+7:8*i] <= d1[8*i+7:8*i];
            end
        end
    end
    endgenerate

        endmodule
