include_recipe 'deploy'

#yum_package 'python26' do
#  action :install
#end

#yum_package 'python-netifaces' do
#  action :install
#end

node[:deploy].each do |application, deploy|
  # determine root folder of new app deployment
  app_root = "#{deploy[:deploy_to]}/current"
  
  # deploy init 
  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end
 
  Chef::Log.info("deploy #{application}")

  # install
  bash 'deploy-rpm' do
        user 'root'
        code <<-EOH
                rpm -ivh "#{app_root}/archive"
        EOH
        notifies :start, "service[rpm]", :delayed
  end
  
  # start
  service 'rpm' do
        service_name "#{application}"
        action :nothing
  end
  
end