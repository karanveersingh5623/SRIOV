
import libvirt  # To connect to the hypervisor
import re
import subprocess
import xml.etree.ElementTree as ET
import random
import paramiko
import getpass


# Connect to your local hypervisor. See https://libvirt.org/uri.html
#    for different URI's where you'd replace `None` with your
#    connection URI (like `qemu://system`)
conn = libvirt.openReadOnly('qemu+ssh://root@195.167.137.76/system')  # Open the hypervisor in read-only mode
# conn = libvirt.open(None)  # Open the default hypervisor in read-write mode (require
if conn == None:
    raise Exception('Failed to open connection to the hypervisor')

try:  # getting a list of all domains (by ID) on the host
    domains = conn.listDomainsID()
    #print domains
except:
    raise Exception('Failed to find any domains')
ip_list = []
for domain_id in domains:
    # Open that vm
    vm = conn.lookupByID(domain_id)
    #uuid = vm.UUIDString()
    #print uuid
    xml = vm.XMLDesc(0)
    #print type(xml)
    #print type(vm.XMLDesc(0))
    
    # Grab the MAC Address from the XML definition
    #     using a regex, which may appear multiple times in the XML
    #root = ET.fromstring(xml)
    #print root
    #mac_addresses = 
    mac_addresses = re.findall(r"..:..:..:..:..:..", xml)
    #print mac_addresses
    for mac_address in mac_addresses:
        # Now, use subprocess to lookup that macaddress in the
        #      ARP tables of the host.
        ssh = paramiko.SSHClient()

        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        #p = getpass.getpass()

        ssh.connect('195.167.137.76', username='root', password='ubuntu123')
        stdin, stdout, stderr = ssh.exec_command('arp -a')
        process = stdout.readlines()
        ssh.close()
        #process = subprocess.Popen(['arp', '-a'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        #process.wait()  # Wait for it to finish with the command
        for line in process:
            #print line
            if mac_address in line:
                ip_address = re.findall(r'(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})', line)
                ip_list.append(ip_address[0])
                print ip_address[0]
                #print 'VM {0} with MAC Address {1} is using IP {2}'.format(
                #    vm.name(), mac_address, ip_address[0]
                #)
            else:
                pass
                #print 'Unknown IP Address from the ARP tables! Handle this somehow...'
                # Unknown IP Address from the ARP tables! Handle this somehow...
print ip_list
data = open("ip.txt", "w" )
for ip in ip_list:
    data.write(ip + '\n')
data.close()
print('data has been written')
