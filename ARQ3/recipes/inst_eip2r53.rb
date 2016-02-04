
require 'aws-sdk'

region = node["opsworks"]["instance"]["region"]
hostname = node["opsworks"]["instance"]["hostname"]

#adjust hostname if name with '-'
hostname_node = hostname
nFind=hostname_node.index('-')
if nFind
  hostname_node=hostname_node[0,nFind]
end
public_ip = node["ip_mapping"][region][hostname_node]["ip"]
mapped_ns = node["ip_mapping"][region][hostname_node]["ns"]

hosted_zone_names = node["hosted_zones"]


###############################
#function
=begin
#not work
def r53_hosted_zone_names2ids(hosted_zone_names, region_name)
  r53 = AWS::Route53::Client.new(region: region_name)
  hosted_zone_ids=[]
  hosted_zone_names.each do |hosted_zone_name|
    resp = r53.list_hosted_zones({marker: "PageMarker",max_items: 100})
    if resp.respond_to?(:hosted_zones)
      resp.hosted_zones do |hosted_zone|
        puts "### hosted_zone name: #{hosted_zone.name} ###"
        puts "### hosted_zone id: #{hosted_zone.id} ###"
        if(hosted_zone.name == hosted_zone_name)
          hosted_zone_ids.insert(-1, hosted_zone.id)
        end
      end
    end
  end
  return hosted_zone_ids
end
=end

def r53_cli_hosted_zone_names2ids(hosted_zone_names)
  hosted_zone_ids=[]
  hosted_zone_names.each do |hosted_zone_name|
    hosted_zone_name_dot = "#{hosted_zone_name}."
    #cmd = "aws route53 list-hosted-zones-by-name --dns-name awstest.ers.trendmicro.com"
    cmd = "aws route53 list-hosted-zones-by-name --dns-name #{hosted_zone_name}"
    #puts "### aws route53 list-hosted-zones-by-name ###"
    value = %x( #{cmd} )
    if value.include? '"HostedZones":'
      zone_hash = JSON.parse(value)
      if zone_hash.has_key?("HostedZones")
        zone_hash["HostedZones"].each do |zonedata|
          #puts "### HostedZones Id: #{zonedata["Id"]} ###"
          #puts "### HostedZones Name: #{zonedata["Name"]} ###"
          if zonedata["Name"] == hosted_zone_name_dot
            #"zonedata["Id"]="/hostedzone/Z1QLIJZNNZ5SR0", 
            hosted_zone_id_elements = zonedata["Id"].split('/')
            hosted_zone_id = hosted_zone_id_elements[2]
            hosted_zone_ids.insert(-1, hosted_zone_id)
          end
        end
      end
    end
  end
  return hosted_zone_ids
end

def r53_get_resource_record_sets(hostedzoneid, dnsname, type, set_identifier,target_ip)
  r53 = AWS::Route53::Client.new()
  resp = r53.list_resource_record_sets({
      hosted_zone_id: hostedzoneid,
      start_record_name: dnsname,
      start_record_type: type,
      start_record_identifier: set_identifier,
      max_items: 1})
  res_records=[]
  bNeedUpdate = true
  bNeedCreate = true
  resp.resource_record_sets.each do |record|
     if record.respond_to?(:resource_records) and record.respond_to?(:set_identifier)
        bNeedCreate = false
        record.resource_records.each do |resource_record|
           if resource_record.respond_to?(:value)
              if resource_record.value == target_ip
                  bNeedUpdate = false
              else
                  res_records.insert(-1,resource_record)
              end
              Chef::Log.info("##    value: #{resource_record.value}    ##")
           end
        end
     end
  end
  return res_records,bNeedUpdate,bNeedCreate
end

def r53_change_resource_record_sets(hostedzoneid, bCreate, dnsname, 
  rtype, rset_identifier, rregion, rttl, rrecords)

  raction = bCreate ? "CREATE" : "UPSERT"
  puts "### Action: #{raction} ###"
  r53 = AWS::Route53::Client.new()
  resp = r53.change_resource_record_sets({
    hosted_zone_id: hostedzoneid,
    change_batch: {
      comment: "ResourceDescription",
      changes: [
        {
          action: raction, # required, accepts CREATE, DELETE, UPSERT
          resource_record_set: { # required
            name: dnsname, # required
            type: rtype, # required, accepts SOA, A, TXT, NS, CNAME, MX, PTR, SRV, SPF, AAAA
            set_identifier: rset_identifier,
            region: rregion, # accepts us-east-1, us-west-1, us-west-2, eu-west-1, eu-central-1, ap-southeast-1, ap-southeast-2, ap-northeast-1, sa-east-1, cn-north-1
            ttl: rttl,
            resource_records: rrecords
          },
        },
      ],
    },
  })
  Chef::Log.info("###   id: #{resp.change_info.id}   ###")
  Chef::Log.info("###   status: #{resp.change_info.status}   ###")
  Chef::Log.info("###   submitted_at: #{resp.change_info.submitted_at}   ###")
  Chef::Log.info("###   comment: #{resp.change_info.comment}   ###")
end
###############################


#get hosted zone ids from names
hosted_zone_ids=r53_cli_hosted_zone_names2ids(hosted_zone_names)

#fill record date
DNSName=mapped_ns #'ns1.awstest.ers.trendmicro.com.'
DNSName_element=mapped_ns.split('.')
record_type='A'
record_set_identifier="arq-#{DNSName_element[1]}-#{DNSName_element[0]}" #arq-awstest-ns1
record_region=region
record_ttl=3600
RData1=public_ip
record=[{value: RData1}]


hosted_zone_ids.each do |hostedzoneid|
  #try to get record set in each hosted zone
  res_records,bNeedUpdate,bNeedCreate = r53_get_resource_record_sets(hostedzoneid, DNSName,
                                          record_type, record_set_identifier,public_ip)
  res_records+=record

  if bNeedUpdate
    Chef::Log.info("###   Try to add: #{public_ip}   ###")
    #try to change record set in each hosted zone
    r53_change_resource_record_sets(hostedzoneid, bNeedCreate, DNSName, 
                record_type, record_set_identifier, record_region, record_ttl, res_records)
  else
      Chef::Log.info("###   #{public_ip} already in record  ###")
  end
end