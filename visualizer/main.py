import serial_reader as sr
import visualizer as vis
from threading import Thread

serial_reader = sr.SerialReader()
visualizer = vis.Visualizer()

def startserial():
    serial_reader.start()

def startvisualizer():
    visualizer.start()

serial_thread = Thread(target=startserial)
visualizer_thread = Thread(target=startvisualizer)

serial_thread.start()
visualizer_thread.start()
