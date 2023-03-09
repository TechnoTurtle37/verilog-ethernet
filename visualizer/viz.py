import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np
import random
import serial
from scapy.all import *

# Begin Reading Incoming PCAP Data
"""
Psuedocode:
while True:
    If pcap on serial
        For dns-packet in packets:
            url <- dns-packet.url
            count <- urlCountHashMap[url] + 1

    Redraw graphs
"""

urlCount = dict() # Hashmap where URL -> Count

def checkData(pcap_file):
    """"""
    print("Checking for a new PCAP")
    # Check serial

    # Filter on DNS Traffic, is this necessary?
    # Isn't transferred data from the FPGA expected to only be DNS?
    packets = PcapReader(pcap_file)
    for packet in packets:
        # Scapy documentation :(. There Must be an easy way to extract domain names.
        print("Todo!")
    '''
    dns_packets = filter(lambda packet: packet[TCP].dport == 53, PcapReader(pcap_file))
    for packet in dns_packets:
        # pseudocode
            # grab packet url
            # countHashMap[url] = current value + 1
        print(packet)
    '''

def setupSerial(port):
    # Setup Serial Port to interface with DE2-115
    print("Starting Serial...")
    ser = serial.Serial()
    ser.port = port # Setup for Arduino simulations at the moment
    ser.baudrate = 115200
    ser.timeout = .1
    try:
        ser.open()
    except Exception as err:
        print(f"Error: {err}")
        return
    if ser.is_open == True:
        print("Complete: Reading Network Data...")
    else:
        print("Undefined: Serial Completed but is not Open")

def updateGraph():
    print("Todo!")

def main():
    print("Starting DNS Traffic Visualizer")
    setupSerial('COM4')
    checkData("./dns_2019_08.pcap")
    #while(True):

if __name__ == "__main__":
    main()

