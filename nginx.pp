# Define parameters for customization
class nginx (
  $server_blocks = [],
  $ssl_certificate = '',
  $ssl_key = '',
) {

  # Install the Nginx package
  package { 'nginx':
    ensure => 'installed',
  }

  # Manage the main Nginx configuration file
  file { '/etc/nginx/nginx.conf':
    ensure => 'file',
    source => 'puppet:///modules/nginx/nginx.conf',
    # Notify Nginx to reload when the configuration file changes
    notify => Service['nginx'],
  }

  # Ensure the Nginx service is running and enabled
  service { 'nginx':
    ensure  => 'running',
    enable  => true,
    require => Package['nginx'],
  }

  # Define a custom type for managing server blocks (virtual hosts)
  define nginx::server_block (
    $server_name,
    $root = '/var/www/html',
    $listen = 80,
  ) {
    # Manage individual server block configuration files
    file { "/etc/nginx/conf.d/${name}.conf":
      ensure  => 'file',
      content => template('nginx/server_block.erb'),
      # Notify Nginx to reload when the server block configuration changes
      notify  => Service['nginx'],
    }
  }

  # Manage server blocks (virtual hosts) if defined
  if $server_blocks {
    nginx::server_block { $server_blocks: }
  }

  # Manage SSL/TLS configuration if SSL certificate and key are provided
  if $ssl_certificate and $ssl_key {
    # Manage SSL certificate file
    file { '/etc/nginx/ssl/server.crt':
      ensure  => 'file',
      source  => $ssl_certificate,
      # Notify Nginx to reload when the SSL certificate changes
      notify  => Service['nginx'],
    }

    # Manage SSL private key file
    file { '/etc/nginx/ssl/server.key':
      ensure  => 'file',
      source  => $ssl_key,
      # Notify Nginx to reload when the SSL key changes
      notify  => Service['nginx'],
    }

    # Manage SSL/TLS configuration file
    file { '/etc/nginx/conf.d/ssl.conf':
      ensure  => 'file',
      source  => 'puppet:///modules/nginx/ssl.conf',
      # Notify Nginx to reload when the SSL configuration changes
      notify  => Service['nginx'],
    }
  }

  # Add log rotation configuration using the logrotate module
  class { 'logrotate':
    managecronjob => true,
  }

  # Define log rotation rules for Nginx logs
  logrotate::rule { 'nginx_logs':
    path        => '/var/log/nginx/*.log',
    rotate      => 7,
    missingok   => true,
    notifempty  => true,
    sharedscripts => true,
    postrotate  => 'nginx -s reload',
  }

  # Add additional modules and customizations here as needed.
}
