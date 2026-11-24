`timescale 1ns/1ps

module ntt_coeff_bram (
    input  wire        clk,

    input  wire        en_a,
    input  wire        we_a,
    input  wire [7:0]  addr_a,
    input  wire [11:0] din_a,
    output reg  [11:0] dout_a,

    input  wire        en_b,
    input  wire        we_b,
    input  wire [7:0]  addr_b,
    input  wire [11:0] din_b,
    output reg  [11:0] dout_b
);

    reg [11:0] mem [0:255];

    always @(posedge clk) begin
        if (en_a) begin
            if (we_a)
                mem[addr_a] <= din_a;
            dout_a <= mem[addr_a];
        end
    end

    always @(posedge clk) begin
        if (en_b) begin
            if (we_b)
                mem[addr_b] <= din_b;
            dout_b <= mem[addr_b];
        end
    end

endmodule
