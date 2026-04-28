`timescale 1ns / 1ps

module vga_bitchange(
    input clk,
    input reset,
    input bright,
    input game_start,
    input btnL, btnD, btnU, btnR,
    input [9:0] hCount, vCount,
    output reg [11:0] rgb,
    output reg [15:0] score,
    output reg [15:0] comboCount,
    output reg [3:0] multiplier,
    output reg [3:0] missCount,
    output reg gameOver,
    output game_running_dbg
);

    assign game_running_dbg = game_running;

    parameter BLACK = 12'b0000_0000_0000;
    parameter WHITE = 12'b1111_1111_1111;
    parameter RED   = 12'b1111_0000_0000;
    parameter GREEN = 12'b0000_1111_0000;
	parameter BLUE  = 12'b0000_0000_1111;
    parameter YELLOW = 12'b1111_1111_0000;

    parameter FALL_TIME_MS = 2000;
    parameter WHITE_ZONE_Y = 400;
	parameter NOTE_HEIGHT = 40;
    parameter SCREEN_BOTTOM = 515;
    parameter MS_DIVIDER = 100000;
    parameter NOTE_COUNT = 420;

    // game timer
    reg [31:0] game_time_ms;
	reg [16:0] ms_counter;
    reg game_running;

    always @(posedge clk) begin
        if (reset) begin
            game_time_ms <= 0;
            ms_counter <= 0;
            game_running <= 0;
        end else begin
            if (gameOver)
                game_running <= 0;
            else if (game_start) begin
                // switch ON = game runs
                if (!game_running) begin
                    game_time_ms <= 0;
                    ms_counter <= 0;
                end
                game_running <= 1;
            end else begin
                game_running <= 0;
            end

            if (game_running) begin
                if (ms_counter >= MS_DIVIDER - 1) begin
                    ms_counter <= 0;
                    game_time_ms <= game_time_ms + 1;
                end 
				else
                    ms_counter <= ms_counter + 1;
            end
        end
    end

    // note ROM
    reg [10:0] rom_addr;
    wire [23:0] rom_time_ms;
    wire [1:0] rom_lane;

    note_rom rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .time_ms(rom_time_ms),
        .lane(rom_lane)
    );

    // 4 notes per lane
    reg [9:0] lane0_y [0:3];
    reg [9:0] lane1_y [0:3];
    reg [9:0] lane2_y [0:3];
    reg [9:0] lane3_y [0:3];
    reg [3:0] lane0_active, lane1_active, lane2_active, lane3_active;

    reg [10:0] next_note_idx;
    wire [31:0] spawn_time;
    assign spawn_time = (rom_time_ms >= FALL_TIME_MS) ? (rom_time_ms - FALL_TIME_MS) : 0;

    // movement tick(1 pixel per 5ms)
    reg [19:0] move_counter;
    wire move_tick = (move_counter >= 499999);

    always @(posedge clk) begin
        if (reset || !game_running)
            move_counter <= 0;
        else if (move_tick)
            move_counter <= 0;
        else
            move_counter <= move_counter + 1;
    end

    // find free slot
    function [2:0] find_free_slot;
        input [3:0] active;
        begin
            if (!active[0]) find_free_slot = 0;
            else if (!active[1]) find_free_slot = 1;
            else if (!active[2]) find_free_slot = 2;
            else if (!active[3]) find_free_slot = 3;
            else find_free_slot = 4;
        end
    endfunction

    // find hittable note in white zone
    function [2:0] find_hittable;
        input [3:0] active;
        input [9:0] y0, y1, y2, y3;
        reg [2:0] best;
        reg [9:0] best_y;
        begin
            best = 4;
            best_y = 0;
            if (active[0] && y0 >= WHITE_ZONE_Y && y0 <= WHITE_ZONE_Y + 35 && y0 > best_y) begin
                best = 0;
                best_y = y0;
            end
            if (active[1] && y1 >= WHITE_ZONE_Y && y1 <= WHITE_ZONE_Y + 35 && y1 > best_y) begin
                best = 1;
                best_y = y1;
            end
            if (active[2] && y2 >= WHITE_ZONE_Y && y2 <= WHITE_ZONE_Y + 35 && y2 > best_y) begin
                best = 2;
                best_y = y2;
            end
            if (active[3] && y3 >= WHITE_ZONE_Y && y3 <= WHITE_ZONE_Y + 35 && y3 > best_y) begin
                best = 3;
                best_y = y3;
            end
            find_hittable = best;
        end
    endfunction

    reg [2:0] free_slot, hit_slot;
    reg prev_btnL, prev_btnD, prev_btnU, prev_btnR;
    wire btnL_press = btnL && !prev_btnL;
    wire btnD_press = btnD && !prev_btnD;
    wire btnU_press = btnU && !prev_btnU;
    wire btnR_press = btnR && !prev_btnR;

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            prev_btnL <= 0;
            prev_btnD <= 0;
            prev_btnU <= 0;
            prev_btnR <= 0;
            rom_addr <= 0;
            next_note_idx <= 0;
            lane0_active <= 0;
            lane1_active <= 0;
            lane2_active <= 0;
            lane3_active <= 0;
            score <= 0;
            comboCount <= 0;
            multiplier <= 1;
            missCount <= 0;
            gameOver <= 0;
        end else begin
            prev_btnL <= btnL;
            prev_btnD <= btnD;
            prev_btnU <= btnU;
            prev_btnR <= btnR;
            rom_addr <= next_note_idx;

            if (!game_running && !gameOver) begin
                next_note_idx <= 0;
                lane0_active <= 0;
                lane1_active <= 0;
                lane2_active <= 0;
                lane3_active <= 0;
                score <= 0;
                comboCount <= 0;
                multiplier <= 1;
                missCount <= 0;
            end else if (!gameOver) begin

                // spawn notes
                if (next_note_idx < NOTE_COUNT && game_time_ms >= spawn_time) begin
                    case (rom_lane)
                        0: begin
                            free_slot = find_free_slot(lane0_active);
                            if (free_slot < 4) begin
                                lane0_y[free_slot] <= 0;
                                lane0_active[free_slot] <= 1;
                                next_note_idx <= next_note_idx + 1;
                            end
                        end
                        1: begin
                            free_slot = find_free_slot(lane1_active);
                            if (free_slot < 4) begin
                                lane1_y[free_slot] <= 0;
                                lane1_active[free_slot] <= 1;
                                next_note_idx <= next_note_idx + 1;
                            end
                        end
                        2: begin
                            free_slot = find_free_slot(lane2_active);
                            if (free_slot < 4) begin
                                lane2_y[free_slot] <= 0;
                                lane2_active[free_slot] <= 1;
                                next_note_idx <= next_note_idx + 1;
                            end
                        end
                        3: begin
                            free_slot = find_free_slot(lane3_active);
                            if (free_slot < 4) begin
                                lane3_y[free_slot] <= 0;
                                lane3_active[free_slot] <= 1;
                                next_note_idx <= next_note_idx + 1;
                            end
                        end
                    endcase
                end

                // move notes
                if (move_tick) begin
                    for (i = 0; i < 4; i = i + 1) begin
                        if (lane0_active[i]) begin
                            if (lane0_y[i] >= SCREEN_BOTTOM) begin
                                lane0_active[i] <= 0;
                                comboCount <= 0;
                                missCount <= missCount + 1;
                            end 
							else
                                lane0_y[i] <= lane0_y[i] + 1;
                        end
                        if (lane1_active[i]) begin
                            if (lane1_y[i] >= SCREEN_BOTTOM) begin
                                lane1_active[i] <= 0;
                                comboCount <= 0;
                                missCount <= missCount + 1;
                            end 
							else
                                lane1_y[i] <= lane1_y[i] + 1;
                        end
                        if (lane2_active[i]) begin
                            if (lane2_y[i] >= SCREEN_BOTTOM) begin
                                lane2_active[i] <= 0;
                                comboCount <= 0;
                                missCount <= missCount + 1;
                            end 
							else
                                lane2_y[i] <= lane2_y[i] + 1;
                        end
                        if (lane3_active[i]) begin
                            if (lane3_y[i] >= SCREEN_BOTTOM) begin
                                lane3_active[i] <= 0;
                                comboCount <= 0;
                                missCount <= missCount + 1;
                            end 
							else
                                lane3_y[i] <= lane3_y[i] + 1;
                        end
                    end
                end

                // hit detection
                if (btnL_press) begin
                    hit_slot = find_hittable(lane0_active, lane0_y[0], lane0_y[1], lane0_y[2], lane0_y[3]);
                    if (hit_slot < 4) begin
                        lane0_active[hit_slot] <= 0;
                        score <= score + multiplier;
                        comboCount <= comboCount + 1;
                    end else begin
                        comboCount <= 0;
                        missCount <= missCount + 1;
                    end
                end
                if (btnD_press) begin
                    hit_slot = find_hittable(lane1_active, lane1_y[0], lane1_y[1], lane1_y[2], lane1_y[3]);
                    if (hit_slot < 4) begin
                        lane1_active[hit_slot] <= 0;
                        score <= score + multiplier;
                        comboCount <= comboCount + 1;
                    end else begin
                        comboCount <= 0;
                        missCount <= missCount + 1;
                    end
                end
                if (btnU_press) begin
                    hit_slot = find_hittable(lane2_active, lane2_y[0], lane2_y[1], lane2_y[2], lane2_y[3]);
                    if (hit_slot < 4) begin
                        lane2_active[hit_slot] <= 0;
                        score <= score + multiplier;
                        comboCount <= comboCount + 1;
                    end else begin
                        comboCount <= 0;
                        missCount <= missCount + 1;
                    end
                end
                if (btnR_press) begin
                    hit_slot = find_hittable(lane3_active, lane3_y[0], lane3_y[1], lane3_y[2], lane3_y[3]);
                    if (hit_slot < 4) begin
                        lane3_active[hit_slot] <= 0;
                        score <= score + multiplier;
                        comboCount <= comboCount + 1;
                    end else begin
                        comboCount <= 0;
                        missCount <= missCount + 1;
                    end
                end

                // multiplier
                if (comboCount >= 30) multiplier <= 4;
                else if (comboCount >= 20) multiplier <= 3;
                else if (comboCount >= 10) multiplier <= 2;
                else multiplier <= 1;

                if (missCount >= 10) gameOver <= 1;
            end
        end
    end

    // rendering
    wire whiteZone = (hCount >= 144) && (hCount <= 784) && (vCount >= WHITE_ZONE_Y) && (vCount <= WHITE_ZONE_Y + 75);
    wire laneLine1 = (hCount >= 304) && (hCount <= 305);
    wire laneLine2 = (hCount >= 464) && (hCount <= 465);
    wire laneLine3 = (hCount >= 624) && (hCount <= 625);

    wire in_l0 = (lane0_active[0] && hCount >= 204 && hCount <= 244 && vCount >= lane0_y[0] && vCount <= lane0_y[0] + NOTE_HEIGHT) ||
                 (lane0_active[1] && hCount >= 204 && hCount <= 244 && vCount >= lane0_y[1] && vCount <= lane0_y[1] + NOTE_HEIGHT) ||
                 (lane0_active[2] && hCount >= 204 && hCount <= 244 && vCount >= lane0_y[2] && vCount <= lane0_y[2] + NOTE_HEIGHT) ||
                 (lane0_active[3] && hCount >= 204 && hCount <= 244 && vCount >= lane0_y[3] && vCount <= lane0_y[3] + NOTE_HEIGHT);

    wire in_l1 = (lane1_active[0] && hCount >= 364 && hCount <= 404 && vCount >= lane1_y[0] && vCount <= lane1_y[0] + NOTE_HEIGHT) ||
                 (lane1_active[1] && hCount >= 364 && hCount <= 404 && vCount >= lane1_y[1] && vCount <= lane1_y[1] + NOTE_HEIGHT) ||
                 (lane1_active[2] && hCount >= 364 && hCount <= 404 && vCount >= lane1_y[2] && vCount <= lane1_y[2] + NOTE_HEIGHT) ||
                 (lane1_active[3] && hCount >= 364 && hCount <= 404 && vCount >= lane1_y[3] && vCount <= lane1_y[3] + NOTE_HEIGHT);

    wire in_l2 = (lane2_active[0] && hCount >= 524 && hCount <= 564 && vCount >= lane2_y[0] && vCount <= lane2_y[0] + NOTE_HEIGHT) ||
                 (lane2_active[1] && hCount >= 524 && hCount <= 564 && vCount >= lane2_y[1] && vCount <= lane2_y[1] + NOTE_HEIGHT) ||
                 (lane2_active[2] && hCount >= 524 && hCount <= 564 && vCount >= lane2_y[2] && vCount <= lane2_y[2] + NOTE_HEIGHT) ||
                 (lane2_active[3] && hCount >= 524 && hCount <= 564 && vCount >= lane2_y[3] && vCount <= lane2_y[3] + NOTE_HEIGHT);

    wire in_l3 = (lane3_active[0] && hCount >= 684 && hCount <= 724 && vCount >= lane3_y[0] && vCount <= lane3_y[0] + NOTE_HEIGHT) ||
                 (lane3_active[1] && hCount >= 684 && hCount <= 724 && vCount >= lane3_y[1] && vCount <= lane3_y[1] + NOTE_HEIGHT) ||
                 (lane3_active[2] && hCount >= 684 && hCount <= 724 && vCount >= lane3_y[2] && vCount <= lane3_y[2] + NOTE_HEIGHT) ||
                 (lane3_active[3] && hCount >= 684 && hCount <= 724 && vCount >= lane3_y[3] && vCount <= lane3_y[3] + NOTE_HEIGHT);

    always @(*) begin
        if (~bright) rgb = BLACK;
        else if (gameOver) rgb = RED;
        else if (in_l0) rgb = GREEN;
        else if (in_l1) rgb = RED;
        else if (in_l2) rgb = YELLOW;
        else if (in_l3) rgb = BLUE;
        else if (laneLine1 || laneLine2 || laneLine3) rgb = WHITE;
        else if (whiteZone) rgb = WHITE;
        else rgb = BLACK;
    end

endmodule
