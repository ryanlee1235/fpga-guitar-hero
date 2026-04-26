import serial
import time
import math

s = serial.Serial('COM4', 115200)

# generate simple sine wave
for i in range(100000):
    sample = int(32767 * math.sin(2 * math.pi * i / 50))
    
    # convert to unsigned 16-bit
    sample = sample + 32768
    
    # send LSB first (important)
    s.write(sample.to_bytes(2, 'little'))