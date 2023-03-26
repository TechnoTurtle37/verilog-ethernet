import serial_reader as sr
import visualizer as vis
from threading import Thread

serial_reader = sr.SerialReader()
visualizer = vis.Visualizer()

def startserial():
    serial_reader.start()

serial_thread = Thread(target=startserial)

serial_thread.start()

# Visualizer should start in main thread.
visualizer.start()