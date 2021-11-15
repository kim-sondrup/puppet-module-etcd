# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include etcd::install
class etcd::install (
  String $version,
  Stdlib::Absolutepath $bin_dir           = '/usr/bin',
  Boolean $manage_user                    = true,
  Boolean $manage_group                   = true,
  Optional[String[1]] $download_proxy     = undef,
  Stdlib::HTTPUrl $base_url               = 'https://github.com/etcd-io/etcd/releases/download',
  String[1] $os                           = downcase($facts['kernel']),
  String[1] $arch                         = $facts['os']['architecture'],
  Optional[Stdlib::HTTPUrl] $download_url = undef,
  Stdlib::Absolutepath $download_dir      = '/tmp',
  Stdlib::Absolutepath $base_install_dir  = '/opt/etcd',
  String[1] $user                         = 'etcd',
  String[1] $group                        = 'etcd',
  Optional[Integer] $user_uid             = undef,
  Optional[Integer] $group_gid            = undef,
) {

  if $os != 'linux' {
    fail("Module etcd only supports Linux, not ${os}")
  }

  case $arch {
    'x86_64', 'amd64': { $real_arch = 'amd64' }
    'aarch64':         { $real_arch = 'arm64' }
    default:           { $real_arch = $arch }
  }

  $_download_url = pick($download_url, "${base_url}/v${version}/etcd-v${version}-${os}-${real_arch}.tar.gz")
  $install_dir = "${base_install_dir}/etcd-${version}"

  file { $base_install_dir:
    ensure       => 'directory',
    owner        => 'root',
    group        => 'root',
    mode         => '0755',
    recurselimit => 1,
    force        => true,
    purge        => true,
    recurse      => true,
    ignore       => 'etcd-*',
  }

  file { $install_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  archive { "${download_dir}/etcd.tar.gz":
    source          => $_download_url,
    extract         => true,
    extract_path    => $install_dir,
    extract_command => 'tar xfz %s --strip-components=1',
    creates         => "${install_dir}/etcd",
    cleanup         => true,
    user            => 'root',
    group           => 'root',
    proxy_server    => $download_proxy,
    require         => File[$install_dir],
    before          => File[
      'etcd',
      'etcdctl',
    ],
  }

  file { 'etcd':
    ensure  => 'link',
    path    => "${bin_dir}/etcd",
    target  => "${install_dir}/etcd",
    require => Archive["${download_dir}/etcd.tar.gz"],
    notify  => Service['etcd'],
  }

  file { 'etcdctl':
    ensure  => 'link',
    path    => "${bin_dir}/etcdctl",
    target  => "${install_dir}/etcdctl",
    require => Archive["${download_dir}/etcd.tar.gz"],
  }

  if $manage_user {
    user { 'etcd':
      ensure     => 'present',
      name       => $user,
      forcelocal => true,
      shell      => '/usr/sbin/nologin',
      uid        => $user_uid,
      gid        => $group,
      managehome => false,
      system     => true,
    }
  }
  if $manage_group {
    group { 'etcd':
      ensure     => 'present',
      name       => $group,
      forcelocal => true,
      gid        => $group_gid,
      system     => true,
    }
  }
}
