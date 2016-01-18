require 'aws-sdk'


ip_ops="52.70.181.6"
ip_new="52.71.198.1"

OpsWorks_instance_id=node["opsworks"]["instance"]["id"]
#OpsWorks_instance_id='bd91da6e-d665-44a9-9ad8-8187a1a51f7d'
opsworks = AWS::OpsWorks::Client.new


=begin
public_ip=node["opsworks"]["instance"]["ip"]
puts "##### node public_ip:#{public_ip} #####"

#disassociate eip
resp = opsworks.disassociate_elastic_ip({elastic_ip: ip_ops})
=end

public_ip=node["opsworks"]["instance"]["ip"]
puts "##### node public_ip:#{public_ip} #####"


#resp = opsworks.describe_elastic_ips({instance_id: OpsWorks_instance_id})
resp = opsworks.describe_elastic_ips({ips: [ip_ops]})

puts "##### try to list public_ip #####"
resp.elastic_ips.each do |eip|
    if eip.respond_to?(:ip)
        puts "### ip: #{eip.ip} ###"
    end
    if eip.respond_to?(:name )
        puts "### name: #{eip.name} ###"
    end
    
    if eip.respond_to?(:region )
        puts "### region: #{eip.region} ###"
    end
    if eip.respond_to?(:instance_id  )
        puts "### instance_id: #{eip.instance_id} ###"
    end
end
puts "##### end of list public_ip #####"



#associate eip
resp = opsworks.associate_elastic_ip({elastic_ip: ip_new,instance_id: OpsWorks_instance_id})


public_ip=node["opsworks"]["instance"]["ip"]
puts "##### af associate node public_ip:#{public_ip} #####"

resp = opsworks.describe_elastic_ips({ips: [ip_new]})
puts "##### try to list public_ip #####"
resp.elastic_ips.each do |eip|
    if eip.respond_to?(:ip)
        puts "### ip: #{eip.ip} ###"
    end
    if eip.respond_to?(:name )
        puts "### name: #{eip.name} ###"
    end
    
    if eip.respond_to?(:region )
        puts "### region: #{eip.region} ###"
    end
    if eip.respond_to?(:instance_id  )
        puts "### instance_id: #{eip.instance_id} ###"
    end
end
puts "##### end of list public_ip #####"
