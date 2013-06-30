#
# Cookbook Name:: mongodb
# Recipe:: backup
#
 
ey_cloud_report "mongodb" do
  message "configuring backup"
end

# We support three mongo configs, Solo, Stand-Alone, and Replica Sets, only Replica Sets are recommended and supported for Production use.
replset = true
mongo_nodes = @node[:utility_instances].select { |instance| instance[:name].match(/^mongodb_repl#{@node[:mongo_replset]}/) }
if mongo_nodes.empty?
  mongo_nodes = @node[:utility_instances].select { |instance| instance[:name].match(/mongodb/)}
  replset = false
end

if (!mongo_nodes.empty? and (!replset or (replset and @node[:name] == mongo_nodes.last[:name]))) or (['solo'].include?(node[:instance_role]) && @node[:mongo_utility_instances].length == 0)

  node[:applications].each do |app_name, data|
    user = node[:users].first

    template "/usr/local/bin/mongo-backup" do
      source "mongo-backup.rb.erb"
      owner "root"
      group "root"
      mode 0700
      variables({
        :secret_key => node[:aws_secret_key],
        :id_key => node[:aws_secret_id],
        :env => node[:environment][:name],
        :app_name => app_name
      })
    end

    cron "#{app_name}-mongo-backup" do
      hour "1"
      minute "30"
      command "/usr/local/bin/mongo-backup"
    end
  end

else

  cron "mongo-backup" do
    action :delete
  end

end

