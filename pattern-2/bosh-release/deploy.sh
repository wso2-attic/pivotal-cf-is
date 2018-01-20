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

# deployment artifacts and versions
export wso2_product="wso2is"
export wso2_product_version="5.4.0"
export wso2_product_pack_identifier="${wso2_product}-${wso2_product_version}"
export wso2_product_distribution=${wso2_product_pack_identifier}"*.zip"
export wso2_product_analytics_pack_identifier="${wso2_product}-analytics-${wso2_product_version}"
export wso2_product_analytics_distribution=${wso2_product_analytics_pack_identifier}"*.zip"
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
product_db="WSO2_IS_DB"

# check if Docker has been installed
if [ ! -x "$(command -v docker)" ]; then
    echo -e "---> Please install Docker."
    exit 1
fi

# start the MySQL Docker container service
if [ ! "$(docker ps -q -f name=${mysql_docker_container})" ]; then
    echo -e "---> Starting MySQL Docker container..."
    container_id=$(docker run -d --name ${mysql_docker_container} -p 3306:3306 -e MYSQL_ROOT_PASSWORD=${mysql_root_password} -v ${PWD}/dbscripts/:/dbscripts/ mysql:5.7.19)

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

# create the product database
echo "---> Creating databases..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "DROP DATABASE IF EXISTS "${product_db}"; CREATE DATABASE "${product_db}"; "

# create the database tables
echo "---> Creating tables..."
docker exec -it ${mysql_docker_container} mysql -h${mysql_host} -u${mysql_root_username} -p${mysql_root_password} -e "USE "${product_db}"; SOURCE /dbscripts/mysql.sql;"

# create the BOSH release
./create.sh "$1"

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
echo "---> Adding route to BOSH Lite VM..."
sudo route add -net 10.244.0.0/16 gw 192.168.50.6

# list down the running VMs
echo "---> Listing VMs..."
bosh -e vbox vms
