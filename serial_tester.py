import serial

WORD_SIZE = 4 # bytes

print("Starting Serial...")

ser = serial.Serial()
ser.port = "COM5"
ser.baudrate = 115200
ser.timeout = .1
try:
    ser.open()
except Exception as err:
    print(f"Error: {err}")
    if ser.is_open == True:
        print("Complete: Reading Network Data...")
    else:
        print("Undefined: Serial Completed but is not Open")

new_block = []

while(True):
    # while (True):
    #     if (new_block[-4:] == "1111"):
    #     # if stop condition = true
    #         break
    #     else:
    #     # else
    #         new_block.append(ser.read(1))
    
    # Will block until it reads 2047 * word_size bytes
    new_block = ser.read(2047 * WORD_SIZE)

    block_qname = new_block[0:(63 * WORD_SIZE)]
    flags = new_block[(64 * WORD_SIZE):(65 * WORD_SIZE - 1)]
    query_num = new_block[(65 * WORD_SIZE):(66 * WORD_SIZE - 1)]
    res_num = new_block[(66 * WORD_SIZE):(67 * WORD_SIZE - 1)]
    qhosts = new_block[(67 * WORD_SIZE):(68 * WORD_SIZE - 1)]
    rhosts_a = new_block[(68 * WORD_SIZE):(69 * WORD_SIZE - 1)]
    rhosts_aaaa = new_block[(69 * WORD_SIZE):(70 * WORD_SIZE - 1)]
    rhosts_cname = new_block[(70 * WORD_SIZE):(70 * WORD_SIZE + 3)]

    resolved_hosts_a = new_block[(128 * WORD_SIZE):(511 * WORD_SIZE)]
    resolved_hosts_aaaa = new_block[(512 * WORD_SIZE) : (767 * WORD_SIZE)]
    resolved_hosts_cname = new_block[(768 * WORD_SIZE) : (1023 * WORD_SIZE)]

    querying_host = new_block[(1024 * WORD_SIZE):(2047 * WORD_SIZE)]

    # example of parsing info
    #hardcode_name = bytes([0x06, 0x74, 0x65, 0x6e, 0x68, 0x6f, 0x75, 0x03, 0x6e, 0x65, 0x74, 0x00])
    #hardcode_ip_addr = bytes([0xa0, 0x10, 0x80, 0x1e])
    #temp = ".".join(str(x) for x in hardcode_ip_addr)

    #print(hardcode_name) prints \0x06tenhou\x03net\x00  <- to handle this, remove first byte (0x06), any future bytes that ARE NOT in alphabetical ascii range (i.e. 0x03) are converted to ".", and the last byte (0x00) is removed
    #print(temp)          prints 160.16.128.30

    print(f"QName: {block_qname}\n \
          Flags: {flags}\n \
          Query #: {query_num}\n \
          Res #: {res_num}\n \
          QHosts: {qhosts}\n \
          RHosts_a: {rhosts_a}\n \
          RHosts_aaaa: {rhosts_aaaa}\n \
          RHosts_cname: {rhosts_cname}\n \
          Resolved_Hosts_a: {resolved_hosts_a}\n \
          Resolved_Hosts_aaaa: {resolved_hosts_aaaa}\n \
          Resolved_Hosts_cname: {resolved_hosts_cname}\n \
          Querying_Host: {querying_host}\n")