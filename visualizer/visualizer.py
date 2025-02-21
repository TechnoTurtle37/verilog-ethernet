import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np
import ast


class Visualizer:
    def __init__(self, plot_width=10):
        self.plot_width = plot_width

    # Reads in url and number of queries so that it can plot this data in real time.
    def fread(self):
        file = open("./data.csv", "r")
        data = file.readline()
        print(f"Data during read: {data}")
        data = data.split("; ")
        print(f"Data after split: {data}")
        data_formatted = []
        print(f"Data: {data}")
        for info in data:
            print(f"Formatting: {info}")
            data_formatted.append(ast.literal_eval(info))
        print(type(data_formatted))
        print(data_formatted)
        file.close()
        return data_formatted

    # Updates plot in real time with new data.
    def update(self, i):
        self.ax.clear()
        new_data = self.fread()
        urls, counts = zip(*new_data)
        print(f"Updating plot with: {urls}\nWith the respective hits: {counts}")
        y_pos = np.arange(len(urls))
        bars = self.ax.barh(y_pos, counts)
        self.ax.invert_yaxis()
        self.ax.set_xlabel("Number of queries")
        self.ax.set_ylabel(f"Top {self.plot_width} queried domains")
        self.ax.set_yticks(y_pos, labels=urls)
        return bars

    # Begin the animated plot using matplotlib's FuncAnimation function.
    def start(self):
        self.fig, self.ax = plt.subplots()
        self.ani = animation.FuncAnimation(self.fig, self.update, frames=10, interval=500)
        plt.show()