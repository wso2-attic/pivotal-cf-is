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

set -e

# deployment artifacts and versions
wso2_product="wso2is"
wso2_product_version="5.4.0"
wso2_product_pack_identifier="${wso2_product}-${wso2_product_version}"
wso2_product_distribution=${wso2_product_pack_identifier}"*.zip"
jdk_distribution="jdk-8u*-linux-x64.tar.gz"
mysql_driver="mysql-connector-java-5.1.*-bin.jar"

# repository folder structure variables
distributions="dist"
deployment="deployment"

# deployment variables
mysql_docker_container="mysql-5.7"

# MySQL connection details
mysql_root_username="root"
mysql_root_password="root"
mysql_host="127.0.0.1"

# MySQL databases
identity_db="WSO2_IDENTITY_DB"

# MySQL database users
identity_user="wso2identityuser"

# check the availability of required utility software, product packs and distributions

# check if the WSO2 Identity Server product distribution has been provided
if [ ! -f ${distributions}/${wso2_product_distribution} ]; then
    echo -e "---> WSO2 Identity Server product distribution not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if the JDK distribution has been provided
if [ ! -f ${distributions}/${jdk_distribution} ]; then
    echo -e "---> Java Development Kit (JDK) distribution not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if the MySQL Connector has been provided
if [ ! -f ${distributions}/${mysql_driver} ]; then
    echo -e "---> MySQL Driver not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if Docker has been installed
if [ ! -x "$(command -v docker)" ]; then
    echo -e "---> Please install Docker."
    exit 1
fi

# check if Git has been installed
if [ ! -x "$(command -v git)" ]; then
    echo -e "---> Please install Git client."
    exit 1
fi

# check if Bosh CLI has been installed
if [ ! -x "$(command -v bosh)" ]; then
    echo -e "---> Please install Bosh CLI v2."
    exit 1
fi

# start the MySQL Docker container service
if [ ! "$(docker ps -q -f name=${mysql_docker_container})" ]; then
    echo -e "---> Starting MySQL Docker container..."
    container_id=$(docker run -d --name ${mysql_docker_container} -p 3306:3306 -e MYSQL_ROOT_PASSWORD=${mysql_root_password} -v ${PWD}/dbscripts/mysql-5.7/:/dbscripts/ mysql:5.7.19)

    echo -e "---> Waiting for MySQL service to start..."

    while [ $(docker logs ${mysql_docker_container} 2>&1 | grep "mysqld: ready for connections" | wc -l) -ne 2 ]; do
        printf '.'
        sleep 1
    done
    echo ""
    echo -e "---> MySQL service started."
else
    echo -e "---> MySQL service is already running..."
fi

# print out the information of the created Docker container
docker ps -a

echo -e "---> Creating databases..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "DROP DATABASE IF EXISTS "${identity_db}"; CREATE DATABASE "${identity_db}";"

echo -e "---> Creating users..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "DROP USER IF EXISTS '${identity_user}'@'%'; FLUSH PRIVILEGES; CREATE USER '${identity_user}'@'%' IDENTIFIED BY '${identity_user}';"

echo -e "---> Grant access for users..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "GRANT ALL PRIVILEGES ON ${identity_db}.* TO '${identity_user}'@'%'; FLUSH PRIVILEGES;"

echo -e "---> Creating tables..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "USE "${identity_db}"; SOURCE /dbscripts/identity-mysql.sql; SOURCE /dbscripts/um-mysql.sql; SOURCE /dbscripts/bps-mysql.sql;"

cd ${distributions}

wso2_product_distribution=$(ls ${wso2_product_distribution})
mysql_driver=$(ls ${mysql_driver})

if [ ! -f ${wso2_product_pack_identifier}.zip ]; then
    cp ${wso2_product_distribution} ${wso2_product_pack_identifier}.zip
fi

cd ../${deployment}

if [ ! -d bosh-deployment ]; then
    echo -e "---> Cloning https://github.com/cloudfoundry/bosh-deployment..."
    git clone https://github.com/cloudfoundry/bosh-deployment bosh-deployment
fi

if [ ! -d vbox ]; then
    echo -e "---> Creating environment directory..."
    mkdir vbox
fi

if [ "$1" == "--force" ]; then
    echo -e "---> Deleting existing environment..."
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

echo -e "---> Creating environment..."
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

echo -e "---> Setting alias for the environment..."
bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int vbox/creds.yml --path /director_ssl/ca)

echo -e "---> Logging in..."
bosh -e vbox login --client=admin --client-secret=$(bosh int vbox/creds.yml --path /admin_password)

cd ..
echo -e "---> Adding blobs..."
bosh -e vbox add-blob ${distributions}/jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
bosh -e vbox add-blob ${distributions}/${mysql_driver} mysqldriver/${mysql_driver}
bosh -e vbox add-blob ${distributions}/${wso2_product_distribution} wso2is/${wso2_product_pack_identifier}.zip

echo -e "---> Uploading blobs..."
bosh -e vbox -n upload-blobs

echo -e "---> Creating bosh release..."
bosh -e vbox create-release --force

echo -e "---> Uploading bosh release..."
bosh -e vbox upload-release

if [ ! -f ${distributions}/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
    echo -e "---> Stemcell does not exist! Downloading..."
    wget --directory-prefix=${distributions} https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
fi

echo -e "---> Uploading Stemcell..."
bosh -e vbox upload-stemcell ${distributions}/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

echo -e "---> Deploying bosh release..."
yes | bosh -e vbox -d wso2is deploy wso2is-manifest.yml

echo -e "---> Adding route to bosh lite VM..."
sudo route add -net 10.244.0.0/16 gw 192.168.50.6

echo -e "---> Listing VMs..."
bosh -e vbox vms
