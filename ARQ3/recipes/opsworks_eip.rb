require 'aws-sdk'


region = node["opsworks"]["instance"]["region"]
hostname = node["opsworks"]["instance"]["hostname"]

#adjust hostname if name with '-'
hostname_node = hostname
nFind=hostname_node.index('-')
if nFind
  hostname_node=hostname_node[0,nFind]
end
eip_new = node["ip_mapping"][region][hostname_node]["ip"]
mapped_ns = node["ip_mapping"][region][hostname_node]["ns"]
#eip_old=node["opsworks"]["instance"]["ip"]
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

#get stack_id and public_ip from instance
resp = opsworks.describe_instances({instance_ids: [OpsWorks_instance_id]})
instance=resp.instances[0]
stackid=instance.stack_id
eip_old=instance.public_ip

instance_id_old = nil

if eip_old == eip_new
  eip_old = nil
  puts "### #{eip_new} already bind to instance###"
else
  #check if new eip associated a instance 
  resp = opsworks.describe_elastic_ips({ips: [eip_new]})
  resp.elastic_ips.each do |elastic_data|
    if elastic_data.ip == eip_new
      instance_id_old=elastic_data.instance_id
      break
    end
  end
  
  unless instance_id_old #not associated instance
    #regist eip to stack
    resp = opsworks.register_elastic_ip({elastic_ip: eip_new,stack_id: stackid})
  end
  
  #associate eip
  resp = opsworks.associate_elastic_ip({elastic_ip: eip_new,instance_id: OpsWorks_instance_id})
end

if eip_old.nil?
  puts "### no eip need to free###"
else
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
end

#stop and delete old instance
#unless instance_id_old.nil?
#  opsworks.
#end

