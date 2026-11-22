
`timescale 1ns/1ps

module picorv32_ntt_memory #(
    parameter PROGRAM_FILE = "firmware/firmware.hex",
    parameter integer PROGRAM_LAST_WORD = 306
) (
    input  wire        clk,

    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,

    output reg         mem_ready,
    output reg  [31:0] mem_rdata
);

    // 4 KB program memory and 4 KB data memory.
    reg [31:0] program_mem [0:1023];
    reg [31:0] data_mem    [0:1023];

    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            program_mem[i] = 32'h00000013; // NOP
            data_mem[i] = 32'h00000000;
        end

        $readmemh(PROGRAM_FILE, program_mem, 0, PROGRAM_LAST_WORD);
    end

    // Combinational reads and memory transaction acknowledgement.
    always @(*) begin
        mem_ready = 1'b0;
        mem_rdata = 32'b0;

        if (mem_valid) begin
            if (mem_addr[31:12] == 20'h00000) begin
                mem_ready = 1'b1;
                mem_rdata = program_mem[mem_addr[11:2]];
            end
            else if (mem_addr[31:12] == 20'h00001) begin
                mem_ready = 1'b1;
                mem_rdata = data_mem[mem_addr[11:2]];
            end
        end
    end

    // Synchronous, byte-enabled writes to data memory.
    always @(posedge clk) begin
        if (mem_valid && mem_ready &&
            mem_addr[31:12] == 20'h00001) begin

            if (mem_wstrb[0])
                data_mem[mem_addr[11:2]][7:0] <= mem_wdata[7:0];

            if (mem_wstrb[1])
                data_mem[mem_addr[11:2]][15:8] <= mem_wdata[15:8];

            if (mem_wstrb[2])
                data_mem[mem_addr[11:2]][23:16] <= mem_wdata[23:16];

            if (mem_wstrb[3])
                data_mem[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
        end
    end

endmodule
