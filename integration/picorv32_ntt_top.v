
`timescale 1ns/1ps

module picorv32_ntt_top #(
    parameter PROGRAM_FILE = "firmware/firmware.hex",
    parameter integer PROGRAM_LAST_WORD = 306
) (
    input wire clk,
    input wire resetn
);

    // PicoRV32 memory bus
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    // Processor optional interfaces
    wire        trap;
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [3:0]  mem_la_wstrb;

    wire        pcpi_valid;
    wire [31:0] pcpi_insn;
    wire [31:0] pcpi_rs1;
    wire [31:0] pcpi_rs2;
    wire [31:0] eoi;
    wire        trace_valid;
    wire [35:0] trace_data;

    // Processor memory interface
    wire        memory_ready;
    wire [31:0] memory_rdata;

    // Accelerator interface
    wire        accelerator_ready;
    wire [31:0] accelerator_rdata;

    wire        mmio_wr_en;
    wire        mmio_rd_en;
    wire [11:0] mmio_addr;
    wire [31:0] mmio_wdata;
    wire [31:0] mmio_rdata;

    // Address decoder
    wire accelerator_select;

    assign accelerator_select =
        (mem_addr[31:12] == 20'h10000);

    // Select response from memory or accelerator.
    assign mem_ready =
        accelerator_select ? accelerator_ready : memory_ready;

    assign mem_rdata =
        accelerator_select ? accelerator_rdata : memory_rdata;

    // PicoRV32 processor
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_COUNTERS64(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .COMPRESSED_ISA(0),
        .ENABLE_MUL(0),
        .ENABLE_DIV(0),
        .ENABLE_IRQ(0),
        .ENABLE_TRACE(0),
        .PROGADDR_RESET(32'h00000000)
    ) cpu (
        .clk(clk),
        .resetn(resetn),

        .trap(trap),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),

        .mem_la_read(mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr(mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb),

        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'b0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),

        .irq(32'b0),
        .eoi(eoi),

        .trace_valid(trace_valid),
        .trace_data(trace_data)
    );

    // Program and data memory
    picorv32_ntt_memory #(
        .PROGRAM_FILE(PROGRAM_FILE),
        .PROGRAM_LAST_WORD(PROGRAM_LAST_WORD)
    ) memory (
        .clk(clk),
        .mem_valid(mem_valid && !accelerator_select),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_ready(memory_ready),
        .mem_rdata(memory_rdata)
    );

    // PicoRV32-to-NTT bus adapter
    picorv32_ntt_bus_adapter bus_adapter (
        .clk(clk),
        .rst(!resetn),

        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_ready(accelerator_ready),
        .mem_rdata(accelerator_rdata),

        .mmio_wr_en(mmio_wr_en),
        .mmio_rd_en(mmio_rd_en),
        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_rdata(mmio_rdata)
    );

    // NTT accelerator
    ntt_accelerator_mmio accelerator (
        .clk(clk),
        .rst(!resetn),
        .wr_en(mmio_wr_en),
        .rd_en(mmio_rd_en),
        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .rdata(mmio_rdata)
    );

endmodule
