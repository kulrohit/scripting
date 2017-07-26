ip1=$1
ip2=$2


python -c "import netaddr;  p_cidr = netaddr.iprange_to_cidrs('$ip1','$ip2'); print p_cidr"

