import serial, time
s = serial.Serial('COM4', 115200)

while True:
    s.write(b'A')
    time.sleep(0.01)