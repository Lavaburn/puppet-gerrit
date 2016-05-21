# Class: gerrit::api
#
# This class manages the configuration file that Puppet uses to call the Gerrit REST API.
#
# Parameters:
# * username (string): The username to authenticate on the API. [REQUIRED]
# * password (string): The password to authenticate on the API. [REQUIRED]
# * root_ssh_key (string): The (public) SSH key for the local root user. [REQUIRED]
# * host (string): The host to call the API on. Default: 127.0.0.1
# * port (integer): The HTTP port to call the API on. Default: 8080
# * ssh_port (integer): The SSH port. Default: 29418
# * install_dir (path): The installation directory. Default: /opt/gerrit
# * setup_config (boolean): Setup configuration file. Default: true
# * setup_rest_auth (boolean): Setup HTPASSWD file. Default: true
# * setup_ssh_keys (boolean): Setup root SSH key. Default: true
#
# === Authors
#
# Nicolas Truyens <nicolas@truyens.com>
#
class gerrit::api (
  $username        = undef,
  $password        = undef,
  $root_ssh_key    = {},
  $host            = '127.0.0.1',
  $port            = 8080,
  $ssh_port        = 29418,
  $install_dir     = '/opt/gerrit',
  $setup_config    = true,
  $setup_rest_auth = true,
  $setup_ssh_keys  = true,
) {
  # Validation
  validate_bool($setup_config, $setup_rest_auth, $setup_ssh_keys)
  validate_string($host, $username, $password, $root_ssh_key)
  validate_absolute_path($install_dir)
  validate_hash($root_ssh_key)

  # Config file location is currently statically configured (gerrit_rest.rb)
  $api_auth_file = '/opt/gerrit/api.yaml'

  # Template parameters
  $api_host = $host
  $api_port = $port
  $admin_user = $username
  $admin_password = $password

  # Configuration File
  if ($setup_config) {
    Class['gerrit']
    ->
    file { $api_auth_file:
      ensure  => 'file',
      content => template('gerrit/api.yaml.erb')
    }
  }

  # REST API Authentication
  if ($setup_rest_auth) {
    Class['gerrit']
    ->
    httpauth { "gerrit_auth_${username}":
	   file     => "${install_dir}/etc/.htpasswd",
     name     => $username,
	   password => $password,
	 }
  }

	# SSH Keys
  if ($setup_ssh_keys) {
    $ssh_key = {
      user   => $username,
      'type' => 'ssh-rsa',# Puppet 4 - type is reserved word...
    }
    create_resources('ssh_authorized_key', $root_ssh_key, $ssh_key)
  }

  # Dependency Gems Installation
  if versioncmp($::puppetversion, '4.0.0') < 0 {
    ensure_packages(['rest-client'], {'ensure' => 'present', 'provider' => 'gem'})
  } else {
    ensure_packages(['rest-client'], {'ensure' => 'present', 'provider' => 'puppet_gem'})
  }
}
