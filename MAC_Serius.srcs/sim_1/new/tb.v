module testbench#(
           parameter ADD_WIDTH=12, DATA_WIDTH=32
       );

//clock and reset_n signals
reg aclk =1'b0;
wire aclock;
assign aclock=aclk;
reg arstn = 1'b0;


//Write Address channel (AW)
reg [ADD_WIDTH-1:0] write_addr =32'd0;	//Master write address
reg [2:0] write_prot = 3'd0;	//type of write(leave at 0)
reg write_addr_valid = 1'b0;	//master indicating address is valid
wire write_addr_ready;		//slave ready to receive address

//Write Data Channel (W)
reg [DATA_WIDTH-1:0] write_data = 32'd0;	//Master write data
reg [3:0] write_strb = 4'd0;	//Master byte-wise write strobe
reg write_data_valid = 1'b0;	//Master indicating write data is valid
wire write_data_ready;		//slave ready to receive data

//Write Response Channel (WR)
reg write_resp_ready = 1'b0;	//Master ready to receive write response
wire [1:0] write_resp;		//slave write response
wire write_resp_valid;		//slave response valid

//Read Address channel (AR)
reg [ADD_WIDTH-1:0] read_addr = 32'd0;	//Master read address
reg [2:0] read_prot =3'd0;	//type of read(leave at 0)
reg read_addr_valid = 1'b0;	//Master indicating address is valid
wire read_addr_ready;		//slave ready to receive address

//Read Data Channel (R)
reg read_data_ready = 1'b0;	//Master indicating ready to receive data
wire [DATA_WIDTH-1:0] read_data;		//slave read data
wire [1:0] read_resp;		//slave read response
wire read_data_valid;		//slave indicating data in channel is valid

//
wire [7:0] txData;
reg txClock;
reg [7:0] rxData;
reg rxClock;

MAC_PalingSerius#(

                ) UUT
                (
                    .txData(txData),
                . txClock(txClock),
                . rxData(rxData),
                . rxClock(rxClock),
                    .S_AXI_ACLK(aclk),
                    .S_AXI_ARESETN(arstn),
                    .S_AXI_AWADDR(write_addr),
                    .S_AXI_AWPROT(write_prot),
                    .S_AXI_AWVALID(write_addr_valid),
                    .S_AXI_AWREADY(write_addr_ready),
                    .S_AXI_WDATA(write_data),
                    .S_AXI_WSTRB(write_strb),
                    .S_AXI_WVALID(write_data_valid),
                    .S_AXI_WREADY(write_data_ready),

                    .S_AXI_BRESP(write_resp),
                    .S_AXI_BVALID(write_resp_valid),
                    .S_AXI_BREADY(write_resp_ready),

                    .S_AXI_ARADDR(read_addr),
                    .S_AXI_ARPROT(read_prot),
                    .S_AXI_ARVALID(read_addr_valid),
                    .S_AXI_ARREADY(read_addr_ready),

                    .S_AXI_RDATA(read_data),
                    .S_AXI_RRESP(read_resp),
                    .S_AXI_RVALID(read_data_valid),
                    .S_AXI_RREADY(read_data_ready)
                );

always
    #3 aclk <=~aclk;

reg [31:0] data [0:113];
initial begin
$readmemh("./dum.mem",data);
end

reg [11:0] i;
initial begin
    arstn = 0;
    i=0;
    #20 arstn=1;
    #1500 axi_write(12'd0,data[0]);
    for(i=1;i<=32'D122;i=i+1) begin
        #1500 axi_write(i,data[i]);    //write i to slv_reg0\
        end
    #1500 axi_write(12'd510,32'h1c0);
    #1500 axi_write(12'd511,32'h1);
    #300
    #20 arstn = 0;
//    #20 axi_write(i,data[i]);
//    #20 axi_write(i,data[i]);
//    $finish;
end

    task axi_write;
    input [31:0] address;
    input [31:0] data;
    begin
        write_addr = address;
        write_data = data;
        write_addr_valid = 1'b1;
        write_data_valid = 1'b1;
        write_strb = 4'b1111;

        wait (write_addr_ready && write_data_ready);
        write_resp_ready = 1'b1;
        
        wait (write_resp_valid == 1'b1);
        write_addr_valid = 1'b0;
        write_data_valid = 1'b0;
        
        wait (write_resp_valid == 1'b0);
        write_resp_ready = 1'b0;
    end
endtask

//task axi_write;
//    input [31:0] addr;
//    input [31:0] data;
//    begin
//        #3 write_addr <= addr;    //Put write address on bus
//        write_data <= data;    //put write data on bus
//        write_addr_valid <= 1'b1;    //indicate address is valid
//        write_data_valid <= 1'b1;    //indicate data is valid
//        write_resp_ready <= 1'b1;    //indicate ready for a response
//        write_strb <= 4'hF;        //writing all 4 bytes

//        //wait for one slave ready signal or the other
//        wait(write_data_ready || write_addr_ready);

//        @(posedge aclk); //one or both signals and a positive edge
//        if(write_data_ready&&write_addr_ready)//received both ready signals
//        begin
//            write_addr_valid<=0;
//            write_data_valid<=0;
//        end
//        else    //wait for the other signal and a positive edge
//        begin
//            if(write_data_ready)    //case data handshake completed
//            begin
//                write_data_valid<=0;
//                wait(write_addr_ready); //wait for address address ready
//            end
//            else if(write_addr_ready)   //case address handshake completed
//            begin
//                write_addr_valid<=0;
//                wait(write_data_ready); //wait for data ready
//            end
//            @ (posedge aclk);// complete the second handshake
//            write_addr_valid<=0; //make sure both valid signals are deasserted
//            write_data_valid<=0;
//        end

//        //both handshakes have occured
//        //deassert strobe
//        write_strb<=0;

//        //wait for valid response
//        wait(write_resp_valid);

//        //both handshake signals and rising edge
//        @(posedge aclk);

//        //deassert ready for response
//        write_resp_ready<=0;


//        //end of write transaction
//    end
//endtask

endmodule
