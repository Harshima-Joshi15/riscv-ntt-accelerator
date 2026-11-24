`timescale 1ns/1ps

module ntt_accelerator_mmio_bram_barrett_opt (
    input  wire        clk,
    input  wire        rst,

    input  wire        wr_en,
    input  wire        rd_en,
    input  wire [11:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg start;
    reg done_sticky;
    reg rd_pending;

    wire init_done;
    wire busy;
    wire done;

    wire cpu_wr_en;
    wire cpu_rd_en;

    wire [7:0] cpu_wr_addr;
    wire [7:0] cpu_rd_addr;

    wire [11:0] cpu_rd_data;

    wire input_write_address;
    wire output_read_address;

    assign input_write_address =
        (addr >= 12'h100) &&
        (addr <= 12'h4FC) &&
        (addr[1:0] == 2'b00);

    assign output_read_address =
        (addr >= 12'h500) &&
        (addr <= 12'h8FC) &&
        (addr[1:0] == 2'b00);

    assign cpu_wr_en =
        wr_en && input_write_address && init_done && !busy;

    assign cpu_wr_addr = (addr - 12'h100) >> 2;

    assign cpu_rd_en =
        rd_en && output_read_address && init_done && !busy;

    assign cpu_rd_addr = (addr - 12'h500) >> 2;

    // Shared BRAM-based NTT engine.
    mlkem_ntt_bram_engine_barrett_opt engine (
        .clk(clk),
        .rst(rst),
        .start(start),

        .cpu_wr_en(cpu_wr_en),
        .cpu_wr_addr(cpu_wr_addr),
        .cpu_wr_data(wdata[11:0]),

        .cpu_rd_en(cpu_rd_en),
        .cpu_rd_addr(cpu_rd_addr),
        .cpu_rd_data(cpu_rd_data),

        .init_done(init_done),
        .busy(busy),
        .done(done)
    );

    // Control register and sticky completion status.
    always @(posedge clk) begin
        if (rst) begin
            start       <= 1'b0;
            done_sticky <= 1'b0;
            rd_pending  <= 1'b0;
        end else begin
            start      <= 1'b0;
            rd_pending <= cpu_rd_en;

            if (done)
                done_sticky <= 1'b1;

            if (wr_en && addr == 12'h000) begin
                if (wdata[0] && !busy && init_done) begin
                    start       <= 1'b1;
                    done_sticky <= 1'b0;
                end
            end
        end
    end

    // Status reads are combinational.
    // Coefficient reads use the synchronous BRAM response.
    always @(*) begin
        rdata = 32'd0;

        if (rd_pending) begin
            rdata[11:0] = cpu_rd_data;
        end else if (rd_en && addr == 12'h004) begin
            rdata[0] = busy;
            rdata[1] = done_sticky;
            rdata[2] = init_done;
        end
    end

endmodule


