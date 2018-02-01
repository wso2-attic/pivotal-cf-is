#!/bin/bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

# exit immediately if a command exits with a non-zero status
set -e

# set variables
os_name=`uname`

# deployment artifacts and versions
export wso2_product="wso2is"
export wso2_product_version="5.4.0"
export wso2_product_pack_identifier="${wso2_product}-${wso2_product_version}"
export wso2_product_distribution=${wso2_product_pack_identifier}"*.zip"
export jdk_distribution="jdk-8u*-linux-x64.tar.gz"
export mysql_driver="mysql-connector-java-5.1.*-bin.jar"

# repository folder structure variables
export distributions="dist"
export deployment="deployment"

# deployment variables
mysql_docker_container="mysql-5.7"

# MySQL connection details
mysql_root_username="root"
mysql_root_password="root"
mysql_host="127.0.0.1"

# MySQL databases
product_db=${wso2_product}_db

# check if Docker has been installed
if [ ! -x "$(command -v docker)" ]; then
    echo "---> Please install Docker."
    exit 1
fi

# check if Git has been installed
if [ ! -x "$(command -v git)" ]; then
    echo "---> Please install Git client."
    exit 1
fi

# check if Bosh CLI has been installed
if [ ! -x "$(command -v bosh)" ]; then
    echo "---> Please install Bosh CLI v2."
    exit 1
fi

# start the MySQL Docker container service
if [ ! "$(docker ps -q -f name=${mysql_docker_container})" ]; then
    echo "---> Starting MySQL Docker container..."
    container_id=$(docker run -d --name ${mysql_docker_container} -p 3306:3306 -e MYSQL_ROOT_PASSWORD=${mysql_root_password} -v ${PWD}/dbscripts/:/dbscripts/ mysql:5.7.19)

    if [[ "${os_name}" == 'Darwin' ]]; then
        docker_host_ip=$(ipconfig getifaddr en0)
    else
        docker_host_ip=$(/sbin/ifconfig docker0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
    fi

    echo "---> Waiting for MySQL service to start on ${docker_host_ip}:3306..."

    while [ $(docker logs ${mysql_docker_container} 2>&1 | grep "mysqld: ready for connections" | wc -l) -ne 2 ]; do
        printf '.'
        sleep 1
    done
    echo ""
    echo "---> MySQL service started."
else
    echo "---> MySQL service is already running..."
fi

# print out the information of the created Docker container
docker ps -a

# create the product database
echo "---> Creating databases..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "DROP DATABASE IF EXISTS "${product_db}"; CREATE DATABASE "${product_db}"; "

# create the database tables
echo "---> Creating tables..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "USE "${product_db}"; SOURCE /dbscripts/mysql.sql;"

# move to the deployment directory
cd ${deployment}

# Git clone the collection of BOSH manifests referenced by cloudfoundry/docs-bosh, required to create the BOSH environment
if [ ! -d bosh-deployment ]; then
    echo "---> Cloning https://github.com/cloudfoundry/bosh-deployment..."
    git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
fi

# create a directory to hold the configuration files for VirtualBox specific BOSH environment
if [ ! -d vbox ]; then
    echo "---> Creating environment directory..."
    mkdir vbox
fi

# if forced, delete any existing BOSH environment
if [ "$1" == "--force" ]; then
    echo "---> Deleting existing BOSH environment..."
    bosh delete-env bosh-deployment/bosh.yml \
        --state vbox/state.json \
        -o bosh-deployment/virtualbox/cpi.yml \
        -o bosh-deployment/virtualbox/outbound-network.yml \
        -o bosh-deployment/bosh-lite.yml \
        -o bosh-deployment/bosh-lite-runc.yml \
        -o bosh-deployment/jumpbox-user.yml \
        --vars-store vbox/creds.yml \
        -v director_name="Bosh Lite Director" \
        -v internal_ip=192.168.50.6 \
        -v internal_gw=192.168.50.1 \
        -v internal_cidr=192.168.50.0/24 \
        -v outbound_network_name=NatNetwork
fi

# create a new BOSH environment with BOSH Lite as the BOSH Director and VirtualBox as the IaaS
echo "---> Creating the BOSH environment..."
bosh create-env bosh-deployment/bosh.yml \
    --state vbox/state.json \
    -o bosh-deployment/virtualbox/cpi.yml \
    -o bosh-deployment/virtualbox/outbound-network.yml \
    -o bosh-deployment/bosh-lite.yml \
    -o bosh-deployment/bosh-lite-runc.yml \
    -o bosh-deployment/jumpbox-user.yml \
    --vars-store vbox/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name=NatNetwork

# set an alias for the created BOSH environment
echo "---> Setting alias for the environment..."
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

# log into the created BOSH environment
echo "---> Logging in..."
bosh -e vbox login --client=admin --client-secret=$(bosh int vbox/creds.yml --path /admin_password)

cd ..
# create the BOSH release
./create.sh vbox

# upload the BOSH release to the BOSH Director
echo "---> Uploading BOSH release..."
bosh -e vbox upload-release

# check if the BOSH Stemcell is present and if not provided, download it
if [ ! -f ${distributions}/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
    echo "---> Stemcell does not exist! Downloading..."
    wget --directory-prefix=${distributions} https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
fi

# upload the BOSH Stemcell to the BOSH Director
echo "---> Uploading Stemcell..."
bosh -e vbox upload-stemcell ${distributions}/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

# deploy the BOSH release
echo "---> Deploying BOSH release..."
yes | bosh -e vbox -d wso2is deploy wso2is-manifest.yml

# add a route to BOSH Lite VM created earlier
echo "---> Adding route to BOSH lite VM..."
if [[ "$os_name" == 'Darwin' ]]; then
    sudo route add -net 10.244.0.0/16 192.168.50.6
else
    sudo ip route add 10.244.0.0/16 via 192.168.50.6
fi

# list down the running VMs
echo "---> Listing VMs..."
bosh -e vbox vms
