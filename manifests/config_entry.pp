define etcd::config_entry (
  String[1] $key = $name,
  Variant[String, Integer, Boolean] $value
) {
  if $value == undef {
    $line = "#${key}="
  } else {
    $line = "${key}=${shellquote($value)}"
  }

  $path = File['sysconfig-etcd']['path']

  file_line { "sysconfig-etcd-${name}-${key}":
    ensure  => present,
    path    => $path,
    line    => $line,
    match   => "^#?${regexpescape($key)}\s?=\s?('')?",
    require => File['sysconfig-etcd'],
    notify  => Service['etcd'],
  }
}
