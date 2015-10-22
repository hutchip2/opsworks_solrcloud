action :getconfig do
  run_context.include_recipe 'aws'
  Chef::Log.info("Beginning deploy_custom_config recipe...")
  Chef::Log.info('Getting solr configuration from s3 bucket')

  zkconfigtar_tmp = '/tmp/zkconfigtar/'
  
  Chef::Log.info("Deleting directory: #{zkconfigtar_tmp}")
  directory zkconfigtar_tmp do
    recursive true
    action :delete
  end

  Chef::Log.info("Creating directory: #{zkconfigtar_tmp}")
  directory zkconfigtar_tmp do
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  Chef::Log.info("Retrieving file from s3: #{zkconfigtar_tmp}solrconfig.tar.gz")
  aws_s3_file "#{zkconfigtar_tmp}solrconfig.tar.gz" do
    Chef::Log.info("Bucket: #{zkconfigsets_s3_bucket}")
    bucket new_resource.zkconfigsets_s3_bucket
    
    Chef::Log.info("Remote path: #{zkconfigsets_s3_remote_path}")
    remote_path new_resource.zkconfigsets_s3_remote_path
    
    Chef::Log.info("AWS Access Key ID: #{zkconfigsets_s3_aws_access_key_id}")
    aws_access_key_id new_resource.zkconfigsets_s3_aws_access_key_id
    
    Chef::Log.info("AWS Secret Key: #{zkconfigsets_s3_aws_secret_access_key}")
    aws_secret_access_key new_resource.zkconfigsets_s3_aws_secret_access_key
  end

  bash 'zkconfigtar' do
    cwd zkconfigtar_tmp
    
    # Chef::Log.info("Current working directory: #{zkconfigtar_tmp}")
    # Chef::Log.info("Executing: tar xvfz solrconfig.tar.gz")
    # Chef::Log.info("Removing solrconfig.tar.gz")
    # Chef::Log.info("Copying #{node['solrcloud']['zkconfigsets_home]}")
    
    code <<-EOF
         tar xvfz solrconfig.tar.gz
         rm solrconfig.tar.gz
         cp -R * #{node['solrcloud']['zkconfigsets_home']}
    EOF
  end
  
  Chef::Log.info("Finishing deploy_custom_config recipe...")
  
  new_resource.updated_by_last_action(true)
end
