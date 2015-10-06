cat init.pp 
class ntp {
      
	package { 'ntp':
		ensure => installed,
  }
      
  service { 'ntp':
		name      => ntpd,
		ensure    => running,
    enable    => true,
  }

	file { 'ntp.conf':
    path    => '/etc/ntp.conf',
    recurse => true,
    ensure  => file,
    require => Package['ntp'],
    source  => 'puppet:///modules/ntp/ntp.conf',
		owner   => 'ntp',
    group   => 'ntp',
  }

	file { "/etc/ntp":
		ensure	=> directory,
    require => Package['ntp'],
    recurse => true, 
  	owner		=> "ntp",
  	group		=> "ntp",
	 }
}
