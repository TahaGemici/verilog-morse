module axi4lite_read_slave (
    input aclk,
    input aresetn,

    input arvalid,
    output reg arready,
    input[31:0] araddr,
    input[2:0] arprot,

    output reg rvalid,
    input rready,
    output reg[31:0] rdata,
    output reg[1:0] rresp,
    
    input valid,
    input[31:0] data
);

localparam OKAY = 2'b00, SLVERR = 2'b10, DECERR = 2'b11;

reg arready_nxt, rvalid_nxt;
reg[1:0] rresp_nxt;
reg[31:0] rdata_nxt;
always @(posedge aclk or negedge aresetn) begin
    if(~aresetn) begin
        arready <= 1'b0;
        rvalid <= 1'b0;
        rdata <= 32'b0;
        rresp <= OKAY;
    end else begin
        arready <= arready_nxt;
        rvalid <= rvalid_nxt;
        rdata <= rdata_nxt;
        rresp <= rresp_nxt;
    end
end

wire handshake_ar = arvalid & arready;
always @* begin
    arready_nxt = rvalid ? rready : 1'b1;
    rvalid_nxt = rvalid ? (~rready) : 1'b0;
    if(handshake_ar) begin
        arready_nxt = 1'b0;
        rvalid_nxt = 1'b1;
    end

    rdata_nxt = handshake_ar ? data : rdata;

    rresp_nxt = rresp;
    if(handshake_ar) begin
        rresp_nxt = OKAY;
        if(araddr[1:0]) rresp_nxt = SLVERR;
        if(~valid) rresp_nxt = DECERR;
    end
end

endmodule