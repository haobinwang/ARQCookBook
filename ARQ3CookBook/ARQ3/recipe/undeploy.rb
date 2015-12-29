include_recipe 'deploy'

# stop the service
node[:deploy].each do |app_name, deploy_config|
  service 'rpm' do
        service_name "#{app_name}"
        action :stop
  #      notifies :run, "bash[undeploy-rpm]", :delayed
  end

  # uninstall
  #bash 'undeploy-rpm' do
  #      user 'root'
  #      code <<-EOH
  #              rpm -e "#{app_name}"
  #      EOH
  #end
end