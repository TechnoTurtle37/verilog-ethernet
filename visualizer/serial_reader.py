import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np
import random
import serial
import time
import database as db

SERIAL_BAUDRATE = 115200
SERIAL_TIMEOUT = .1
SERIAL_PORT = 'COM4'
REFRESH_SECONDS = 5
PLOT_WIDTH = 10
WRITE_FILE = "./data.csv"

db = db.Database(PLOT_WIDTH, WRITE_FILE)

def setupSerial(port):
    # Setup Serial Port to interface with DE2-115
    print("Starting Serial...")
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = SERIAL_BAUDRATE
    ser.timeout = SERIAL_TIMEOUT
    try:
        ser.open()
    except Exception as err:
        print(f"Error: {err}")
        return
    if ser.is_open == True:
        print("Complete: Reading Network Data...")
        return ser
    else:
        print("Undefined: Serial Completed but is not Open")

def main():
    print("Starting DNS Traffic Visualizer")
    ser = setupSerial(SERIAL_PORT)

    while(True):
        # Assuming data read in is "url,count"
        new_data = ser.readline().split(b',')
        url = new_data[0]
        count = new_data[1]
        db.push(url, count)
        db.export()
        time.sleep(REFRESH_SECONDS)
    

if __name__ == "__main__":
    main()

