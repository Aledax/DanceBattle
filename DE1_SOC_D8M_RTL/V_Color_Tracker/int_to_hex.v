module digit_to_hex(
    input [3:0]  i,
    output [6:0] o
);

    assign o = (i == 4'd0)?7'h40: //0
               (i == 4'd1)?7'h79: //1
               (i == 4'd2)?7'h24: //2
               (i == 4'd3)?7'h30: //3
               (i == 4'd4)?7'h19: //4        
               (i == 4'd5)?7'h12: //5
               (i == 4'd6)?7'h02: //6
               (i == 4'd7)?7'h78: //7
               (i == 4'd8)?7'h00: //8
                           7'h10; //9

endmodule

module int16_to_hex6(
    input [15:0]  i,
    output [41:0] o
);

    wire [3:0] ones = i % 10;
    wire [3:0] tens = (i / 10) % 10;
    wire [3:0] hundreds = (i / 100) % 10;
    wire [3:0] thousands = (i / 1000) % 10;
    wire [3:0] ten_thousands = (i / 10000) % 10;
    wire [3:0] hundred_thousands = (i / 100000) % 10;

    wire [6:0] ones_hex;
    wire [6:0] tens_hex;
    wire [6:0] hundreds_hex;
    wire [6:0] thousands_hex;
    wire [6:0] ten_thousands_hex;
    wire [6:0] hundred_thousands_hex;

    digit_to_hex digit_to_hex_ones(
        .i(ones),
        .o(ones_hex)
    );

    digit_to_hex digit_to_hex_tens(
        .i(tens),
        .o(tens_hex)
    );

    digit_to_hex digit_to_hex_hundreds(
        .i(hundreds),
        .o(hundreds_hex)
    );

    digit_to_hex digit_to_hex_thousands(
        .i(thousands),
        .o(thousands_hex)
    );

    digit_to_hex digit_to_hex_ten_thousands(
        .i(ten_thousands),
        .o(ten_thousands_hex)
    );

    digit_to_hex digit_to_hex_hundred_thousands(
        .i(hundred_thousands),
        .o(hundred_thousands_hex)
    );

    assign o = {hundred_thousands_hex, ten_thousands_hex, thousands_hex, hundreds_hex, tens_hex, ones_hex};

endmodule