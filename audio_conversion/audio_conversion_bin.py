# audio_conversion_bin.py

import subprocess
import sys
import os

def convert_opus_to_bin(input_file, output_file,
                        start_sec=0,
                        duration_sec=None,
                        sample_rate=22050):

    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found")
        return

    cmd = [
        "ffmpeg",
        "-y",
        "-ss", str(start_sec),
        "-i", input_file,
        "-ar", str(sample_rate),
        "-ac", "1",
        "-f", "s16le",
    ]

    if duration_sec is not None:
        cmd.extend(["-t", str(duration_sec)])

    cmd.append(output_file)

    print("Running ffmpeg → writing .bin directly...")

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError:
        print("FFmpeg failed.")
        return

    print(f"Done! Output: {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python audio_conversion_bin.py input.opus output.bin [start_sec] [duration_sec]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    start_sec = float(sys.argv[3]) if len(sys.argv) >= 4 else 0
    duration_sec = float(sys.argv[4]) if len(sys.argv) >= 5 else None

    convert_opus_to_bin(input_file, output_file, start_sec, duration_sec)