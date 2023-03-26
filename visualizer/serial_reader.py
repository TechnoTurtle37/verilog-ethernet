import serial
import time
import database as db

SERIAL_BAUDRATE = 115200
SERIAL_TIMEOUT = .1
SERIAL_PORT = 'COM8'
REFRESH_SECONDS = 5
PLOT_WIDTH = 10
WRITE_FILE = "./data.csv"

db = db.Database(PLOT_WIDTH, WRITE_FILE)

class SerialReader:
    def setupSerial(self, port):
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

    def start(self):
        print("Starting DNS Traffic Visualizer")
        ser = self.setupSerial(SERIAL_PORT)

        while(True):
            # Assuming data read in is "url,count"
            new_data_bytes = ser.readline()
            if not new_data_bytes:
                continue
            new_data_str = new_data_bytes.decode().strip()
            print(f"Serial: Reading {new_data_str}")
            new_data = new_data_str.split(", ")
            url = new_data[0]
            count = int(new_data[1])
            print(f"Adding ({url}, {count}) to database\n")
            db.push(url, count)
            db.export()
            time.sleep(REFRESH_SECONDS)

