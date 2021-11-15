# @summary Manage etcd
#
# @example
#   include etcd
#
# @param version
#   Version of etcd to install
#   Not used if download_url is defined.
# @param base_url
#   Base URL of where to download etcd binaries.
#   Not used if download_url is defined.
# @param os
#   The GOOS to install
#   Not used if download_url is defined.
# @param arch
#   The GOARCH to install
#   Not used if download_url is defined.
# @param download_url
#   Alternative location to download etcd binaries
# @param download_dir
#   The directory of where to download etcd
# @param extract_dir
#   The directory where to extract etcd
# @param bin_dir
#   The path to bin directory for etcd and etcdctl symlinks
# @param manage_user
#   Boolean that determines if etcd user is managed
# @param manage_group
#   Boolean that determines if etcd group is managed
# @param user
#   The etcd user
# @param user_uid
#   The etcd user UID
# @param group
#   The etcd group
# @param group_gid
#   The etcd group GID
# @param config_path
#   The path to etcd YAML configuration
# @param config
#   The config values to pass to etcd
# @param max_open_files
#   The value for systemd LimitNOFILE unit option
class etcd (
  String $version                         = '3.5.1',
  Optional[Stdlib::HTTPUrl] $download_url = undef,
  Optional[String[1]] $download_proxy     = undef,
  Stdlib::Absolutepath $bin_dir           = '/usr/bin',
  Boolean $manage_user                    = true,
  Boolean $manage_group                   = true,
  String[1] $user                         = 'etcd',
  String[1] $group                        = 'etcd',
  Stdlib::Absolutepath $working_directory = '/var/lib/etcd',
  Optional[String[1]] $etcd_name          = '%H',
  Integer $max_open_files                 = 40000,
) {

  if $facts['service_provider'] != 'systemd' {
    fail('Module etcd only supported on systems using systemd')
  }

  class { 'etcd::install':
    version        => $version,
    bin_dir        => $bin_dir,
    manage_user    => $manage_user,
    manage_group   => $manage_group,
    user           => $user,
    group          => $group,
    download_proxy => $download_proxy,
  }

  Class['etcd::install'] -> Class['etcd::service']
  Class['etcd::install'] -> File <| path == $working_directory |>

  file { 'etcd-working-directory':
    ensure => 'directory',
    path   => $working_directory,
    owner  => $user,
    group  => $group,
    mode   => '0700',
    notify => Service['etcd'],
  }

  class { 'etcd::service':
    user              => $user,
    working_directory => $working_directory,
    etcd_name         => $etcd_name,
    max_open_files    => $max_open_files,
  }
}
