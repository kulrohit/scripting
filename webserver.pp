##Puppetmasterless manifest for testing 

node default {
        notify { "Testing puppet module":}  #just a message 
        package { 'httpd':
                ensure => installed,}  # install httpd 
        file { '/etc/httpd/conf/httpd.conf':
                ensure  => present,
                require => Package['httpd'],
                source  => '/root/masterless_puppet/httpd.conf',
                notify  => Service['httpd'],   # this will create relationship and restart httpd if httpd.conf is modified
                owner   => 'root',
                group   => 'root',
  } 
        service { 'httpd':
                ensure    => running,
                require => file['/etc/httpd/conf/httpd.conf'],
                 enable    => true,
  }

        }
