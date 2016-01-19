include_recipe 'deploy'

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
  # rpm install 
  rpm_package "#{application}" do
    source "#{app_root}/archive"
    notifies :start, "service[rpm]", :delayed
    action :install
  end

  # start
  service 'rpm' do
        service_name "#{application}"
        action :nothing
  end

end
#include_recipe 'ARQ3::instanceAttributes'
#include_recipe 'ARQ3::inst_eip2r53'
#include_recipe 'ARQ3::opsworks_eip'