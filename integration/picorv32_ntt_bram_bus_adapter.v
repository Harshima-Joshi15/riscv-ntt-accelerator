`timescale 1ns/1ps

module picorv32_ntt_bram_bus_adapter (
    input  wire        clk,
    input  wire        rst,

    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output wire        mem_ready,
    output wire [31:0] mem_rdata,

    output wire        mmio_wr_en,
    output wire        mmio_rd_en,
    output wire [11:0] mmio_addr,
    output wire [31:0] mmio_wdata,
    input  wire [31:0] mmio_rdata
);

    wire accelerator_select;
    reg read_wait;

    assign accelerator_select =
        (mem_addr[31:12] == 20'h10000);

    assign mmio_wr_en =
        mem_valid &&
        accelerator_select &&
        (|mem_wstrb) &&
        !rst;

    assign mmio_rd_en =
        mem_valid &&
        accelerator_select &&
        (mem_wstrb == 4'b0000) &&
        !rst;

    assign mmio_addr  = mem_addr[11:0];
    assign mmio_wdata = mem_wdata;

    // Writes complete immediately.
    // Reads wait one cycle for synchronous BRAM data.
    assign mem_ready =
        mem_valid &&
        accelerator_select &&
        !rst &&
        ((|mem_wstrb) || read_wait);

    assign mem_rdata =
        (accelerator_select && mem_wstrb == 4'b0000)
        ? mmio_rdata : 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            read_wait <= 1'b0;
        end else if (!mem_valid || !accelerator_select || (|mem_wstrb)) begin
            read_wait <= 1'b0;
        end else if (!read_wait) begin
            read_wait <= 1'b1;
        end else if (mem_ready) begin
            read_wait <= 1'b0;
        end
    end

endmodule
