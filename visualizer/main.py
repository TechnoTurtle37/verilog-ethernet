import serial_reader as sr
import visualizer as vis
from threading import Thread

SERIAL_BAUDRATE = 115200
SERIAL_TIMEOUT = .1
SERIAL_PORT = 'COM8'
REFRESH_SECONDS = 5
PLOT_WIDTH = 10
WRITE_FILE = "./data.csv"

serial_reader = sr.SerialReader(SERIAL_BAUDRATE, SERIAL_TIMEOUT, SERIAL_PORT, REFRESH_SECONDS, PLOT_WIDTH, WRITE_FILE)
visualizer = vis.Visualizer(PLOT_WIDTH)

def startserial():
    serial_reader.start()

serial_thread = Thread(target=startserial)

serial_thread.start()

# Visualizer should start in main thread.
visualizer.start()