import sys
from netaddr import IPNetwork


with open ('your file containing CIDR records') as f:
	ipList = [ ipNtw.strip('\n') for ipNtw in f.readlines() ] 

#print ipList

for ipcidr in ipList:
	for ip in IPNetwork(ipcidr):
		print '%s' % ip

