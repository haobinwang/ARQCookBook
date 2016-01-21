require 'aws-sdk'


region = node["opsworks"]["instance"]["region"]
hostname = node["opsworks"]["instance"]["hostname"]

eip_new = node["ip_mapping"][region][hostname]["ip"]
mapped_ns = node["ip_mapping"][region][hostname]["ns"]
eip_old=node["opsworks"]["instance"]["ip"]
OpsWorks_instance_id=node["opsworks"]["instance"]["id"]



###############################
#fundcion
def aws_eip2allocationid(region,eip)
  ret = nil
  #cmd = "aws ec2 describe-addresses"
  cmd = "aws ec2 describe-addresses --region #{region} --public-ips #{eip}"
  #puts "### try aws ec2 describe-addresses ###"
  value = %x( #{cmd} )
  if value.include? '"Addresses":'
    ip_hash = JSON.parse(value)
    if ip_hash.has_key?("Addresses")
      ip_hash["Addresses"].each do |address|
        puts "### PublicIp: #{address["PublicIp"]} ###"
        puts "### AllocationId: #{address["AllocationId"]} ###"
        if address["PublicIp"] == eip
          ret=address["AllocationId"]
          return ret
        end
      end
    end
  end
  return ret
end
###############################


opsworks = AWS::OpsWorks::Client.new

#get stack_id from instance
resp = opsworks.describe_instances({instance_ids: [OpsWorks_instance_id]})
instance=resp.instances[0]
stackid=instance.stack_id


#regist eip to stack
resp = opsworks.register_elastic_ip({elastic_ip: eip_new,stack_id: stackid})

#associate eip
resp = opsworks.associate_elastic_ip({elastic_ip: eip_new,instance_id: OpsWorks_instance_id})


#deregist old eip
resp = opsworks.deregister_elastic_ip({elastic_ip: eip_old})

#release old eip
ec2 = AWS::EC2::Client.new

#get allocation id
allocationid=aws_eip2allocationid(region,eip_old)


#release old eip
if allocationid.nil?
  puts "### cannot get allocation id ###"
else
  resp = ec2.release_address({allocation_id: allocationid})
end

