module audio_rom (
    input wire [31:0] addr,
    output reg [11:0] data
);

    (* ram_style = "block" *) reg [11:0] mem [0:66150]; // adjust size to lines in .mem

    initial begin
        $readmemh("song.mem", mem);
    end

    always @(*) begin
        data = mem[addr];
    end

endmodule