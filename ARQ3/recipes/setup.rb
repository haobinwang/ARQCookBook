#include_recipe 'deploy'

#account for arq
user 'rbldnsd' do
  home '/home/rbldnsd'
end

#arq dependence
yum_package 'python26' do
  action :install
end

#arq dependence
yum_package 'python-netifaces' do
  action :install
end