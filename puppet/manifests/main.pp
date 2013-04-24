rbenv::install { 'vagrant': }

rbenv::compile { '1.9.3-p392':
  user   => 'vagrant',
  global => true
}

class { 'mongodb': }
class { 'redis': }
