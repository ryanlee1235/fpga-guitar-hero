`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:15:38 12/14/2017 
// Design Name: 
// Module Name:    vgaBitChange 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_bitchange(
	input clk,
	input bright,
	input btnL, btnD, btnU, btnR,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [15:0] score,
	output reg [15:0] comboCount,
    output reg [3:0]  multiplier
   );
	
	parameter BLACK = 12'b0000_0000_0000;
	parameter WHITE = 12'b1111_1111_1111;
	parameter RED    = 12'b1111_0000_0000;
	parameter GREEN  = 12'b0000_1111_0000;
	parameter BLUE   = 12'b0000_0000_1111;
	parameter YELLOW = 12'b1111_1111_0000;

	wire whiteZone;
	wire cube0, cube1, cube2, cube3;
	wire laneLine1, laneLine2, laneLine3;
	reg reset;
	reg[9:0] cubeY0, cubeY1, cubeY2, cubeY3;
	reg[49:0] cubeSpeed;

	initial begin
		cubeY0 = 10'd35;	
		cubeY1 = 10'd155;	
		cubeY2 = 10'd275;	
		cubeY3 = 10'd395;	
		comboCount = 16'd0;
    	multiplier = 4'd1;
		score = 16'd0;
		reset = 1'b0;
	end
	
	
	always@ (*) // paint a white box on a red background
    	if (~bright)
			rgb = BLACK; // force black if not bright
	    else if (cube0)
			rgb = GREEN;
		else if (cube1)
			rgb = RED;
		else if (cube2)
			rgb = YELLOW;
		else if (cube3)
			rgb = BLUE;
		else if (laneLine1 || laneLine2 || laneLine3)
			rgb = WHITE;
		else if (whiteZone == 1)
			rgb = WHITE; // white box
		else
			rgb = BLACK; // background color

	always @(posedge clk) begin
		cubeSpeed = cubeSpeed + 50'd1;
		if (btnL && cubeY0 >= 10'd400 && cubeY0 <= 10'd435) begin
			score = score + multiplier;
			comboCount = comboCount + 1;
			cubeY0 = 10'd0;
		end
		else if (cubeSpeed >= 50'd500000) begin
			cubeY0 = cubeY0 + 10'd1;
			if (cubeY0 >= 10'd515) cubeY0 = 10'd0;
		end

		if (btnD && cubeY1 >= 10'd400 && cubeY1 <= 10'd435) begin
			score = score + multiplier;
			comboCount = comboCount + 1;
			cubeY1 = 10'd0;
		end
		else if (cubeSpeed >= 50'd500000) begin
			cubeY1 = cubeY1 + 10'd1;
			if (cubeY1 >= 10'd515) cubeY1 = 10'd0;
		end

		if (btnU && cubeY2 >= 10'd400 && cubeY2 <= 10'd435) begin
			score = score + multiplier;
			comboCount = comboCount + 1;
			cubeY2 = 10'd0;
		end
		else if (cubeSpeed >= 50'd500000) begin
			cubeY2 = cubeY2 + 10'd1;
			if (cubeY2 >= 10'd515) cubeY2 = 10'd0;
		end

		if (btnR && cubeY3 >= 10'd400 && cubeY3 <= 10'd435) begin
			score = score + multiplier;
			comboCount = comboCount + 1;
			cubeY3 = 10'd0;
		end
		else if (cubeSpeed >= 50'd500000) begin
			cubeY3 = cubeY3 + 10'd1;
			if (cubeY3 >= 10'd515) cubeY3 = 10'd0;
		end

		if (cubeSpeed >= 50'd500000) 
			cubeSpeed = 50'd0;

		if (comboCount >= 16'd30) 
			multiplier = 4'd4;
		else if (comboCount >= 16'd20) 
			multiplier = 4'd3;
		else if (comboCount >= 16'd10) 
			multiplier = 4'd2;
		else                           
			multiplier = 4'd1;
	end

	assign whiteZone = ((hCount >= 10'd144) && (hCount <= 10'd784)) && ((vCount >= 10'd400) && (vCount <= 10'd475)) ? 1 : 0;
	// Dividing lines
	assign laneLine1 = (hCount >= 10'd304) && (hCount <= 10'd305);
	assign laneLine2 = (hCount >= 10'd464) && (hCount <= 10'd465);
	assign laneLine3 = (hCount >= 10'd624) && (hCount <= 10'd625);

	assign cube0 = (hCount >= 10'd204) && (hCount <= 10'd244) &&
               (vCount >= cubeY0)  && (vCount <= cubeY0 + 10'd40);
	assign cube1 = (hCount >= 10'd364) && (hCount <= 10'd404) &&
				(vCount >= cubeY1)  && (vCount <= cubeY1 + 10'd40);
	assign cube2 = (hCount >= 10'd524) && (hCount <= 10'd564) &&
				(vCount >= cubeY2)  && (vCount <= cubeY2 + 10'd40);
	assign cube3 = (hCount >= 10'd684) && (hCount <= 10'd724) &&
				(vCount >= cubeY3)  && (vCount <= cubeY3 + 10'd40);
	
endmodule
