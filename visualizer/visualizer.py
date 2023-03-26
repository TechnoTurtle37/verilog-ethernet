import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np
import ast

fig, ax = plt.subplots()
#file = open("./data.csv", "r")

def fread():
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

def update(i):
    ax.clear()
    new_data = fread()
    urls, counts = zip(*new_data)
    print(f"Updating plot with: {urls}\nWith the respective hits: {counts}")
    y_pos = np.arange(len(urls))
    bars = ax.barh(y_pos, counts)
    ax.invert_yaxis()
    ax.set_xlabel("Number of queries")
    ax.set_ylabel("Top 10 queried domains")
    ax.set_yticks(y_pos, labels=urls)
    return bars

ani = animation.FuncAnimation(fig, update, frames=10, interval=500)
plt.show()
#file.close()