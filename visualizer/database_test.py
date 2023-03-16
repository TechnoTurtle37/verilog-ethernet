import database as db
import random
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.animation import FuncAnimation

urls = ["youtube.com", "google.com", "yahoo.com", "gatech.edu", "stackoverflow.com", "sparkfun.com", "w3schools.com", "outlook.com", "reddit.com", "linkedin.com", "twitter.com"]
db = db.Database(5, "./data.csv") # Should only display top 5 hits
# plt.rcdefaults()
# fig, ax = plt.subplots()

def simulator(msgs):
    for x in range(0, msgs):
        url = random.choice(urls)
        count = random.choice(range(0, 101))
        print(f"Adding ({url}, {count})")
        db.push(url, count)
        db.print()
        db.export()
    



# def update(i):

# def init_plot(data):
#     urls, counts = zip(*data)
#     y_pos = np.arange(len(urls))
#     ax.barh(y_pos, counts)
#     ax.set_yticks(y_pos, labels=urls)
#     ax.invert_yaxis()
#     ax.set_xlabel('Count')
#     ax.set_title('Top n queried urls')
#     plt.show()

simulator(10)
