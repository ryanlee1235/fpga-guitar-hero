# audio_conversion_mem.py

import subprocess
import sys
import os
import tempfile

def convert_opus_to_mem(input_file, output_file,
                        start_sec=0,
                        duration_sec=3,
                        sample_rate=22050,
                        bits=12
                        ):

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found")
        return

    tmp_raw = tempfile.NamedTemporaryFile(delete=False)
    tmp_raw.close()

    cmd = [
        "ffmpeg",
        "-y",
        "-ss", str(start_sec),     # 🔥 START OFFSET
        "-i", input_file,
        "-t", str(duration_sec),   # 🔥 DURATION
        "-ar", str(sample_rate),
        "-ac", "1",
        "-f", "s16le",
        tmp_raw.name
    ]

    print("Running ffmpeg...")
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        print("FFmpeg failed.")
        return

    print("Converting to .mem format...")

    max_val = (1 << bits) - 1

    with open(tmp_raw.name, "rb") as f_in, open(output_file, "w") as f_out:
        while True:
            bytes_read = f_in.read(2)
            if not bytes_read:
                break

            sample = int.from_bytes(bytes_read, 'little', signed=True)

            # signed → unsigned
            sample = sample + 32768

            # scale to N bits
            sample = sample >> (16 - bits)

            sample = max(0, min(sample, max_val))

            f_out.write(f"{sample:0{bits//4}x}\n")

    os.remove(tmp_raw.name)

    print(f"Done! Output: {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python opus_to_mem.py input.opus output.mem [start_sec] [duration_sec]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    start_sec = 0
    duration_sec = 3

    if len(sys.argv) >= 4:
        start_sec = float(sys.argv[3])

    if len(sys.argv) >= 5:
        duration_sec = float(sys.argv[4])

    convert_opus_to_mem(
        input_file,
        output_file,
        start_sec=start_sec,
        duration_sec=duration_sec
    )