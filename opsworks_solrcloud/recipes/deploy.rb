Chef::Log.info("Running opsworks solrcloud deploy in activity #{node['opsworks']['activity']}")

if node['opsworks']['layers']['solrcloud']['instances'].first.nil?
  Chef::Log.info('No first instance for layer solrcloud available skipping deployment')
else
  firsthost = node['opsworks']['layers']['solrcloud']['instances'].first[1]
  # only run on the first cluster node
  if firsthost['private_ip'] == node['ipaddress']
    opsworks_solrcloud_solr 'Downloading solr configuration' do
      action :getconfig
    end

    opsworks_solrcloud_solr 'Deploying solr configuration' do
      action :deployconfig
    end
  else
    Chef::Log.info('Not running on the first node, skipping deployment of solr configuration')
  end
end

=begin
config_directory = '/usr/local/solr_zkconfigsets'
collections = Dir.entries(config_directory).select {|entry| File.directory? File.join(config_directory,entry) and !(entry =='.' || entry == '..' || entry.start_with?('.')) }

execute '/usr/local/solr_zkconfigsets' do
    unless collections.empty?
      collections.each do |collection|
        unless collection.to_s.nil? or collection.to_s.empty? or collection.to_s.blank?
          # create current collection
          command "/usr/local/solr-5.3.0/bin/./solr create -c #{collection.to_s}"
          # store 'managed-schema' for current collection
          #file "/etc/init.d/someService" do
          #  owner 'solr'
          #  group 'solr'
          #  mode 0755
          #  content ::File.open("/usr/local/solr_zkconfigsets/#{collection}/conf/managed-schema").read
          #  action :create
          #end
          # store 'solrconfig.xml' for current collection
          
        end
      end
    end
    ignore_failure true
end
=end
