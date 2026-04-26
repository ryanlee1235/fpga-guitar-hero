module audio_player (
    input wire clk,          // 100 MHz
    input wire reset,
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
    reg [31:0] addr = 0;
    wire [11:0] sample;

    parameter MAX_ADDR = 66150;

    always @(posedge clk) begin
        if (reset)
            addr <= 0;
        else if (sample_tick) begin
            if (addr < MAX_ADDR)
                addr <= addr + 1;
        end
    end

    // ROM
    audio_rom rom (
        .addr(addr),
        .data(sample)
    );

    // PWM
    pwm_audio pwm (
        .clk(clk),
        .sample(sample),
        .audio_out(audio_out)
    );

endmodule