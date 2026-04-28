#!/usr/bin/env python3
# converts MIDI guitar track to Verilog ROM

import mido

midi_path = "../ABBA - Dancing Queen (Naonemeu, Nero149)/notes.mid"
mid = mido.MidiFile(midi_path)

# expert difficulty notes 96-100
note_range = range(96, 101)
base_note = 96

# find guitar track
guitar_track = None
for track in mid.tracks:
    if 'GUITAR' in track.name.upper():
        guitar_track = track
        break

ticks_per_beat = mid.ticks_per_beat
tempo = 500000
current_time = 0
notes = []

for msg in guitar_track:
    current_time += msg.time
    if msg.type == 'set_tempo':
        tempo = msg.tempo
    if msg.type == 'note_on' and msg.velocity > 0 and msg.note in note_range:
        time_ms = int(mido.tick2second(current_time, ticks_per_beat, tempo) * 1000)
        lane = msg.note - base_note
        if lane <= 3:  # skip orange (no 5th button)
            notes.append((time_ms, lane))

notes.sort(key=lambda x: x[0])

# write verilog
with open("note_rom.v", 'w') as f:
    f.write("`timescale 1ns / 1ps\n\n")
    f.write("// note ROM - Dancing Queen (420 notes)\n")
    f.write("// lane: 0=Green, 1=Red, 2=Yellow, 3=Blue\n")
    f.write("module note_rom (\n")
    f.write("    input wire clk,\n")
    f.write("    input wire [10:0] addr,\n")
    f.write("    output reg [23:0] time_ms,\n")
    f.write("    output reg [1:0] lane\n")
    f.write(");\n")
    f.write("    always @(posedge clk) begin\n")
    f.write("        case (addr)\n")
    for i, (t, l) in enumerate(notes):
        f.write(f"            11'd{i}: begin time_ms <= 24'd{t}; lane <= 2'd{l}; end\n")
    f.write(f"            default: begin time_ms <= 24'd16777215; lane <= 2'd0; end\n")
    f.write("        endcase\n")
    f.write("    end\n")
    f.write("endmodule\n")

print(f"generated note_rom.v with {len(notes)} notes")
