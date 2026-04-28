module spi_flash_reader (
    input  wire clk,        // 100 MHz (ClkPort)
    input  wire reset,

    // SPI flash interface
    output reg  cs,         // chip select (active low)
    output wire spi_clk_out,
    // output wire sclk,       // SPI clock
    output reg  mosi,
    input  wire miso,

    // FIFO interface (8-bit write)
    output reg [7:0] data_out,
    output reg       data_valid,
    input  wire      fifo_full
    //input  wire      fifo_prog_full
);

    // Clock divider (to fit in SPI clock)
    reg [9:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    // controls the speed of flow
    wire spi_clk = clk_div[9];
    // assign sclk = spi_clk;
    assign spi_clk_out = spi_clk;

    reg [7:0] cmd_reg = 8'h03;

    reg [3:0] state = 0;
    reg [5:0] bit_cnt = 0;
    reg [7:0] shift_reg = 0;

    reg [23:0] addr = 24'h200000;

    localparam IDLE  = 0;
    localparam CMD   = 1;
    localparam ADDR  = 2;
    localparam READ  = 3;
    localparam CS_SETUP = 4;

    // SPI logic
    always @(posedge spi_clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            cs         <= 1;
            mosi       <= 0;
            bit_cnt    <= 0;
            data_valid <= 0;
            addr       <= 24'h200000;
        end else begin
            data_valid <= 0;

            case (state)

            IDLE: begin
                cs <= 1;

                if (!fifo_full) begin
                    cs <= 0;
                    bit_cnt <= 0;
                    state <= CS_SETUP;
                end
            end

            CS_SETUP: begin
                state <= CMD;
            end

            CMD: begin
                mosi <= cmd_reg[7 - bit_cnt];
                bit_cnt <= bit_cnt + 1;

                if (bit_cnt == 7) begin
                    bit_cnt <= 0;
                    state <= ADDR;
                end
            end

            ADDR: begin
                mosi <= addr[23 - bit_cnt];
                bit_cnt <= bit_cnt + 1;

                if (bit_cnt == 23) begin
                    bit_cnt <= 0;
                    state <= READ;
                end
            end

            READ: begin
                shift_reg <= {miso, shift_reg[7:1]};
                bit_cnt <= bit_cnt + 1; 
                if (bit_cnt == 7) begin 
                    data_out <= shift_reg; 
                    data_valid <= 1; 
                    addr <= addr + 1; 
                    bit_cnt <= 0; 
                end

                if (fifo_full) begin
                    cs <= 1;
                    state <= IDLE;
                end
            end

            endcase
        end
    end
endmodule