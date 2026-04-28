`timescale 1ns / 1ps

module vga_top(
	input ClkPort,
	input BtnC, BtnU, BtnL, BtnD, BtnR,
	output Ld0, Ld1,
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	output QuadSpiFlashCS,
	output QSPI_DQ0,
	input  QSPI_DQ1,
	output AUD_PWM,
	output AUD_SD
);

	// power-on reset
	reg [3:0] reset_counter = 4'b1111;
	wire reset = (reset_counter != 0);
	always @(posedge ClkPort)
		if (reset_counter != 0) reset_counter <= reset_counter - 1;

	wire bright;
	wire [9:0] hc, vc;
	wire [15:0] score, comboCount;
	wire [3:0] multiplier, missCount;
    wire [6:0] ssdOut;
	wire [7:0] anode;
	wire [11:0] rgb;
    wire gameOver;
    wire game_running_dbg;

	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));

	vga_bitchange vbc(
		.clk(ClkPort), .reset(reset), .bright(bright), .game_start(BtnC),
		.btnL(BtnL), .btnD(BtnD), .btnU(BtnU), .btnR(BtnR),
		.hCount(hc), .vCount(vc), .rgb(rgb),
		.score(score), .comboCount(comboCount), .multiplier(multiplier),
		.missCount(missCount), .gameOver(gameOver),
		.game_running_dbg(game_running_dbg)
	);

	counter cnt(.clk(ClkPort), .displayNumber(score), .multiplier(multiplier), .anode(anode), .ssdOut(ssdOut));

	// FIFO
	wire [15:0] fifo_dout;
	wire fifo_empty, fifo_full, fifo_rd_en, fifo_prog_full;
	wire [7:0] flash_data;
	wire flash_valid;

	fifo_generator_0 fifo_inst (
		.clk(ClkPort), .srst(reset),
		.din(flash_data), .wr_en(flash_valid),
		.rd_en(fifo_rd_en), .dout(fifo_dout),
		.empty(fifo_empty), .prog_full(fifo_prog_full), .full(fifo_full)
	);

	// audio
	wire audio_signal;
	audio_player player (
		.clk(ClkPort), .reset(reset),
		.fifo_dout(fifo_dout), .fifo_empty(fifo_empty), .fifo_rd_en(fifo_rd_en),
		.audio_out(audio_signal)
	);

	assign AUD_PWM = audio_signal;
	assign AUD_SD = 1'b1;

	// SPI flash
	wire spi_clk;
	spi_flash_reader flash_reader (
		.clk(ClkPort), .reset(reset),
		.cs(QuadSpiFlashCS), .spi_clk_out(spi_clk), .mosi(QSPI_DQ0), .miso(QSPI_DQ1),
		.data_out(flash_data), .data_valid(flash_valid),
		.fifo_full(fifo_full), .fifo_prog_full(fifo_prog_full)
	);

	STARTUPE2 startup_inst (
		.CFGCLK(), .CFGMCLK(), .EOS(), .PREQ(),
		.CLK(1'b0), .GSR(1'b0), .GTS(1'b0), .KEYCLEARB(1'b1), .PACK(1'b0),
		.USRCCLKO(spi_clk), .USRCCLKTS(1'b0), .USRDONEO(1'b1), .USRDONETS(1'b0)
	);

	// outputs
	assign Dp = 1;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = ssdOut[6:0];
	assign {An7, An6, An5, An4, An3, An2, An1, An0} = anode;
	assign vgaR = rgb[11:8];
	assign vgaG = rgb[7:4];
	assign vgaB = rgb[3:0];
	assign Ld0 = game_running_dbg;  // LED on = game started
	assign Ld1 = flash_valid;

endmodule
