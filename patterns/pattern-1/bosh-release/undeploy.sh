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

# check if Docker has been installed
if [ ! -x "$(command -v docker)" ]; then
    echo -e "---> Please install Docker."
    exit 1
fi

# check if Bosh CLI has been installed
if [ ! -x "$(command -v bosh)" ]; then
    echo -e "---> Please install Bosh CLI v2."
    exit 1
fi

# move to deployment folder
cd deployment

# kill and remove the running MySQL Docker container
echo -e "---> Killing MySQL Docker container..."
docker rm -f mysql-5.7 && docker ps -a

# if forced, delete the existing BOSH environment
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

sudo route delete -net 10.244.0.0/16 gw 192.168.50.6
