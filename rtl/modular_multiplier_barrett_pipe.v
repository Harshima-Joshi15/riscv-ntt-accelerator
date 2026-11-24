`timescale 1ns/1ps

module modular_multiplier_barrett_pipe (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg  [11:0] result,
    output wire       done
);

    // ML-KEM parameters: Q = 3329, MU = 5039.

    reg [7:0] valid;

    reg [23:0] product_reg;
    reg [36:0] partial_a_reg, partial_b_reg;
    reg [36:0] scaled_reg;
    reg [12:0] qhat_reg;

    reg [24:0] qpos_reg, qneg_reg;
    reg [24:0] qproduct_reg;

    reg [23:0] product_d1, product_d2;
    reg [23:0] product_d3, product_d4, product_d5;

    reg [24:0] remainder_reg;

    wire [36:0] product_ext;
    wire [24:0] qhat_ext;

    assign product_ext = {13'd0, product_reg};
    assign qhat_ext = {12'd0, qhat_reg};

    assign done = valid[7];

    always @(posedge clk) begin
        if (rst) begin
            valid          <= 8'd0;
            product_reg    <= 24'd0;
            partial_a_reg  <= 37'd0;
            partial_b_reg  <= 37'd0;
            scaled_reg     <= 37'd0;
            qhat_reg       <= 13'd0;
            qpos_reg       <= 25'd0;
            qneg_reg       <= 25'd0;
            qproduct_reg   <= 25'd0;
            product_d1     <= 24'd0;
            product_d2     <= 24'd0;
            product_d3     <= 24'd0;
            product_d4     <= 24'd0;
            product_d5     <= 24'd0;
            remainder_reg  <= 25'd0;
            result         <= 12'd0;
        end else begin
            valid <= {valid[6:0], start};

            // Stage 1: DSP multiplication.
            if (start)
                product_reg <= a * b;

            // Stage 2: Split constant multiplication by 5039.
            partial_a_reg <=
                  (product_ext << 12)
                + (product_ext << 9)
                + (product_ext << 8)
                + (product_ext << 7);

            partial_b_reg <=
                  (product_ext << 5)
                + (product_ext << 3)
                + (product_ext << 2)
                + (product_ext << 1)
                + product_ext;

            product_d1 <= product_reg;

            // Stage 3: Complete scaled product.
            scaled_reg <= partial_a_reg + partial_b_reg;
            product_d2 <= product_d1;

            // Stage 4: Quotient estimate.
            qhat_reg <= scaled_reg >> 24;
            product_d3 <= product_d2;

            // Stage 5: Split multiplication by 3329.
            qpos_reg <= (qhat_ext << 12) + qhat_ext;
            qneg_reg <= (qhat_ext << 9) + (qhat_ext << 8);
            product_d4 <= product_d3;

            // Stage 6: Complete quotient product.
            qproduct_reg <= qpos_reg - qneg_reg;
            product_d5 <= product_d4;

            // Stage 7: Remainder.
            remainder_reg <= {1'b0, product_d5} - qproduct_reg;

            // Stage 8: Final correction.
            if (remainder_reg >= 25'd3329)
                result <= remainder_reg - 25'd3329;
            else
                result <= remainder_reg[11:0];
        end
    end

endmodule
