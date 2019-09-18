`default_nettype none

`timescale 1 ns / 1 ps

module	MAC_PalingSerius
       #(
           // Users to add parameters here
           parameter [0:0] OPT_READ_SIDEEFFECTS = 1,
           // User parameters ends
           // Do not modify the parameters beyond this line
           // Width of S_AXI data bus
           parameter integer C_S_AXI_DATA_WIDTH	= 32,
           // Width of S_AXI address bus
           parameter integer C_S_AXI_ADDR_WIDTH	= 12
       ) (
           // Users to add ports here
           // No user ports (yet) in this design
           // User ports ends
           output wire [7:0] txData,
           output wire txClock,
           input wire [7:0] rxData,
           input wire rxClock,
           // Do not modify the ports beyond this line
           // Global Clock Signal
           input wire  S_AXI_ACLK,
           // Global Reset Signal. This Signal is Active LOW
           input wire  S_AXI_ARESETN,
           // Write address (issued by master, acceped by Slave)
           input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
           // Write channel Protection type. This signal indicates the
           // privilege and security level of the transaction, and whether
           // the transaction is a data access or an instruction access.
           input wire [2 : 0] S_AXI_AWPROT,
           // Write address valid. This signal indicates that the master
           // signaling valid write address and control information.
           input wire  S_AXI_AWVALID,
           // Write address ready. This signal indicates that the slave
           // is ready to accept an address and associated control signals.
           output wire  S_AXI_AWREADY,
           // Write data (issued by master, acceped by Slave)
           input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
           // Write strobes. This signal indicates which byte lanes hold
           // valid data. There is one write strobe bit for each eight
           // bits of the write data bus.
           input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
           // Write valid. This signal indicates that valid write
           // data and strobes are available.
           input wire  S_AXI_WVALID,
           // Write ready. This signal indicates that the slave
           // can accept the write data.
           output wire  S_AXI_WREADY,
           // Write response. This signal indicates the status
           // of the write transaction.
           output wire [1 : 0] S_AXI_BRESP,
           // Write response valid. This signal indicates that the channel
           // is signaling a valid write response.
           output wire  S_AXI_BVALID,
           // Response ready. This signal indicates that the master
           // can accept a write response.
           input wire  S_AXI_BREADY,
           // Read address (issued by master, acceped by Slave)
           input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
           // Protection type. This signal indicates the privilege
           // and security level of the transaction, and whether the
           // transaction is a data access or an instruction access.
           input wire [2 : 0] S_AXI_ARPROT,
           // Read address valid. This signal indicates that the channel
           // is signaling valid read address and control information.
           input wire  S_AXI_ARVALID,
           // Read address ready. This signal indicates that the slave is
           // ready to accept an address and associated control signals.
           output wire  S_AXI_ARREADY,
           // Read data (issued by slave)
           output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
           // Read response. This signal indicates the status of the
           // read transfer.
           output wire [1 : 0] S_AXI_RRESP,
           // Read valid. This signal indicates that the channel is
           // signaling the required read data.
           output wire  S_AXI_RVALID,
           // Read ready. This signal indicates that the master can
           // accept the read data and response information.
           input wire  S_AXI_RREADY
       );

// AXI4LITE signals
reg		axi_awready;
reg		axi_wready;
reg		axi_bvalid;
reg		axi_arready;
reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
reg		axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = 2;
localparam integer AW = C_S_AXI_ADDR_WIDTH-2;
localparam integer DW = C_S_AXI_DATA_WIDTH;
localparam integer MW = 2**AW;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
reg [DW-1:0]	slv_mem	[0:MW-1];

initial begin
    slv_mem[510]<=32'd400;
end

// I/O Connections assignments

assign S_AXI_AWREADY	= axi_awready;
assign S_AXI_WREADY	= axi_wready;
assign S_AXI_BRESP	= 2'b00; // The OKAY response
assign S_AXI_BVALID	= axi_bvalid;
assign S_AXI_ARREADY	= axi_arready;
assign S_AXI_RDATA	= axi_rdata;
assign S_AXI_RRESP	= 2'b00; // The OKAY response
assign S_AXI_RVALID	= axi_rvalid;
// Implement axi_*wready generation

//////////////////////////////////////
//
// Read processing
//
//
wire	valid_read_request,
     read_response_stall;

assign	valid_read_request  =  S_AXI_ARVALID || !S_AXI_ARREADY;
assign	read_response_stall =  S_AXI_RVALID  && !S_AXI_RREADY;

//
// The read response channel valid signal
//
initial
    axi_rvalid = 1'b0;
always @( posedge S_AXI_ACLK )
    if (!S_AXI_ARESETN)
        axi_rvalid <= 0;
    else if (read_response_stall)
        // Need to stay valid as long as the return path is stalled
        axi_rvalid <= 1'b1;
    else if (valid_read_request)
        axi_rvalid <= 1'b1;
    else
        // Any stall has cleared, so we can always
        // clear the valid signal in this case
        axi_rvalid <= 1'b0;

reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	pre_raddr, rd_addr;

// Buffer the address
always @(posedge S_AXI_ACLK)
    if (S_AXI_ARREADY)
        pre_raddr <= S_AXI_ARADDR;

always @(*)
    if (!axi_arready)
        rd_addr = pre_raddr;
    else
        rd_addr = S_AXI_ARADDR;

//
// Read the data
//
always @(posedge S_AXI_ACLK)
    if (!read_response_stall
            &&(!OPT_READ_SIDEEFFECTS || valid_read_request))
        // If the outgoing channel is not stalled (above)
        // then read
        axi_rdata <= slv_mem[rd_addr[AW+ADDR_LSB-1:ADDR_LSB]];

//
// The read address channel ready signal
//
initial
    axi_arready = 1'b0;
always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_arready <= 1'b1;
    else if (read_response_stall) begin
        // Outgoing channel is stalled
        //    As long as something is already in the buffer,
        //    axi_arready needs to stay low
        axi_arready <= !valid_read_request;
    end
    else
        axi_arready <= 1'b1;

//////////////////////////////////////
//
// Write processing
//
//
reg [C_S_AXI_ADDR_WIDTH-1 : 0]		pre_waddr, waddr;
reg [C_S_AXI_DATA_WIDTH-1 : 0]		pre_wdata, wdata;
reg [(C_S_AXI_DATA_WIDTH/8)-1 : 0]	pre_wstrb, wstrb;

wire	valid_write_address, valid_write_data,
     write_response_stall;

assign	valid_write_address = S_AXI_AWVALID || !axi_awready;
assign	valid_write_data    = S_AXI_WVALID  || !axi_wready;
assign	write_response_stall= S_AXI_BVALID  && !S_AXI_BREADY;

//
// The write address channel ready signal
//
initial
    axi_awready = 1'b1;
always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_awready <= 1'b1;
    else if (write_response_stall) begin
        // The output channel is stalled
        //	If our buffer is full, we need to remain stalled
        //	Likewise if it is empty, and there's a request,
        //	  we'll need to stall.
        axi_awready <= !valid_write_address;
    end
    else if (valid_write_data)
        // The output channel is clear, and write data
        // are available
        axi_awready <= 1'b1;
    else
        // If we were ready before, then remain ready unless an
        // address unaccompanied by data shows up
        axi_awready <= ((axi_awready)&&(!S_AXI_AWVALID));
// This is equivalent to
// axi_awready <= !valid_write_address

//
// The write data channel ready signal
//
initial
    axi_wready = 1'b1;
always @(posedge S_AXI_ACLK)
    if (!S_AXI_ARESETN)
        axi_wready <= 1'b1;
    else if (write_response_stall)
        // The output channel is stalled
        //	We can remain ready until valid
        //	write data shows up
        axi_wready <= !valid_write_data;
    else if (valid_write_address)
        // The output channel is clear, and a write address
        // is available
        axi_wready <= 1'b1;
    else
        // if we were ready before, and there's no new data avaialble
        // to cause us to stall, remain ready
        axi_wready <= (axi_wready)&&(!S_AXI_WVALID);
// This is equivalent to
// axi_wready <= !valid_write_data


// Buffer the address
always @(posedge S_AXI_ACLK)
    if (S_AXI_AWREADY)
        pre_waddr <= S_AXI_AWADDR;

// Buffer the data
always @(posedge S_AXI_ACLK)
    if (S_AXI_WREADY) begin
        pre_wdata <= S_AXI_WDATA;
        pre_wstrb <= S_AXI_WSTRB;
    end

always @(*)
    if (!axi_awready)
        // Read the write address from our "buffer"
        waddr = pre_waddr;
    else
        waddr = S_AXI_AWADDR;

always @(*)
    if (!axi_wready) begin
        // Read the write data from our "buffer"
        wstrb = pre_wstrb;
        wdata = pre_wdata;
    end
    else begin
        wstrb = S_AXI_WSTRB;
        wdata = S_AXI_WDATA;
    end

reg [31:0] txBuff[0:399];
reg [31:0] rxBuff[0:399];
reg [31:0] txControl,rxControl;

//
// Actually (finally) write the data
//
wire readyWrite;
integer iw=0;
assign readyWrite = !write_response_stall
       // If we have a valid address, and
       && valid_write_address
       // If we have valid data
       && valid_write_data;
always @( posedge S_AXI_ACLK )
    // If the output channel isn't stalled, and
    if (readyWrite) begin
        if (wstrb[0])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][7:0]
                   <= wdata[7:0];
        if (wstrb[1])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][15:8]
                   <= wdata[15:8];
        if (wstrb[2])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][23:16]
                   <= wdata[23:16];
        if (wstrb[3])
            slv_mem[waddr[AW+ADDR_LSB-1:ADDR_LSB]][31:24]
                   <= wdata[31:24];
    end
    else     if (!readyWrite) begin
        for(iw=0;iw<400;iw=iw+1) begin
            slv_mem[512+iw]<=rxBuff[iw];
        end
        slv_mem[511]<=txControl;
        slv_mem[1023]<=rxControl;
    end

//    genvar jo;
//    generate
//    for (jo=0;jo<399;jo=jo+1)begin
//        always @( posedge S_AXI_ACLK )
//        if (!readyWrite)
//            slv_mem[512+jo]<=rxBuff[jo];
//        end
//    endgenerate


//
// The write response channel valid signal
//
initial
    axi_bvalid = 1'b0;
always @( posedge S_AXI_ACLK )
    if (!S_AXI_ARESETN)
        axi_bvalid <= 1'b0;
//
// The outgoing response channel should indicate a valid write if ...
// 1. We have a valid address, and
    else if (valid_write_address
             // 2. We had valid data
             && valid_write_data)
        // It doesn't matter here if we are stalled or not
        // We can keep setting ready as often as we want
        axi_bvalid <= 1'b1;
    else if (S_AXI_BREADY)
        // Otherwise, if BREADY was true, then it was just accepted
        // and can return to idle now
        axi_bvalid <= 1'b0;

// Make Verilator happy
// Verilator lint_off UNUSED
wire	[4*ADDR_LSB+5:0]	unused;
assign	unused = { S_AXI_AWPROT, S_AXI_ARPROT,
                  S_AXI_AWADDR[ADDR_LSB-1:0],
                  rd_addr[ADDR_LSB-1:0],
                  waddr[ADDR_LSB-1:0],
                  S_AXI_ARADDR[ADDR_LSB-1:0] };
// Verilator lint_on UNUSED



reg [15:0]txLenght=400, rxLenght=0;
reg [2:0] txState,rxState;

localparam idle =3'd0;
localparam start =3'd1;
localparam crc =3'd2;
localparam transfer=3'd3;
localparam finish =3'd7;

integer txi=0;

reg [7:0] txCRCIn=0,rxCRCIn=0;
wire [15:0] txCRCout=0,rxCRCout=0;
wire CRCclock;
reg txCRCreset=0,rxCRCreset=0;

reg [15:0] txCRCi=0,rxCRCi=0;
reg [15:0] txCRCresult,rxCRCresult;

reg [11:0] i;

reg [7:0] txDataReg;

localparam txHL=11'd4;

//urusan assign txBuff;
always @( posedge S_AXI_ACLK ) begin //block A
    if (!S_AXI_ARESETN) begin
        txi<=0;
        txCRCreset<=1'b0;
        txState<=idle;
    end
    else begin
        case(txState)
            idle: begin
                if(slv_mem[511][0]==1'b1) begin
                    txLenght<=slv_mem[510][15:0]; //Panjang data di register 510 MSB 16 bit
                    txState<=start;
                    txControl<=slv_mem[511];
                end
            end
            start: begin
                for(i=1;i<1540;i=i+4) begin
                    txBuff[i+txHL]<=slv_mem[i/4][31-((i%4)*8)-:8];
                end
                txBuff[txHL-2]<=txLenght[15:8];
                txBuff[txHL-1]<=txLenght[7:0];
                txLenght<=txLenght+4;
                txCRCreset<=1'b1;
                txCRCIn<=txBuff[0];
                txCRCi<=1;
                txState<=crc;
            end
            crc: begin
                if(txCRCi<txLenght) begin
                    txCRCi<=txCRCi+1;
                    txCRCIn<=txBuff[txCRCi];
                end
                else begin
                    txCRCresult<=txCRCout;
                    txCRCreset<=1'b0;
                end
            end
            transfer: begin
                
            end
            finish: begin
                txControl[0]<=0;
            end
            default:
                txState<=0;
        endcase

    end
end

always @( posedge S_AXI_ACLK ) begin
    if (!S_AXI_ARESETN) begin
        txi<=0;
        txCRCreset<=1'b0;
        txState<=idle;
    end
end

crc16 txCRC(
          .dataIn(txCRCIn),
          .crcOut(txCRCout),
          .clock(CRCclock),
          .reset(txCRCreset)
      );

crc16 rxCRC(
          .dataIn(rxCRCIn),
          .crcOut(rxCRCout),
          .clock(CRCclock),
          .reset(rxCRCreset)
      );
endmodule
