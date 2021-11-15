# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include etcd::service
class etcd::service (
  Stdlib::Absolutepath $etcd_bin          = '/usr/bin/etcd',
  String[1] $user                         = 'etcd',
  Stdlib::Absolutepath $working_directory = '/var/lib/etcd',
  Optional[String[1]] $etcd_name          = undef,
  Integer $max_open_files                 = 40000,
) {

  systemd::unit_file { 'etcd.service':
    content => epp('etcd/etcd.service.epp', {
      user              => $user,
      etcd_bin          => $etcd_bin,
      working_directory => $working_directory,
      max_open_files    => $max_open_files,
      etcd_name         => $etcd_name,
    }),
  }

  if versioncmp($facts['puppetversion'],'6.1.0') < 0 {
    # Puppet 5 does not execute 'systemctl daemon-reload' automatically (https://tickets.puppetlabs.com/browse/PUP-3483)
    # and camptocamp/systemd only creates this relationship when managing the service
    Class['systemd::systemctl::daemon_reload'] -> Service['etcd']
  }

  service { 'etcd':
    ensure    => 'running',
    enable    => true,
    subscribe => Systemd::Unit_file['etcd.service']
  }

  file { 'sysconfig-etcd':
    ensure => file,
    path   => '/etc/sysconfig/etcd',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }

  File <| path == $etcd_bin |> ~> Service['etcd']
}
