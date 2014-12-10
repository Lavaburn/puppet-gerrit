require 'spec_helper'

describe 'gerrit', :type => :class do

  # Force our osfamily & operatingsystem so that puppetlabs-java
  # doesn't croak on us
  let(:facts) { {:osfamily => 'RedHat', :operatingsystem => 'Centos'} }

  context 'with defaults' do
    it { is_expected.to contain_class('gerrit') }
    it { is_expected.to contain_class('gerrit::params') }
    it { is_expected.to contain_anchor('gerrit::begin') }
    it { is_expected.to contain_class('gerrit::install') }
    it { is_expected.to contain_class('gerrit::config') }
    it { is_expected.to contain_class('gerrit::initialize') }
    it { is_expected.to contain_class('gerrit::service') }
    it { is_expected.to contain_anchor('gerrit::end') }
  end

  #####
  # gerrit::install testing
  #####

  # this would be in a separate install_spec.rb but cross sub-module
  # variable evaluation doesn't seem to work correctly then
  context 'gerrit::install' do
    it { is_expected.to contain_class('java') }
    it { is_expected.to contain_class('git') }
    it { is_expected.to contain_user('gerrit') }

    # only need to fully validate one file for properties since the
    # definition should be an array define for all the permissions
    # setting
    it { is_expected.to contain_file('/opt/gerrit/bin').with(
          'ensure'    => 'directory',
          'owner'     => 'gerrit',
          'group'     => 'gerrit',
          'require'   => 'User[gerrit]',
          ) }
    it { is_expected.to contain_file('/opt/gerrit/etc') }
    it { is_expected.to contain_file('/opt/gerrit/lib') }
    it { is_expected.to contain_file('/opt/gerrit/logs') }
    it { is_expected.to contain_file('/opt/gerrit/plugins') }
    it { is_expected.to contain_file('/opt/gerrit/static') }
    it { is_expected.to contain_file('/opt/gerrit/tmp') }
    it { is_expected.to contain_file('/srv/gerrit') }
    it { is_expected.to contain_exec('download gerrit 2.9.2').with(
        'cwd'     => '/opt/gerrit/bin',
        'path'    => [ '/usr/bin', '/usr/sbin' ],
        'command' => 'curl -s -O https://gerrit-releases.storage.googleapis.com/gerrit-2.9.2.war',
        'creates' => '/opt/gerrit/bin/gerrit-2.9.2.war',
        'user'    => 'gerrit',
        'group'   => 'gerrit',
        ) }
    it { is_expected.to contain_file('/opt/gerrit/bin/gerrit.war').with(
        'ensure'  => 'link',
        'target'  => 'gerrit-2.9.2.war',
        ) }

    context 'with install_java false' do
      let(:params) {{ :install_java => false }}

      it { is_expected.to_not contain_class('java') }
    end

    context 'with install_git false' do
      let(:params) {{ :install_git => false }}

      it { is_expected.to_not contain_class('git') }
    end

    context 'with override_options[container][user][value] set to foo' do
      let(:params) {{ :override_options => {
        'container' => { 'user' => {'value' => 'foo' }}} }}

      it { is_expected.to contain_user('foo') }

      # only need to fully validate one file for properties since the
      # definition should be an array define for all the permissions
      # setting
      it { is_expected.to contain_file('/opt/gerrit/bin').with(
            'ensure'    => 'directory',
            'owner'     => 'foo',
            'group'     => 'foo',
            'require'   => 'User[foo]',
            ) }

      it { is_expected.to contain_exec('download gerrit 2.9.2').with(
          'user'  => 'foo',
          'group' => 'foo',
          ) }
    end

    # really only need to fully validate one file path since we've made sure
    # that changing the user modifies all owner, group, require already
    context 'with gerrit_home set to /var/foo' do
      let(:params) {{ :gerrit_home => '/var/foo' }}

      it { is_expected.to contain_user('gerrit').with(
            'home' => '/var/foo',
          ) }
      it { is_expected.to contain_file('/var/foo/bin').with(
            'ensure'    => 'directory',
            'owner'     => 'gerrit',
            'group'     => 'gerrit',
            'require'   => 'User[gerrit]',
          ) }
      it { is_expected.to contain_file('/var/foo/etc') }
      it { is_expected.to contain_file('/var/foo/lib') }
      it { is_expected.to contain_file('/var/foo/logs') }
      it { is_expected.to contain_file('/var/foo/plugins') }
      it { is_expected.to contain_file('/var/foo/static') }
      it { is_expected.to contain_file('/var/foo/tmp') }
      it { is_expected.to contain_exec('download gerrit 2.9.2').with(
          'cwd' => '/var/foo/bin',
          'creates' => '/var/foo/bin/gerrit-2.9.2.war',
          ) }
    end

    # verify that changing the options[gerrit][basePath][value] changes
    # the git storage location
    # No need to verify the permissions / validity of it being a directory
    # as that has already been tested previously
    context 'with override_options[gerrit]basePath][value] set to /srv/foo' do
      let(:params) {{ :override_options => {
        'gerrit' => { 'basePath' => { 'value' => '/srv/foo' }}} }}

      it { is_expected.to contain_file('/srv/foo') }
    end

    context 'with gerrit_version 2.10.0 and download_location http://foo' do
      let(:params) {{ :gerrit_version => '2.10.0', :download_location => 'http://foo' }}
      it { is_expected.to contain_exec('download gerrit 2.10.0').with(
          'command' => 'curl -s -O http://foo/gerrit-2.10.0.war',
          'creates' => '/opt/gerrit/bin/gerrit-2.10.0.war',
          ) }
    end

  end

  #####
  # gerrit::config testing
  #####

  context 'gerrit::config' do
    it { is_expected.to contain_file('/opt/gerrit/etc/GerritSite.css').with(
        'owner'   => 'gerrit',
        'group'   => 'gerrit',
        'source'  => 'puppet:///modules/gerrit/skin/GerritSite.css',
        ) }
    it { is_expected.to contain_file('/opt/gerrit/etc/GerritSiteHeader.html').with(
        'owner'   => 'gerrit',
        'group'   => 'gerrit',
        'source'  => 'puppet:///modules/gerrit/skin/GerritSiteHeader.html',
        ) }
    it { is_expected.to contain_file('/opt/gerrit/etc/GerritSiteFooter.html',
        'owner'   => 'gerrit',
        'group'   => 'gerrit',
        'source'  => 'puppet:///modules/gerrit/skin/GerritSiteFooter.html',
        ) }
    it { is_expected.to contain_file('/opt/gerrit/etc/gerrit.config').with(
        'ensure'  => 'present',
        'owner'   => 'gerrit',
        'group'   => 'gerrit',
        'mode'    => '0660',
        ) }
    it { is_expected.to contain_file('/opt/gerrit/etc/secure.config').with(
        'ensure'  => 'present',
        'owner'   => 'gerrit',
        'group'   => 'gerrit',
        'mode'    => '0600',
        ) }

    context 'with manage_site_skin false' do
      let(:params) {{ :manage_site_skin => false }}

      it { is_expected.to_not contain_file('/opt/gerrit/etc/GerritSite.css') }
      it { is_expected.to_not contain_file('/opt/gerrit/etc/GerritSiteHeader.html') }
      it { is_expected.to_not contain_file('/opt/gerrit/etc/GerritSiteFooter.html') }
    end

    context 'with custom site skin, home dir, user' do
      let(:params) {{
          :gerrit_home => '/var/foo',
          :override_options => {
            'container' => { 'user' => { 'value' => 'foo' } }
          },
          :gerrit_site_options => {
            'GerritSite.css'        => 'puppet:///private/GerritSite.css',
            'GerritSiteHeader.html' => 'puppet:///private/GerritSiteHeader.html',
            'GerritSiteFooter.html' => 'puppet:///private/GerritSiteFooter.html',
          }
        }}

      it { is_expected.to contain_file('/var/foo/etc/GerritSite.css').with(
          'owner'   => 'foo',
          'group'   => 'foo',
          'source'  => 'puppet:///private/GerritSite.css',
          ) }
      it { is_expected.to contain_file('/var/foo/etc/GerritSiteHeader.html').with(
          'owner'   => 'foo',
          'group'   => 'foo',
          'source'  => 'puppet:///private/GerritSiteHeader.html',
          ) }
      it { is_expected.to contain_file('/var/foo/etc/GerritSiteFooter.html').with(
          'owner'   => 'foo',
          'group'   => 'foo',
          'source'  => 'puppet:///private/GerritSiteFooter.html',
          ) }
    end

  end

  #####
  # gerrit::initialize testing
  #####
  context 'gerrit::initialize' do
    context 'with defaults' do
      it { is_expected.to contain_exec('gerrit_initialize').with(
        'cwd'     => '/opt/gerrit',
        'command' => 'java -jar /opt/gerrit/bin/gerrit.war init --batch && touch /opt/gerrit/.gerrit_setup_complete.txt',
        'creates' => '/opt/gerrit/.gerrit_setup_complete.txt',
        'path'    => [ '/usr/bin', '/usr/sbin' ],
      ) }
    end
  end

  #####
  # gerrit::service testing
  #####

  context 'gerrit::service' do
    context 'with defaults' do
      it { is_expected.to contain_service('gerrit').with(
          :ensure   => true,
          :enable   => true,
        ) }
    end

    context 'service_enabled is incorrect' do
      let(:params) {{ :service_enabled => 'invalid_val' }}
      it 'should report an error when service_enabled is incorrect' do
        expect { subject }.to raise_error(Puppet::Error,
                                          /invalid_val is not supported for service_enabled\. Allowed values are true, false, 'manual'\./)
      end
    end

    context 'service_enabled set to false' do
      let(:params) {{ :service_enabled => false }}

      it { is_expected.to contain_service('gerrit').with(
          :ensure => false
        ) }
    end
  end
end
