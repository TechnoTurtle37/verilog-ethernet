class Database:
    def __init__(self, top_n_width, file):
        self.top_n_width = top_n_width # The amount of most queried urls stored in the most_accessed list at once.
        self.dns_dict = dict() # A dictionary containing all queried urls as keys and their query count as the value.
        self.most_accessed = [] # A sorted list of tuples containing the top queried urls and their associated query count.
        self.bottom_top_n = 0 # The query count of the lowest queried url in the most_accessed list.
        self.file_name = file

    # def __del__(self):
    #     self.file.close()
    
    def push(self, url, count):
        # Check if the new url has a greater number of hits than the lowest queried url in the top n list.
        if count > self.bottom_top_n or len(self.most_accessed) <= self.top_n_width:
            # Check if this specific url is already in the top n list.
            if any(url in tup for tup in self.most_accessed for el in tup):
                # Re-insert the specific url and re-sort the top n queried urls
                for tup in self.most_accessed:
                    if tup[0] == url:
                        self.most_accessed.remove(tup)

                self.most_accessed.append((url, count))

                self.most_accessed.sort(key=lambda sortby: sortby[1], reverse=True) # Sort the array based off of count

                # Update bottom_top_n to lowest hit url count in the top n list
                self.bottom_top_n = self.most_accessed[-1][1]
            else:
                # Add the new url to most_accessed, sort most_accessed, and remove the bottom most queried url of the top n queried urls (if the size of the list is equal or greater than top_n_width)
                self.most_accessed.append((url, count))

                self.most_accessed.sort(key=lambda sortby: sortby[1], reverse=True)

                if len(self.most_accessed) > self.top_n_width:
                    del self.most_accessed[-1]

                self.bottom_top_n = self.most_accessed[-1][1]

    # Export the most accessed urls and there count to be used for plotting
    def export(self):
        file = open(self.file_name, "w")
        file.seek(0)
        file.truncate()
        file.write(str(self.most_accessed).strip('[]').replace("),", ");"))
        file.close()
    
    # Debug
    def print(self):
        print(f"Top {self.top_n_width} Queried URLs:\n")
        for i, item in enumerate(self.most_accessed):
            print(f"{i}| {item[0]} : {item[1]}\n")
        