module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 115200
)(
    input wire clk,
    input wire rx,
    output reg [7:0] data,
    output reg valid
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    reg [15:0] clk_cnt = 0;
    reg [3:0] bit_index = 0;
    reg [7:0] rx_shift = 0;
    reg receiving = 0;

    always @(posedge clk) begin
        valid <= 0;

        if (!receiving) begin
            if (rx == 0) begin // start bit
                receiving <= 1;
                clk_cnt <= CLKS_PER_BIT / 2;
                bit_index <= 0;
            end
        end else begin
            if (clk_cnt == CLKS_PER_BIT-1) begin
                clk_cnt <= 0;

                if (bit_index < 8) begin
                    rx_shift[bit_index] <= rx;
                    bit_index <= bit_index + 1;
                end else begin
                    receiving <= 0;
                    data <= rx_shift;
                    valid <= 1;
                end

            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
    end
endmodule