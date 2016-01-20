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
resp = client.register_elastic_ip({elastic_ip: eip_new,stack_id: stackid})

#associate eip
resp = opsworks.associate_elastic_ip({elastic_ip: eip_new,instance_id: OpsWorks_instance_id})

#deregist old eip
opsworks.deregister_elastic_ip
resp = client.deregister_elastic_ip({elastic_ip: eip_old})

#release old eip
ec2 = AWS::EC2::Client.new
resp = client.release_address({public_ip: eip_old})

