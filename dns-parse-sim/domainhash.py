# Python script used to see if the hash map implementation on the FPGA will hold all the domains
# The hash map will store the last 11 bits of the hash of a domain from the PCAP files
# And have 8 for each hash
# This code will take the last 11 bits of a hash and check if any 8 domains have the same last bits of the hash
# If this code produces no matches then then the hash map can store all the domain 

import hashlib
from collections import defaultdict

# Number of collisions to test
num_collisions = 8

# Take the domain from both the query section and from the CNAMEs
def extract_domain(line):
    if line.startswith('?'):
        return line.split("? ")[1].split()[0]
    return None

# Calculate the least significant bits from the hash of the domain
def calculate_domain_lsb(domain):
    # # Sha1 hash for domains, take last 11 bits and return it has the hash
    # domain_hash = hashlib.sha1(domain.encode("UTF-8")).digest()
    # domain_lsb_as_int = int.from_bytes(domain_hash, byteorder='big') & ((1 << 11) - 1)
    # return domain_lsb_as_int

    # The domain in the pcap file does not have periods, periods are actually seperations for each label
    # But to know the size of each label, a size of label byte is in front of the ascii text for the label
    # Example: google.com in the the pcap file is 06 676f6f676c65 03 636f6d0a
    # the 06 is denoting how many characters is in the first label ie how many characters is in "google" which is 6
    # 676f6f676c65 is the ascii representation of "google"
    # 03 is how many characters in "com"
    # 636f6d0a is the ascii representation of "com"
    #
    #
    # Since in the log file the domains are actually in the form of "google.com"
    # Seperate the domain with "." as the delimiter to get each label individually
    domainparts = domain.split(".")
    
    # Int array that will represent the domain as it looks like in the pcap file
    # With each element as a byte containing either the size or character values
    #
    #
    # For example google.com is 06 676f6f676c65 03 636f6d0a in the pcap file
    # So the array would look like
    # [0x06, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x03, 0x63, 0x6f, 0x6d, 0x0a]
    domainarray = []
    for part in domainparts:
        domainarray.append(len(part))
        for c in part.encode("UTF-8"):
            domainarray.append(c)

    # SDBM hash
    # Take the sdbm hash of each domain
    # The 
    hash = 0
    for c in domainarray:
        hash = c + (hash << 6) + (hash << 16) - hash

    # SDBM hash is in 32 bits
    # hash = hash & 0xffffffff
    # # Printing for Debugging Information
    # print(f"Domain: {domain}")
    # hex_values = [hex(num)[2:].zfill(2) for num in domainarray]  # convert to hex and pad with 0 if needed
    # domain_as_Hex = ''.join(hex_values) # join the hex values into a single string
    # print(f"Hex representation: {domain_as_Hex}")
    # print(f"Int array: {domainarray}")
    # print(f"Domain: {domain}, and its hash: {hex(hash)}\n")

    # Take the last 11 bits of the sdbm hash since
    # in the FPGA only 11 bits of the hash can be stored as a memory saving measure
    hash = hash & 0x7ff

    return hash

# Read all the domains (includes CNMAMES) from the log file and store them in a list
with open("logfile.txt", "r") as f:
    domains_list = {extract_domain(line) for line in f if extract_domain(line)}

# Maps a each domain to its hash
domain_lsb_mapping = {domain: calculate_domain_lsb(domain) for domain in domains_list}

# An inverse of the dictionary, this will map all the hashes to a list of every domain that hashes to it
domain_dict = defaultdict(list)
for domain, lsb in domain_lsb_mapping.items():
    domain_dict[lsb].append(domain)

# A list of tuples of hashes that have at least num_collisions domains that hash to it and its domains
collisions = [(lsb, domains) for lsb, domains in domain_dict.items() if len(domains) >= num_collisions]

# If there are any hashes with more at least num_collisions domains, print them out
if len(collisions) > 0 :

    print("COLLISIONS FOUND\n")

    table_rows = [(i, f"{lsb}", ", ".join(domains)) for i, (lsb, domains) in enumerate(collisions, 1)]

    for row in table_rows:
        print(f"{row[0]}) LSB: {row[1]}, domains: {row[2]}\n")


print(f"Matching Hashes: {len(collisions)} out of {len(domains_list)} domains")