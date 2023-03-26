import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np
import ast

#file = open("./data.csv", "r")

class Visualizer:
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

    # Init is not working
    # def graph_init():
        # ax.invert_yaxis()
        # ax.set_xlabel("Number of queries")
        # ax.set_ylabel("Top 10 queried domains")
        # return bars 

    def update(self, i):
        self.ax.clear()
        new_data = self.fread()
        urls, counts = zip(*new_data)
        print(f"Updating plot with: {urls}\nWith the respective hits: {counts}")
        y_pos = np.arange(len(urls))
        bars = self.ax.barh(y_pos, counts)
        self.ax.invert_yaxis()
        self.ax.set_xlabel("Number of queries")
        self.ax.set_ylabel("Top 10 queried domains")
        self.ax.set_yticks(y_pos, labels=urls)
        return bars

    def start(self):
        self.fig, self.ax = plt.subplots()
        self.ani = animation.FuncAnimation(self.fig, self.update, frames=10, interval=500)
        plt.show()
        #file.close()