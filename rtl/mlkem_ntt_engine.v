
`timescale 1ns/1ps

module mlkem_ntt_engine (
    input  wire          clk,
    input  wire          rst,
    input  wire          start,
    input  wire [3071:0] coeff_in,
    output wire [3071:0] coeff_out,
    output reg           busy,
    output reg           done
);

    localparam integer Q = 3329;

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] LOAD = 2'd1;
    localparam [1:0] RUN  = 2'd2;

    reg [1:0] state;

    reg [11:0] coeff_mem [0:255];

    reg [7:0] stage_len;
    reg [7:0] group_start;
    reg [7:0] j_offset;
    reg [6:0] twiddle_index;

    wire [7:0] a_index;
    wire [7:0] b_index;
    wire [11:0] zeta;
    wire [11:0] u;
    wire [11:0] v;

    integer i;
    genvar g;

    assign a_index = group_start + j_offset;
    assign b_index = group_start + j_offset + stage_len;

    // Look up the twiddle factor for the current group.
    ntt_twiddle_rom twiddle_rom (
        .addr(twiddle_index),
        .zeta(zeta)
    );

    // One reusable modular butterfly.
    ntt_butterfly #(.Q(Q)) butterfly (
        .a(coeff_mem[a_index]),
        .b(coeff_mem[b_index]),
        .zeta(zeta),
        .u(u),
        .v(v)
    );

    // Expose the internal coefficient array as a packed output.
    generate
        for (g = 0; g < 256; g = g + 1) begin : PACK_OUTPUT
            assign coeff_out[g*12 +: 12] = coeff_mem[g];
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            busy          <= 1'b0;
            done          <= 1'b0;
            stage_len     <= 8'd128;
            group_start   <= 8'd0;
            j_offset      <= 8'd0;
            twiddle_index <= 7'd1;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        busy  <= 1'b1;
                        state <= LOAD;
                    end
                end

                LOAD: begin
                    for (i = 0; i < 256; i = i + 1)
                        coeff_mem[i] <= coeff_in[i*12 +: 12] % Q;

                    stage_len     <= 8'd128;
                    group_start   <= 8'd0;
                    j_offset      <= 8'd0;
                    twiddle_index <= 7'd1;
                    state         <= RUN;
                end

                RUN: begin
                    coeff_mem[a_index] <= u;
                    coeff_mem[b_index] <= v;

                    if (j_offset + 1 < stage_len) begin
                        j_offset <= j_offset + 1'b1;
                    end else begin
                        j_offset <= 8'd0;

                        if ((group_start + (2 * stage_len)) < 256) begin
                            group_start   <= group_start + (2 * stage_len);
                            twiddle_index <= twiddle_index + 1'b1;
                        end else if (stage_len > 2) begin
                            stage_len     <= stage_len >> 1;
                            group_start   <= 8'd0;
                            twiddle_index <= twiddle_index + 1'b1;
                        end else begin
                            state <= IDLE;
                            busy  <= 1'b0;
                            done  <= 1'b1;
                        end
                    end
                end

                default: begin
                    state <= IDLE;
                    busy  <= 1'b0;
                end
            endcase
        end
    end

endmodule
