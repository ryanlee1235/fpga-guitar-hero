module audio_player (
    input wire clk,
    input wire reset,

    input  wire [15:0] fifo_dout,
    input  wire        fifo_empty,
    output reg         fifo_rd_en,

    output wire audio_out
);

    parameter SAMPLE_RATE_DIV = 4535;

    reg [15:0] sample_timer = 0;
    reg sample_tick = 0;

    always @(posedge clk) begin
        if (reset) begin
            sample_timer <= 0;
            sample_tick <= 0;
        end else begin
            if (sample_timer >= SAMPLE_RATE_DIV) begin
                sample_timer <= 0;
                sample_tick <= 1;
            end else begin
                sample_timer <= sample_timer + 1;
                sample_tick <= 0;
            end
        end
    end

    // ROM address
    reg [15:0] sample = 16'd0;

    always @(posedge clk) begin
        fifo_rd_en <= 0;

        if (!fifo_empty) begin
            fifo_rd_en <= 1;
            if (sample_tick) begin
                sample <= fifo_dout;
            end
        end
    end

    // PWM
    pwm_audio pwm (
        .clk(clk),
        .sample(sample),
        .audio_out(audio_out)
    );

endmodule