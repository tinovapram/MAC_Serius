module rams_dist #
       (
           parameter    DATA_WIDTH    = 32,
           ADDRESS_WIDTH = 10,
           FIFO_DEPTH    = (1 << ADDRESS_WIDTH)
       )
       (
           clk, we0,we1, a0,a1,di0,di1, spo, dpo
       );
input wire clk;
input wire we0;
input wire we1;
input wire [ADDRESS_WIDTH-1:0] a0;
input wire [ADDRESS_WIDTH-1:0] a1;
input wire [DATA_WIDTH-1:0] di0;
input wire [DATA_WIDTH-1:0] di1;
output wire [DATA_WIDTH-1:0] spo;
output wire [DATA_WIDTH-1:0] dpo;

reg [15:0] ram [FIFO_DEPTH-1:0];

always @(posedge clk) begin
    if (we0)
        ram[a0] <= di0;
    else if (we1)
        ram[a1] <= di1;
end
assign spo = ram[a0];
assign dpo = ram[a1];

endmodule
