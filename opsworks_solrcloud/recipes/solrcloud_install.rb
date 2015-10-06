#
# see solrcloud::tarball
#

# Setup Solr Service User
include_recipe 'solrcloud::user'
include_recipe 'solrcloud::java'
include_recipe 'solrcloud::attributes'

# Require for zk gem
%w(patch gcc make).each do |pkg|
  package pkg do
    action :nothing
    only_if { node['solrcloud']['install_zk_gem'] }
  end.run_action(:install)
end

chef_gem 'zk' do
  action :nothing
  only_if { node['solrcloud']['install_zk_gem'] }
end.run_action(:install)

require 'zk'
require 'net/http'
require 'json'
require 'tmpdir'

tarball_url = "https://archive.apache.org/dist/lucene/solr/#{node['solrcloud']['version']}/solr-#{node['solrcloud']['version']}.tgz"
tarball_checksum = solr_tarball_sha256sum(node['solrcloud']['version'])

temp_dir      = Dir.tmpdir
tarball_file  = ::File.join(temp_dir, "solr-#{node['solrcloud']['version']}.tgz")
tarball_dir   = ::File.join(temp_dir, "solr-#{node['solrcloud']['version']}")

# Stop Solr Service if running for Version Upgrade
service 'solr' do
  service_name node['solrcloud']['service_name']
  action :stop
  only_if { ::File.exist?("/etc/init.d/#{node['solrcloud']['service_name']}") && !::File.exist?(File.join(node['solrcloud']['source_dir'], 'dist', "solr-core-#{node['solrcloud']['version']}.jar")) }
end

# Solr Version Package File
remote_file tarball_file do
  source tarball_url
  checksum tarball_checksum
  not_if { ::File.exist?("#{node['solrcloud']['source_dir']}/dist/solr-core-#{node['solrcloud']['version']}.jar") }
end

# Extract and Setup Solr Source directories
bash 'extract_solr_tarball' do
  user 'root'
  cwd '/tmp'

  code <<-EOS
    tar xzf #{tarball_file}
    mv --force #{tarball_dir} #{node['solrcloud']['source_dir']}
    chown -R #{node['solrcloud']['user']}:#{node['solrcloud']['group']} #{node['solrcloud']['source_dir']}
    chmod #{node['solrcloud']['dir_mode']} #{node['solrcloud']['source_dir']}
  EOS
  creates ::File.join(node['solrcloud']['source_dir'], 'dist', "solr-core-#{node['solrcloud']['version']}.jar")
end

# Link Solr install_dir to Current source_dir
link node['solrcloud']['install_dir'] do
  to node['solrcloud']['source_dir']
  notifies :restart, 'service[solr]', :delayed if node['solrcloud']['notify_restart_upgrade']
end

# Link Jetty lib dir
link ::File.join(node['solrcloud']['install_dir'], 'lib') do
  to ::File.join(node['solrcloud']['install_dir'], node['solrcloud']['server_base_dir_name'], 'lib')
  owner node['solrcloud']['user']
  group node['solrcloud']['group']
end

# Link Solr start.jar
link ::File.join(node['solrcloud']['install_dir'], 'start.jar') do
  to ::File.join(node['solrcloud']['install_dir'], node['solrcloud']['server_base_dir_name'], 'start.jar')
  owner node['solrcloud']['user']
  group node['solrcloud']['group']
end

# Setup Directories for Solr
[node['solrcloud']['log_dir'],
 node['solrcloud']['pid_dir'],
 node['solrcloud']['data_dir'],
 node['solrcloud']['solr_home'],
 node['solrcloud']['config_sets'],
 node['solrcloud']['cores_home'],
 node['solrcloud']['zkconfigsets_home'],
 ::File.join(node['solrcloud']['install_dir'], 'etc'),
 ::File.join(node['solrcloud']['install_dir'], 'resources'),
 ::File.join(node['solrcloud']['install_dir'], 'webapps'),
 ::File.join(node['solrcloud']['install_dir'], 'contexts')
].each do |dir|
  directory dir do
    owner node['solrcloud']['user']
    group node['solrcloud']['group']
    mode 0755
    recursive true
  end
end

directory node['solrcloud']['zk_run_data_dir'] do
  owner node['solrcloud']['user']
  group node['solrcloud']['group']
  mode 0755
  recursive true
  only_if { node['solrcloud']['zk_run'] }
end

# Solr Service User limits
user_ulimit node['solrcloud']['user'] do
  filehandle_limit node['solrcloud']['limits']['nofile']
  process_limit node['solrcloud']['limits']['nproc']
  memory_limit node['solrcloud']['limits']['memlock']
end

ruby_block 'require_pam_limits.so' do
  block do
    fe = Chef::Util::FileEdit.new('/etc/pam.d/su')
    fe.search_file_replace_line(/# session    required   pam_limits.so/, 'session    required   pam_limits.so')
    fe.write_file
  end
end

# Solr Config
include_recipe 'solrcloud::config'

# Jetty Config
include_recipe 'solrcloud::jetty'

# Zookeeper Client Setup
include_recipe 'solrcloud::zkcli'

service 'solr' do
  supports :start => true, :stop => true, :restart => true, :status => true
  service_name node['solrcloud']['service_name']
  action [:enable, :start]
  notifies :run, 'ruby_block[wait_start_up]', :immediately
end

# Waiting for Service
ruby_block 'wait_start_up' do
  block do
    sleep node['solrcloud']['service_start_wait']
  end
  action :nothing
end

remote_file tarball_file do
  action :delete
end


directory '/usr/local/solr/solr/configsets/conf' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file "Copy configset files" do 
  path "/usr/local/solr/solr/configsets/conf/solrconfig.xml" 
  source "/usr/local/solr_zkconfigsets/conf/solrconfig.xml"
  owner 'root'
  group 'root'
  mode 0755
end

directory '/usr/local/solr/solr/cores/core1' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/usr/local/solr/solr/cores/core2' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/usr/local/solr/solr/cores/core3' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/usr/local/solr/solr/cores/core1/core.properties' do
  content 'configSet='
  mode '0755'
  owner 'ec2-user'
end

file '/usr/local/solr/solr/cores/core2/core.properties' do
  content 'configSet=conf'
  mode '0755'
  owner 'ec2-user'
end

file '/usr/local/solr/solr/cores/core3/core.properties' do
  content 'configSet=/usr/local/solr_zkconfigsets/conf'
  mode '0755'
  owner 'ec2-user'
end
