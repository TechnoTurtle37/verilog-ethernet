# Read a logfile of DNS packets, 
# Log file is output from DNS parser 
#
# First line is: data and time, source IP, destination IP, dns_packet length, q or r for query or response, AA or NA for Authoritative or not authoritivive, number of queries?
# number of responses!, number of name servers $, number of additional data in packet+
# Next line begins with ? it is the query section of the packet, following depend on the data in packet ! is responses, $ names serves
#
# examples:
# 2023-04-06 10:52:16.118000,10.0.10.3,8.8.8.8,46,q,NA,1?,0!,0$,0+
# ? registrar.gatech.edu A
#
# 2023-04-06 10:52:16.121750,130.207.244.244,10.2.242.44,62,r,AA,1?,1!,0$,0+
# ? registrar.gatech.edu A
# ! registrar.gatech.edu A 130.207.188.44

with open("logfile.txt", "r") as f:
	lines = f.readlines()

# Dictionary to store dns reponses
# Maps a domain to a list containing 
# a List of host_IPs that quired it
# a list of its resolved IPv4s
# a list of its resolved IPv6s
# and a list of its CNAMEs
# Domain: host_IP_That_Queried_list, resolvedIPv4_list, resolvedIPv6_list, cname_list] 
dns_responses = {}

is_response = False

total_packets = 0
total_dns_packets = 0

for line in lines:
	if line[0] == '$':
		#move on
		continue
	elif line[0] == '?':
		#its the query part of the DNS packet
		
		#if it is a response
		if response:
			domain = line.split("? ")
			domain = domain[1]
			domain = domain.split(" ")
			domain = domain[0]

			if domain not in dns_responses:
				# dns_responses[domain] = [[hostIP], [], [], []]
				dns_responses[domain] = [[hostIP], set(), set(), set()]
			else:
				dns_responses[domain][0].append(hostIP)
		else:
			continue
	elif line[0] == '!':
		#if it is in the response part of DNS packet

		if "CNAME" in line:
			cname = line.split("CNAME ")
			cname = cname[1].strip()
			dns_responses[domain][3].add(cname)
		elif "PTR" in line:
			continue
		elif "AAAA" in line:
			ipv6 = line.split("A ")
			ipv6 = ipv6[1].strip()
			dns_responses[domain][2].add(ipv6)
		elif "A " in line:
			ipv4 = line.split("A ")
			ipv4 = ipv4[1].strip()
			dns_responses[domain][1].add(ipv4)

	elif line[:8] == "2023-04-" or line[:8] == "2018-03-":
		entry = line.split(",")

		query_or_response = entry[4]

		if query_or_response == 'r':
			response = True
			hostIP = entry[2]
		else:
			response = False

	# Stats per pcap file, add them to keep track of totals
	elif "Total packet" in line:
		number_of_packets = line.split(": ")
		number_of_packets = int(number_of_packets[1].strip())
		total_packets += number_of_packets
	elif "Total DNS Packets" in line:
		number_of_packets = line.split(": ")
		number_of_packets = int(number_of_packets[1].strip())
		total_dns_packets += number_of_packets
		

highest_AAAA = 0
highest_A = 0
highest_cname = 0
highest_requests = 0

for domain in dns_responses:
	hostSet = set(dns_responses[domain][0])
	resolvedIPv4set = dns_responses[domain][1]
	resolvedIPv6set = dns_responses[domain][2]
	cname = dns_responses[domain][3]

	number_of_requests = len(hostSet)
	number_of_A = len(resolvedIPv4set)
	number_of_AAAA = len(resolvedIPv6set)
	number_of_cnames = len(cname)

	print(f"{domain} was queried {len(dns_responses[domain][0])} times by {number_of_requests} unique Hosts: {', '.join(hostSet)}")
	print(f"{domain} Resolved to {number_of_A} unique IPv4 addresss: {', '.join(resolvedIPv4set)}")
	print(f"{domain} Resolved to {number_of_AAAA} unique IPv6 address: {', '.join(resolvedIPv6set)}")
	print(f"{domain} Had {number_of_cnames} unique CNAMEs: {', '.join(cname)}")
	print()

	if number_of_A > highest_A:
		highest_A = number_of_A
	if number_of_AAAA > highest_AAAA:
		highest_AAAA = number_of_AAAA
	if number_of_cnames > highest_cname:
		highest_cname = number_of_cnames
	if number_of_requests > highest_requests:
		highest_requests = number_of_requests


print(f"Highest IPV4 count: {highest_A}")
print(f"Highest IPV6 count: {highest_AAAA}")
print(f"Highest cname count: {highest_cname}")
print(f"Highest requests: {highest_requests}\n")

print(f"Total number of Packets: {total_packets}")
print(f"Total number of DNS Packets: {total_dns_packets}")