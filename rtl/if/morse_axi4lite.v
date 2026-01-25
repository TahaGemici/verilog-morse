module morse_axi4lite (
    input aclk,
    input aresetn,

    input awvalid,
    output reg awready,
    input[31:0] awaddr,
    input[2:0] awprot,

    input wvalid,
    output reg wready,
    input[31:0] wdata,
    input[3:0] wstrb,

    output reg bvalid,
    input bready,
    output reg[1:0] bresp,

    input arvalid,
    output reg arready,
    input[31:0] araddr,
    input[2:0] arprot,

    output reg rvalid,
    input rready,
    output reg[31:0] rdata,
    output reg[1:0] rresp,

    output morse_out
);
    // memory-mapped registers
    reg[31:0] mem[0:2], mem_nxt[0:2]; // 0: prescaler, 1: status, 2: ascii_in
    reg write_en, write_en_nxt;
    wire full, empty;
    reg recv_aw, recv_w, recv_r;
    reg recv_aw_nxt, recv_w_nxt, recv_r_nxt;
    reg[3:0] wstrb_reg;
    reg[31:0] awaddr_reg, wdata_reg, araddr_reg;
    reg[31:0] awaddr_reg_nxt, wdata_reg_nxt, araddr_reg_nxt;
    always @(posedge aclk or negedge aresetn) begin
        if(~aresetn) begin
            mem[0] <= 0;
            mem[2] <= 0;
            write_en <= 1'b0;
        end else begin
            mem[0] <= mem_nxt[0];
            mem[2] <= mem_nxt[2];
            write_en <= write_en_nxt;
        end
    end
    always @* begin
        mem[1] = {30'b0, full, empty};
        mem_nxt[0] = mem[0];
        mem_nxt[2] = mem[2];
        write_en_nxt = 1'b0;
        if(recv_aw & recv_w) begin
            case(awaddr_reg[3:2])
                2'd0: begin
                    if(wstrb_reg[0]) mem_nxt[0][7:0] = wdata_reg[7:0];
                    if(wstrb_reg[1]) mem_nxt[0][15:8] = wdata_reg[15:8];
                    if(wstrb_reg[2]) mem_nxt[0][23:16] = wdata_reg[23:16];
                    if(wstrb_reg[3]) mem_nxt[0][31:24] = wdata_reg[31:24];
                end
                2'd2: begin
                    if(wstrb_reg[0]) begin
                        mem_nxt[2][7:0] = wdata_reg[7:0];
                        write_en_nxt = 1'b1;
                    end
                    if(wstrb_reg[1]) mem_nxt[2][15:8] = wdata_reg[15:8];
                    if(wstrb_reg[2]) mem_nxt[2][23:16] = wdata_reg[23:16];
                    if(wstrb_reg[3]) mem_nxt[2][31:24] = wdata_reg[31:24];
                end
            endcase
        end
    end

    morse morse_inst (
        .clk(aclk),
        .arst_n(aresetn),

        .write_en(write_en),
        .ascii_in(mem[2][7:0]),
        .prescaler(mem[0]),
        .full(full),
        .empty(empty),

        .morse_out(morse_out)
    );

    // Write Address Channel
    reg awready_nxt;
    always @(posedge aclk or negedge aresetn) begin
        if(~aresetn) begin
            awready <= 1'b0;
            awaddr_reg <= 32'b0;
            recv_aw <= 1'b0;
        end else begin
            awready <= awready_nxt;
            awaddr_reg <= awaddr_reg_nxt;
            recv_aw <= recv_aw_nxt;
        end
    end
    always @* begin
        awready_nxt = awready;
        awaddr_reg_nxt = awaddr_reg;
        if(awvalid) begin
            awaddr_reg_nxt = awaddr;
            awready_nxt = 1'b1;
            if(awaddr[3:2] == 2'd2) begin
                awready_nxt = ~full;
            end
            if(recv_aw) awready_nxt = 1'b0;
        end
        if(awready) awready_nxt = 1'b0;
        
        recv_aw_nxt = recv_aw;
        if(awready & awvalid) recv_aw_nxt = 1'b1;
        if(bvalid & bready) recv_aw_nxt = 1'b0;
    end

    // Write Data Channel
    reg wready_nxt;
    always @(posedge aclk or negedge aresetn) begin
        if(~aresetn) begin
            wready <= 1'b0;
            wdata_reg <= 32'b0;
            wstrb_reg <= 4'b0;
        end else begin
            wready <= wready_nxt;
            wdata_reg <= wdata_reg_nxt;
            wstrb_reg <= wstrb;
        end
    end

    always @* begin
        wready_nxt = wready;
        wdata_reg_nxt = wdata_reg;
        if(wvalid) begin
            wready_nxt = 1'b1;
            wdata_reg_nxt = wdata;
        end
        if((~awvalid)|wready|wait_bresp) wready_nxt = 1'b0;
    end

    // Write Response Channel
    reg bvalid_nxt;
    reg[1:0] bresp_nxt;
    always @(posedge aclk or negedge aresetn) begin
        if(~aresetn) begin
            bvalid <= 1'b0;
            bresp <= OKAY;
            wait_bresp <= 1'b0;
        end else begin
            bvalid <= bvalid_nxt;
            bresp <= bresp_nxt;
            wait_bresp <= wait_bresp_nxt;
        end
    end

    always @* begin
        bvalid_nxt = bvalid;
        bresp_nxt = bresp;
        wait_bresp_nxt = wait_bresp;

        if(wready & wvalid) begin
            bvalid_nxt = 1'b1;
            bresp_nxt = (awaddr_reg[3:2] == 2'd3) ? DECERR : OKAY;
            bresp_nxt = awaddr_reg[1:0] ? SLVERR : OKAY;
            wait_bresp_nxt = 1'b1;
        end
        if(bready & bvalid) begin
            bvalid_nxt = 1'b0;
            wait_bresp_nxt = 1'b0;
        end
    end

    axi4lite_read_slave read_slave_inst (
        .aclk(aclk),
        .aresetn(aresetn),

        .arvalid(arvalid),
        .arready(arready),
        .araddr(araddr),
        .arprot(arprot),

        .rvalid(rvalid),
        .rready(rready),
        .rdata(rdata),
        .rresp(rresp),

        .valid(araddr[3:2] < 2'd3),
        .data(mem[araddr[3:2]])
    );
endmodule