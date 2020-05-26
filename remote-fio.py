import paramiko
from paramiko import client
import re, os
import time, threading

start = time.time()
class ssh:
    client = None

    def __init__(self, address, username, password):
        print("Connecting to server.")
        self.client = client.SSHClient()
        self.client.set_missing_host_key_policy(client.AutoAddPolicy())
        self.client.connect(address, username=username, password=password, look_for_keys=False)

    def sendCommand(self, command):
        if(self.client):
            stdin, stdout, stderr = self.client.exec_command(command)
            while not stdout.channel.exit_status_ready():
                # Print data when available
                if stdout.channel.recv_ready():
                    alldata = stdout.channel.recv(4096)
#                     alldata2 = stderr.channel.recv(3096)
                    prevdata = b"1"
#                     prevdata2 = b"1"
#                     alldata2 += prevdata2

                    while prevdata:
                        prevdata = stdout.channel.recv(4096)
#                         prevdata2 = stderr.channel.recv(3096)
                        alldata += prevdata
#                         alldata2 += prevdata2

                        x = (str(alldata, "utf8"))
                        print x
                        return x
                else:
#                      elif stdout.channel.recv_stderr_ready():
                    alldata = stderr.channel.recv_stderr(4096)
                    prevdata = b"1"

                    while prevdata:
                        prevdata = stdout.channel.recv(4096)
#                         prevdata2 = stderr.channel.recv(3096)
                        alldata += prevdata
#                         alldata2 += prevdata2

                        x = str(alldata).encode("utf8")
                        print x
                        return x

        else:
            print("Connection not opened.") 
list = []
def readip(filename):
    with open(filename) as f:
         lines = f.readlines()
    return lines
ip_list = readip('ip.txt')
print (ip_list)

#for y in ip_list:
#    connection = ssh(y , "root" , "password")
#    print ('Installing FIO on VMs , internet required in host')
#    connection.sendCommand("apt update")
#    time.sleep(5)
#    connection.sendCommand("apt install -y fio")
#    time.sleep(10)
#    connection.sendCommand("apt install -y fio")
#    time.sleep(10)


for x, i in zip (ip_list, range(1, 9)):
    connection = ssh(x , "root" , "password")
    transport = paramiko.Transport(x)
    transport.connect(username = "root", password = "password")
    sftp = paramiko.SFTPClient.from_transport(transport)
    print ('Copying FIO config file to VMs: fio_sriov.fio')
    sftp.put('NVMe_Performance.sh', '/root/NVMe_Performance.sh')

    print ("Starting FIO on all VMs")
    channel = transport.open_session()
    channel.exec_command("sh NVMe_Performance.sh -a VF" + str(i))
    print ("sh NVMe_Performance.sh -a VF" + str(i))
    print ("Waiting for FIO to finish")
time.sleep(108000)

rdirectory_charging_log = "/root/"
rfiles = sftp.listdir(rdirectory_charging_log)
directory_charging_log = "/root/output_sriov/"
for z, j in zip (ip_list, range(1, 9)):
    transport = paramiko.Transport(z)
    transport.connect(username = "root", password = "password")
    sftp = paramiko.SFTPClient.from_transport(transport)
    print ("Copy fio result files to local machine:")
    rfiles = sftp.listdir(rdirectory_charging_log)
    print (rfiles)
    #rfile = ""
    #rfiles = 
    for rfile in rfiles:
        if rfile.startswith('VF'):
            sftp.get("/root/" + rfile, os.path.join(directory_charging_log, rfile))    
    #sftp.get('/root/VF' + str(j).join(re.compile(.*)), '/root/output_sriov/VF' + str(j).join(re.compile(.*)))

    #connection.sendCommand("fio fio_sriov.fio --output-format=json --output=" + str(x) + ".json")
    #sftp.put('fio-3.19.tar.gz', '/root/fio-3.19.tar.gz')
    #gunzip_cmd = "gunzip fio-3.19.tar.gz"
    #connection.sendCommand(gunzip_cmd)
    #connection.sendCommand("tar -xf fio-3.19.tar")
    #connection.sendCommand("cd fio-3.19 && ./configure && make && make install")
print (time.time()- start)
