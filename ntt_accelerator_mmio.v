
`timescale 1ns/1ps

module ntt_accelerator_mmio (
    input  wire        clk,
    input  wire        rst,

    input  wire        wr_en,
    input  wire        rd_en,
    input  wire [11:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);

    reg [11:0] input_mem [0:255];
    wire [3071:0] coeff_in;
    wire [3071:0] coeff_out;

    reg start;
    wire busy;
    wire done;

    reg done_sticky;

    integer i;
    genvar g;

    // Pack 256 input coefficients into the engine input bus.
    generate
        for (g = 0; g < 256; g = g + 1) begin : PACK_INPUT
            assign coeff_in[g*12 +: 12] = input_mem[g];
        end
    endgenerate

    mlkem_ntt_engine engine (
        .clk(clk),
        .rst(rst),
        .start(start),
        .coeff_in(coeff_in),
        .coeff_out(coeff_out),
        .busy(busy),
        .done(done)
    );

    // Control registers and input coefficient memory.
    always @(posedge clk) begin
        if (rst) begin
            start       <= 1'b0;
            done_sticky <= 1'b0;

            for (i = 0; i < 256; i = i + 1)
                input_mem[i] <= 12'd0;
        end else begin
            // Default: start is a one-cycle pulse.
            start <= 1'b0;

            if (done)
                done_sticky <= 1'b1;

            if (wr_en) begin
                if (addr == 12'h000) begin
                    if (wdata[0] && !busy) begin
                        start       <= 1'b1;
                        done_sticky <= 1'b0;
                    end
                end else if (addr >= 12'h100 &&
                             addr <= 12'h4FC &&
                             addr[1:0] == 2'b00) begin
                    if (!busy)
                        input_mem[(addr - 12'h100) >> 2]
                            <= wdata[11:0];
                end
            end
        end
    end

    // Read status or one output coefficient.
    always @(*) begin
        rdata = 32'd0;

        if (rd_en) begin
            if (addr == 12'h004) begin
                rdata[0] = busy;
                rdata[1] = done_sticky;
            end else if (addr >= 12'h500 &&
                         addr <= 12'h8FC &&
                         addr[1:0] == 2'b00) begin
                rdata[11:0] =
                    coeff_out[((addr - 12'h500) >> 2)*12 +: 12];
            end
        end
    end

endmodule
