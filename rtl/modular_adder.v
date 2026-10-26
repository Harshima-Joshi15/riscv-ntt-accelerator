
module modular_adder (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output wire [11:0] result
);

    parameter Q = 3329;

    wire [12:0] sum;

    assign sum = a + b;

    assign result = (sum >= Q) ? sum - Q : sum;

endmodule
