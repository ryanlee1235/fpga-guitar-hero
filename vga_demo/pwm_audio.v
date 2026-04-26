module pwm_audio (
    input wire clk,
    input wire [11:0] sample,
    output wire audio_out
);

    reg [11:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign audio_out = (counter < sample);

endmodule