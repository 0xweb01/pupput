# Define parameters for customization
class httpd (
  $virtual_hosts = [],
  $ssl_certificate = '',
  $ssl_key = '',
) {

  # Install the Apache package
  package { 'httpd':
    provider => 'yum',
    ensure   => 'installed',
  }

  # Manage the main Apache configuration file
  file { '/etc/httpd/conf/httpd.conf':
    ensure  => 'file',
    source  => 'puppet:///modules/httpd/httpd1.conf',
    replace => true,
    notify  => Service['httpd'],
  }

  # Ensure the Apache service is running and enabled
  service { 'httpd':
    ensure  => 'running',
    enable  => true,
    require => Package['httpd'],
  }

  # Define a custom type for managing virtual hosts
  define httpd::virtual_host (
    $document_root = '/var/www/html',
    $port = 80,
  ) {
    # Manage individual virtual host configuration files
    file { "/etc/httpd/conf.d/${name}.conf":
      ensure  => 'file',
      content => template('httpd/virtual_host.erb'),
      notify  => Service['httpd'],
    }
  }

  # Manage virtual hosts if defined
  if $virtual_hosts {
    httpd::virtual_host { $virtual_hosts: }
  }

  # Manage SSL/TLS configuration if SSL certificate and key are provided
  if $ssl_certificate and $ssl_key {
    # Manage SSL certificate file
    file { '/etc/httpd/conf/ssl.crt/server.crt':
      ensure  => 'file',
      source  => $ssl_certificate,
      notify  => Service['httpd'],
    }

    # Manage SSL private key file
    file { '/etc/httpd/conf/ssl.key/server.key':
      ensure  => 'file',
      source  => $ssl_key,
      notify  => Service['httpd'],
    }

    # Manage SSL/TLS configuration file
    file { '/etc/httpd/conf.d/ssl.conf':
      ensure  => 'file',
      source  => 'puppet:///modules/httpd/ssl.conf',
      notify  => Service['httpd'],
    }
  }

  # Add log rotation configuration using the logrotate module
  class { 'logrotate':
    managecronjob => true,
  }

  # Define log rotation rules for Apache logs
  logrotate::rule { 'httpd_logs':
    path        => '/var/log/httpd/*.log',
    rotate      => 7,
    missingok   => true,
    notifempty  => true,
    sharedscripts => true,
    postrotate  => 'systemctl reload httpd',
  }

  # Add additional modules and customizations here as needed.
}
