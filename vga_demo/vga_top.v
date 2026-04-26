`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE354
// Engineer: Arda Caliskan
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
//
// Date: 11/11/2024
// Author: Arda Caliskan
// Description: Port from NEXYS4 to A7
//////////////////////////////////////////////////////////////////////////////////
module vga_top(
	input ClkPort,
	input BtnC,
	input BtnU,
	input BtnL,
	input BtnD,
	input BtnR,
	// UART compatibaility
	input UART_TXD_IN,

	output Ld0,
	output Ld1,
	
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	
	output QuadSpiFlashCS,

	// For audio port
	output AUD_PWM,
	output AUD_SD

);
	
	wire bright;
	wire[9:0] hc, vc;
	wire[15:0] score;
	wire[15:0] comboCount;
	wire[3:0] multiplier;
	wire [6:0] ssdOut;
	wire [7:0] anode;
	wire [11:0] rgb;
	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
	vga_bitchange vbc(.clk(ClkPort), .bright(bright), .btnL(BtnL), .btnD(BtnD), .btnU(BtnU), .btnR(BtnR), .hCount(hc), .vCount(vc), .rgb(rgb), .score(score), .comboCount(comboCount), .multiplier(multiplier));
	counter cnt(.clk(ClkPort), .displayNumber(score), .multiplier(multiplier), .anode(anode), .ssdOut(ssdOut));
	
	wire [15:0] fifo_dout;
	wire fifo_empty;
	wire fifo_full;
	wire fifo_rd_en;

	// FIFO signals
	wire [7:0] fifo_din;
	wire fifo_wr_en;

	// FIFO instance
	fifo_generator_0 fifo_inst (
		.clk(ClkPort),
		.srst(BtnC),

		.din(uart_data),
		.wr_en(uart_valid),

		.rd_en(fifo_rd_en),
		.dout(fifo_dout),

		.empty(fifo_empty),
		.full(fifo_full)
	);

	assign Dp = 1;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = ssdOut[6 : 0];
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = anode;

	
	assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	
	// disable memory port
	assign {QuadSpiFlashCS} = 1'b1;

	wire audio_signal;

	audio_player player (
		.clk(ClkPort),
		.reset(BtnC),

		.fifo_dout(fifo_dout),
		.fifo_empty(fifo_empty),
		.fifo_rd_en(fifo_rd_en),

		.audio_out(audio_signal)
	);

	assign AUD_PWM = audio_signal;
	assign AUD_SD  = 1'b1;

	assign Ld0 = UART_TXD_IN;  // raw signal
	assign Ld1 = uart_valid;   // decoded byte

	wire [7:0] uart_data;
	wire uart_valid;

	uart_rx uart_inst (
		.clk(ClkPort),
		.rx(UART_TXD_IN),
		.data(uart_data),
		.valid(uart_valid)
	);

endmodule
