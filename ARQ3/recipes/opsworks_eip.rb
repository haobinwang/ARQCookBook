require 'aws-sdk'


region = node["opsworks"]["instance"]["region"]
hostname = node["opsworks"]["instance"]["hostname"]

eip_new = node["ip_mapping"][region][hostname]["ip"]
mapped_ns = node["ip_mapping"][region][hostname]["ns"]
eip_old=node["opsworks"]["instance"]["ip"]

OpsWorks_instance_id=node["opsworks"]["instance"]["id"]
opsworks = AWS::OpsWorks::Client.new


#get stack_id from instance
resp = opsworks.describe_instances({instance_ids: [OpsWorks_instance_id]})
instance=resp.instances[0]
stackid=instance.stack_id


#regist eip to stack
resp = opsworks.register_elastic_ip({elastic_ip: eip_new,stack_id: stackid})

#associate eip
resp = opsworks.associate_elastic_ip({elastic_ip: eip_new,instance_id: OpsWorks_instance_id})

=begin
#deregist old eip
resp = opsworks.deregister_elastic_ip({elastic_ip: eip_old})

#release old eip
ec2 = AWS::EC2::Client.new

#get allocation id

#resp = ec2.describe_addresses(filters: [{name: "public-ip",values: [eip_old]}])
resp = ec2.describe_addresses()
resp.addresses.each do |addresse|
  puts "### allocation_id:#{addresse.allocation_id} ###"
  puts "### public_ip:#{addresse.public_ip} ###"
  if addresse.public_ip == eip_old
    allocationid=addresse.allocation_id
    puts "### find IP allocationid:#{allocationid} ###"
  end
end 

#release old eip
if allocationid.nil?
  resp = ec2.release_address({public_ip: eip_old,allocation_id: allocationid})
else
  puts "### cannot get allocation id ###"
end
=end