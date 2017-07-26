ip1=$1
ip2=$2


python -c "import netaddr;  p_cidr = netaddr.iprange_to_cidrs('$ip1','$ip2'); print p_cidr"


cat ip.txt  | while read ip1 ip2; do   sh ip.sh $ip1 $ip2; done >> iprage_france.txt
