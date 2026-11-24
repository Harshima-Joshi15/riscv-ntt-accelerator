`timescale 1ns/1ps

module mlkem_ntt_bram_engine_barrett_opt (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,

    input  wire        cpu_wr_en,
    input  wire [7:0]  cpu_wr_addr,
    input  wire [11:0] cpu_wr_data,

    input  wire        cpu_rd_en,
    input  wire [7:0]  cpu_rd_addr,
    output wire [11:0] cpu_rd_data,

    output reg         init_done,
    output reg         busy,
    output reg         done
);

    localparam integer Q = 3329;

    localparam [2:0] INIT    = 3'd0;
    localparam [2:0] IDLE    = 3'd1;
    localparam [2:0] READ_A  = 3'd2;
    localparam [2:0] READ_B  = 3'd3;
    localparam [2:0] WRITE_U = 3'd4;
    localparam [2:0] WRITE_V = 3'd5;

    reg [2:0] state;

    reg [7:0] init_addr;
    reg [7:0] stage_len;
    reg [7:0] group_start;
    reg [7:0] j_offset;
    reg [6:0] twiddle_index;

    reg [11:0] operand_a;
    reg [11:0] result_v;

    wire [7:0] a_index;
    wire [7:0] b_index;

    wire [11:0] zeta;
    wire [11:0] butterfly_u;
    wire [11:0] butterfly_v;

    wire [11:0] bram_rd_data;

    reg        bram_rd_en;
    reg [7:0]  bram_rd_addr;

    reg        bram_wr_en;
    reg [7:0]  bram_wr_addr;
    reg [11:0] bram_wr_data;

    wire [11:0] normalized_cpu_data;
    wire [8:0] next_group;

    assign normalized_cpu_data = cpu_wr_data % Q;

    assign a_index = group_start + j_offset;
    assign b_index = group_start + j_offset + stage_len;

    assign next_group =
        {1'b0, group_start} + ({1'b0, stage_len} << 1);

    // Shared coefficient memory.
    ntt_coeff_bram_1r1w coeff_bram (
        .clk(clk),
        .rd_en(bram_rd_en),
        .rd_addr(bram_rd_addr),
        .rd_data(bram_rd_data),
        .wr_en(bram_wr_en),
        .wr_addr(bram_wr_addr),
        .wr_data(bram_wr_data)
    );

    // Existing verified twiddle ROM.
    ntt_twiddle_rom twiddle_rom (
        .addr(twiddle_index),
        .zeta(zeta)
    );

    // Existing verified modular butterfly.
    ntt_butterfly_barrett_opt #(.Q(Q)) butterfly (
        .a(operand_a),
        .b(bram_rd_data),
        .zeta(zeta),
        .u(butterfly_u),
        .v(butterfly_v)
    );

    assign cpu_rd_data = bram_rd_data;

    // Memory-port ownership and operation selection.
    always @(*) begin
        bram_rd_en   = 1'b0;
        bram_rd_addr = 8'd0;

        bram_wr_en   = 1'b0;
        bram_wr_addr = 8'd0;
        bram_wr_data = 12'd0;

        case (state)

            INIT: begin
                bram_wr_en   = 1'b1;
                bram_wr_addr = init_addr;
                bram_wr_data = 12'd0;
            end

            IDLE: begin
                if (cpu_wr_en) begin
                    bram_wr_en   = 1'b1;
                    bram_wr_addr = cpu_wr_addr;
                    bram_wr_data = normalized_cpu_data;
                end

                if (cpu_rd_en) begin
                    bram_rd_en   = 1'b1;
                    bram_rd_addr = cpu_rd_addr;
                end
            end

            READ_A: begin
                bram_rd_en   = 1'b1;
                bram_rd_addr = a_index;
            end

            READ_B: begin
                bram_rd_en   = 1'b1;
                bram_rd_addr = b_index;
            end

            WRITE_U: begin
                bram_wr_en   = 1'b1;
                bram_wr_addr = a_index;
                bram_wr_data = butterfly_u;
            end

            WRITE_V: begin
                bram_wr_en   = 1'b1;
                bram_wr_addr = b_index;
                bram_wr_data = result_v;
            end

            default: begin
            end

        endcase
    end

    // NTT controller.
    always @(posedge clk) begin
        if (rst) begin
            state         <= INIT;
            init_addr     <= 8'd0;
            init_done     <= 1'b0;

            busy          <= 1'b0;
            done          <= 1'b0;

            stage_len     <= 8'd128;
            group_start   <= 8'd0;
            j_offset      <= 8'd0;
            twiddle_index <= 7'd1;

            operand_a     <= 12'd0;
            result_v      <= 12'd0;
        end else begin
            done <= 1'b0;

            case (state)

                INIT: begin
                    if (init_addr == 8'd255) begin
                        init_done <= 1'b1;
                        init_addr <= 8'd0;
                        state     <= IDLE;
                    end else begin
                        init_addr <= init_addr + 1'b1;
                    end
                end

                IDLE: begin
                    busy <= 1'b0;

                    if (start && init_done) begin
                        busy          <= 1'b1;

                        stage_len     <= 8'd128;
                        group_start   <= 8'd0;
                        j_offset      <= 8'd0;
                        twiddle_index <= 7'd1;

                        state <= READ_A;
                    end
                end

                READ_A: begin
                    state <= READ_B;
                end

                READ_B: begin
                    operand_a <= bram_rd_data;
                    state     <= WRITE_U;
                end

                WRITE_U: begin
                    result_v <= butterfly_v;
                    state    <= WRITE_V;
                end

                WRITE_V: begin
                    if (j_offset + 1 < stage_len) begin
                        j_offset <= j_offset + 1'b1;
                        state    <= READ_A;
                    end else begin
                        j_offset <= 8'd0;

                        if (next_group < 9'd256) begin
                            group_start   <= next_group[7:0];
                            twiddle_index <= twiddle_index + 1'b1;
                            state         <= READ_A;
                        end else if (stage_len > 8'd2) begin
                            stage_len     <= stage_len >> 1;
                            group_start   <= 8'd0;
                            twiddle_index <= twiddle_index + 1'b1;
                            state         <= READ_A;
                        end else begin
                            state     <= IDLE;
                            busy      <= 1'b0;
                            done      <= 1'b1;
                        end
                    end
                end

                default: begin
                    state <= INIT;
                    busy  <= 1'b0;
                end

            endcase
        end
    end

endmodule


