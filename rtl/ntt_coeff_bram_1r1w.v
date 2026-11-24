`timescale 1ns/1ps

module ntt_coeff_bram_1r1w (
    input  wire        clk,

    input  wire        rd_en,
    input  wire [7:0]  rd_addr,
    output reg  [11:0] rd_data,

    input  wire        wr_en,
    input  wire [7:0]  wr_addr,
    input  wire [11:0] wr_data
);

    reg [11:0] mem [0:255];

    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;

        if (rd_en)
            rd_data <= mem[rd_addr];
    end

endmodule
