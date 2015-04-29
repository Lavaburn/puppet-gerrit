gerrit_project { 'test2':
  ensure      => present,
  description => 'Testing Project 2',
}

gerrit_group { 'All Users':
  ensure      => present,
  description => 'All Users (Required by Puppet/REST API)'
}

#gerrit_account { 'jenkins': } I can not remove/update it ! - Does not have a group assigned

gerrit_account { 'jenkins2':
  ensure   => present,
  groups   => ['Administrators'],# TODO Stream events ONLY works wfor Administrators group (global capability?)
  ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm6/wW3GITIUjc8qofHzk2zigpfIdqf1akXOk8c5cMkP7hZvYWxlv2oiDy62g0RJzF2scN1mOjBJ+TZ9k3le9nZqnRQhksCZOsFIaxerYRNFM3Esb8EQ1XKvLiJ2r5m9aPnGE+ctnlPgEJ14PWs/BhFCU3ypjB18iFoBRQ2oylBhD6XamsQOyTis2t5BQIJ7EofmBcF5GHelp1q0tmT5F8jD5fhNDZuhxUG5mkUlnECOJtEV6sVYXvPcaSvD2QXGlBpXa+o6ytdJz9rGCDi2ftVQtUScwFO8Y0yDfme1SEMd+wZ/9DRhKloxP+N0PFz+xyRmTBrnkUuf4LpM5ulW4R jenkins@dev'],
}

gerrit_account { 'nicolas':
  ensure    => present,
  real_name => 'Nicolas Truyens',
  emails    => ['nicolas@rcswimax.com', 'nicolas@truyens.com'],
  groups    => ['Administrators'],
  ssh_keys  => [
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZaQOkPRdC0rM30+/WSIlVK+YxSfI0fyIHM+FsXXxMzPTWWBpGcboxD4uDeZi1gpPtsl8ZYj0i/WN+nksVQQHLfd8/e2Xz9gueVECV22YhnusF1Ri+d7O14VBufJ0LBD8zzI6/2NrIp89rz0rcDED9BaANa9XL3pohdUd06tdXtFgqol9yez5H/Cu/ugdaBzGEVPadqb4G+1ZXmiefSTzEhbHT1LDKwWjtn5yyXkQpVFcGkKmDCrQoW1Z6j3SW4NsXNd4dGpVVSNa1hdlMjJPK9/KzPPgw9sPZZeWCPRlqzKHEJcAxrMArpGaYGk1guXe80Yhd7Fp6cUxbWVQOCHtD nicolas@Lava-PC',
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTq+25pV/r/uo8Ihaj/jM9flLx54NyqBRF4oFWq2H2e4zTrntAiwKvLU7vPZ6hyKWvRRDbu7xMsUpaILExNGzIOt24/gfkE0PSyLF/RpgTMbNuFZn8Nbfr+xy5Jhx2JFoaQ8fPnHJV+byN8f1b4QsYu7eJp9McsNQ7gZIkp8Cuo8eBaQS8Iwx+C9kw2WxFNVQ+oCXEfEI77MK0j5EBPTWcTA/xN4A6TzMBnL9xzjah/DUFDFyAnl+7ZZ6kDaY0gcwS3GywFGk70ts0Fel4dt8lXxz6P3fi4CXzMbBb4NhFJcdAlCrgNvvGo4eHungMRM5RrHOycCuzxeIgyzzLTKFT root@VM-84831abb-8d6d-4b52-96c5-b1c24a55cce2'
  ],
}

gerrit_access_role { 'All Users in test2':
  ensure  => present,
  group   => 'All Users',
  project => 'test2',
  rules   => {
    'refs/for/refs/*' => [ 'read', 'push' ],
  }
}

gerrit_access_role { 'All Users in test1':
  ensure  => present,
  group   => 'All Users',
  project => 'test1',
  rules   => {
    'refs/for/refs/*' => [ 'read', 'push', 'pushmerge' ]
  }
}
