import serial_reader as sr
import visualizer as vis
from threading import Thread

SERIAL_BAUDRATE = 115200    # Serial baudrate
SERIAL_TIMEOUT = .1         # Timeout while waiting for data on serial
SERIAL_PORT = 'COM8'        # The COM port to read serial from
REFRESH_SECONDS = 5         # The interval inwhich the visualizer updates
PLOT_WIDTH = 10             # How many results to plot (i.e. 10 = top 10 queried urls)
WRITE_FILE = "./data.csv"   # File used between writing from serial and reading from the visualizer

# Create the object that reads in from serial.
serial_reader = sr.SerialReader(SERIAL_BAUDRATE, SERIAL_TIMEOUT, SERIAL_PORT, REFRESH_SECONDS, PLOT_WIDTH, WRITE_FILE)

# Create the object that takes serial data and plots it.
visualizer = vis.Visualizer(PLOT_WIDTH)

def startserial():
    serial_reader.start()

# Create a secondary thread to read from serial.
serial_thread = Thread(target=startserial)

serial_thread.start()

# Visualizer should start in main thread.
visualizer.start()