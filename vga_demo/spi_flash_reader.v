module spi_flash_reader (
    input wire clk,
    input wire reset,
    output reg cs,
    output wire spi_clk_out,
    output reg mosi,
    input wire miso,
    output reg [7:0] data_out,
    output reg data_valid,
	input wire fifo_full,
    input wire fifo_prog_full
);

    reg [3:0] clk_div = 0;
    always @(posedge clk) clk_div <= clk_div + 1;

    wire spi_clk = clk_div[3];
    assign spi_clk_out = spi_clk;

	reg [3:0] state = 0;
    reg [5:0] bit_cnt = 0;
	reg [7:0] shift_reg = 0;
    reg [23:0] addr = 24'h200000;

    localparam IDLE = 0, CMD = 1, ADDR_ST = 2, READ = 3, CS_SETUP = 4;

    always @(negedge spi_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cs <= 1;
            mosi <= 0;
            bit_cnt <= 0;
            data_valid <= 0;
            addr <= 24'h200000;
        end else begin
            data_valid <= 0;

            case (state)
                IDLE: begin
                    cs <= 1;
                    if (!fifo_prog_full) begin
                        cs <= 0;
                        bit_cnt <= 0;
                        state <= CS_SETUP;
                    end
                end

                CS_SETUP: state <= CMD;

                CMD: begin
                    mosi <= 8'h03[7 - bit_cnt];  // READ command
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin bit_cnt <= 0; state <= ADDR_ST; end
                end

                ADDR_ST: begin
                    mosi <= addr[23 - bit_cnt];
                    bit_cnt <= bit_cnt + 1;
					if (bit_cnt == 23) begin bit_cnt <= 0; state <= READ; end
                end
                READ: begin
                    if (bit_cnt == 0) shift_reg <= 0;
                    else shift_reg <= {shift_reg[6:0], miso};
                    bit_cnt <= bit_cnt + 1;

                    if (bit_cnt == 7) begin
                        data_out <= {shift_reg[6:0], miso};
                        data_valid <= 1;
                        addr <= addr + 1;
                        bit_cnt <= 0;
                    end

                    if (fifo_prog_full) begin cs <= 1; state <= IDLE; end
                end
            endcase
        end
    end
endmodule
