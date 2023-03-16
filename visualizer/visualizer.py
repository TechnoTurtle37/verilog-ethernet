import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib import style
import numpy as np

fig, ax = plt.subplots()
file = open("./data.csv", "r")

def fread():
    data = file.read()
    data.split(b'),')
    return data

def update(i):
    ax.clear()
    new_data = fread()
    urls, counts = zip(*new_data)
    bars = ax.barh(np.arange(len(urls)), counts)
    return bars

ani = animation.FuncAnimation(fig, update, frames=10, interval=500)
plt.show()
file.close()