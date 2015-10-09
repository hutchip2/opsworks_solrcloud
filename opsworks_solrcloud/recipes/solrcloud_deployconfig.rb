include_recipe 'solrcloud::attributes'

chef_gem 'zk' do
  action :nothing
end.run_action(:install)

require 'zk'
require 'net/http'
require 'json'

#
# see solrcloud::zkconfigsets
#
node['solrcloud']['zkconfigsets'].each do |configset_name, options|
  solrcloud_zkconfigset configset_name do
    user node['solrcloud']['user']
    group node['solrcloud']['group']
    zkcli node['solrcloud']['zookeeper']['zkcli']
    zkhost node['solrcloud']['solr_config']['solrcloud']['zk_host'].first
    zkconfigsets_home node['solrcloud']['zkconfigsets_home']
    zkconfigsets_cookbook node['solrcloud']['zkconfigsets_cookbook']
    manage_zkconfigsets node['solrcloud']['manage_zkconfigsets']
    solr_zkcli node['solrcloud']['zookeeper']['solr_zkcli']
    force_upload node['solrcloud']['force_zkconfigsets_upload']
    action options[:action]
  end
end

#
# see solrcloud::collections
#
node['solrcloud']['collections'].each do |collection_name, options|
  collection_name = options[:name] if options[:name]
  solrcloud_collection collection_name do
    num_shards options[:num_shards]
    shards options[:shards]
    router_field options[:router_field]
    async options[:async]
    router_name options[:router_name]
    router_field options[:router_field]
    use_ssl options[:use_ssl]
    context_path node['solrcloud']['jetty_config']['context']['path']
    zkhost node['solrcloud']['solr_config']['solrcloud']['zk_host'].first
    zkcli node['solrcloud']['zookeeper']['zkcli']
    port node['solrcloud']['port']
    ssl_port node['solrcloud']['ssl_port']
    create_node_set options[:create_node_set]
    replication_factor options[:replication_factor]
    max_shards_per_node options[:max_shards_per_node]
    collection_config_name options[:collection_config_name]
    action options[:action]
  end
end

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
