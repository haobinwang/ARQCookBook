node[:deploy].each do |application, config|
  # determine root folder of new app deployment
  app_root = "#{config[:deploy_to]}/current"
  s3_bucket, s3_key = OpsWorks::SCM::S3.parse_uri(config[:scm][:repository])
  package_name = s3_key.split('/')[-1]
  puts "#{package_name}"

  Chef::Log.info("download #{application} from #{config[:scm][:repository]}")
  # download rpm from s3
  s3_file "/tmp/#{package_name}" do
    bucket s3_bucket
    remote_path s3_key
    aws_access_key_id config[:scm][:user]
    aws_secret_access_key config[:scm][:password]
    action :create
  end

  Chef::Log.info("deploy #{application}")
  # rpm install 
  rpm_package "#{application}" do
    source "/tmp/#{package_name}"
    notifies :start, "service[#{application}]", :delayed
    action :install
  end

  # start
  service "#{application}" do
    #service_name "#{application}"
    action :nothing
  end
end
