import serial
import time
import database as db

# Object's purpose is to read in data in the form ("URL", "# OF QUERIES") and export it to the custom database class.
class SerialReader:
    def __init__(self, serial_baudrate=115200, serial_timeout=.1, serial_port="COM8", refresh_seconds=5, plot_width=10, write_file="./data.csv"):
        self.serial_baudrate = serial_baudrate
        self.serial_timeout= serial_timeout
        self.serial_port = serial_port
        self.refresh_seconds = refresh_seconds
        self.plot_width = plot_width
        self.write_file = write_file
        self.db = db.Database(self.plot_width, self.write_file)

    # Setup Serial Port to interface with a COM port.
    def setupSerial(self, port):
        print("Starting Serial...")
        ser = serial.Serial()
        ser.port = port
        ser.baudrate = self.serial_baudrate
        ser.timeout = self.serial_timeout
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

    # Begins reading from serial and exporting data to the custom database object.
    def start(self):
        print("Starting DNS Traffic Visualizer")
        ser = self.setupSerial(self.serial_port)

        while(True):
            # Assuming data read in is "url,count"
            # Converts to a tuple ("url", "count") and pushes to database object
            new_data_bytes = ser.readline()
            if not new_data_bytes:
                continue
            new_data_str = new_data_bytes.decode().strip()
            print(f"Serial: Reading {new_data_str}")
            new_data = new_data_str.split(", ")
            url = new_data[0]
            count = int(new_data[1])
            print(f"Adding ({url}, {count}) to database\n")
            self.db.push(url, count)
            self.db.export()
            time.sleep(self.refresh_seconds)

