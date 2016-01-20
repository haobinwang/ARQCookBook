
require 'aws-sdk'

region = node["opsworks"]["instance"]["region"]
hostname = node["opsworks"]["instance"]["hostname"]

eip_new = node["ip_mapping"][region][hostname]["ip"]
mapped_ns = node["ip_mapping"][region][hostname]["ns"]

#eip_old=node["opsworks"]["instance"]["ip"]
#ops_inst_id=node["opsworks"]["instance"]["id"]
public_ip =eip_new

=begin
#get eip from instance
opsworks = AWS::OpsWorks::Client.new
resp = opsworks.describe_instances({instance_ids: [ops_inst_id]})
instance=resp.instances[0]

if instance.respond_to?(:hostname)
    puts "### hostname: #{instance.hostname} ###"
end
if instance.respond_to?(:ec2_instance_id)
    puts "### ec2_instance_id: #{instance.ec2_instance_id} ###"
end
if instance.respond_to?(:instance_id)
    puts "### instance_id: #{instance.instance_id} ###"
end

if instance.respond_to?(:elastic_ip)
    puts "### elastic_ip: #{instance.elastic_ip} ###"
end

if instance.respond_to?(:stack_id)
    puts "### stack_id: #{instance.stack_id} ###"
end

if instance.respond_to?(:layer_ids)
    instance.layer_ids.each { |layer_id| puts "### layer_id: #{layer_id} ###"}
end

public_ip=instance.elastic_ip
puts "### get EIP from instance:#{public_ip} ###"
=end

#awstest.ers.trendmicro.com
HostedZoneID='Z1QLIJZNNZ5SR0'

#aws.ers.trendmicro.com
#HostedZoneID='Z3H87DJJHX9OQH'


r53 = AWS::Route53::Client.new()

DNSName=mapped_ns #'ns1.awstest.ers.trendmicro.com.'
record_type='A'
record_set_identifier='awstestarq-ns1'
record_region=region
record_ttl=3600
RData1=public_ip
res_records=[{value: RData1}]


#try to get record set

resp = r53.list_resource_record_sets({
    hosted_zone_id: HostedZoneID,
    start_record_name: DNSName,
    start_record_type: record_type,
    start_record_identifier: record_set_identifier,
    max_items: 1})

bNeedUpdate = true
bCreate = true
resp.resource_record_sets.each do |record|
   if record.respond_to?(:resource_records) and record.respond_to?(:set_identifier)
      bCreate = false
      record.resource_records.each do |resource_record|
         if resource_record.respond_to?(:value)
            if resource_record.value == public_ip
                bNeedUpdate = false
            else
                res_records.insert(-1,resource_record)
            end
            Chef::Log.info("##    value: #{resource_record.value}    ##")
         end
      end
   end
end

Action = bCreate ? "CREATE" : "UPSERT"
puts "### Action: #{Action} ###"

if bNeedUpdate
    resp = r53.change_resource_record_sets({
      hosted_zone_id: HostedZoneID,
      change_batch: {
        comment: "ResourceDescription",
        changes: [
          {
            action: Action, # required, accepts CREATE, DELETE, UPSERT
            resource_record_set: { # required
              name: DNSName, # required
              type: record_type, # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
              set_identifier: record_set_identifier,
              region: record_region, # accepts us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1, cn-north-1
              ttl: record_ttl,
              resource_records: res_records
            },
          },
        ],
      },
    })
    Chef::Log.info("###   Try to add: #{public_ip}   ###")
    Chef::Log.info("###   id: #{resp.change_info.id}   ###")
    Chef::Log.info("###   status: #{resp.change_info.status}   ###")
    Chef::Log.info("###   submitted_at: #{resp.change_info.submitted_at}   ###")
    Chef::Log.info("###   comment: #{resp.change_info.comment}   ###")
else
    Chef::Log.info("###   #{public_ip} already in record  ###")
end
