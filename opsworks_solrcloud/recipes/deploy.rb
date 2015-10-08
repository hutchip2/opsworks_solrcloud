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

# get tarball from s3 bucket and untar
aws_s3_file "solrconfig.tar.gz" do
  bucket "labelinsight-documents"
  remote_path "/solr/solrconfig.tar.gz"
  aws_access_key_id node[:custom_access_key]
  aws_secret_access_key node[:custom_secret_key]
end

bash 'extract_solr_tarball_from_s3' do
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

=end
