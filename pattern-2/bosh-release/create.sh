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

# deployment artifacts and versions (if they aren't set)
: ${wso2_product:="wso2is"}
: ${wso2_product_version:="5.4.0"}
: ${wso2_product_pack_identifier:="${wso2_product}-${wso2_product_version}"}
: ${wso2_product_distribution:=${wso2_product_pack_identifier}"*.zip"}
: ${wso2_product_analytics_pack_identifier:="${wso2_product}-analytics-${wso2_product_version}"}
: ${wso2_product_analytics_distribution:=${wso2_product_analytics_pack_identifier}"*.zip"}
: ${jdk_distribution:="jdk-8u*-linux-x64.tar.gz"}
: ${mysql_driver:="mysql-connector-java-5.1.*-bin.jar"}

# repository folder structure variables
: ${distributions:="dist"}
: ${deployment:="deployment"}

# move to the directory containing the distributions
cd ${distributions}

# capture the exact product distribution identifiers
mysql_driver=$(ls ${mysql_driver})
jdk_distribution=$(ls ${jdk_distribution})

# make copies of the WSO2 original product distributions with the generic WSO2 product identifiers
if [ ! -f ${wso2_product_pack_identifier}.zip ]; then
    cp ${wso2_product_distribution} ${wso2_product_pack_identifier}.zip
fi

if [ ! -f ${wso2_product_analytics_pack_identifier}.zip ]; then
    cp ${wso2_product_analytics_distribution} ${wso2_product_analytics_pack_identifier}.zip
fi

# check the availability of required utility software, product packs and distributions

# check if the WSO2 product distributions have been provided
if [ ! -f ${wso2_product_pack_identifier}.zip ]; then
    echo "---> WSO2 product distribution not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if the JDK distribution has been provided
if [ ! -f ${jdk_distribution} ]; then
    echo "---> Java Development Kit (JDK) distribution not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if the MySQL Connector has been provided
if [ ! -f ${mysql_driver} ]; then
    echo "---> MySQL Driver not found! Please add it to ${distributions} directory."
    exit 1
fi

# check if Bosh CLI has been installed
if [ ! -x "$(command -v bosh)" ]; then
    echo "---> Please install Bosh CLI v2."
    exit 1
fi

cd ..
# add the locally available WSO2 product distribution(s) and dependencies as blobs to the BOSH Director
echo "---> Adding blobs..."
bosh -e $1 add-blob ${distributions}/${jdk_distribution} oraclejdk/${jdk_distribution}
bosh -e $1 add-blob ${distributions}/${mysql_driver} mysqldriver/${mysql_driver}
bosh -e $1 add-blob ${distributions}/${wso2_product_pack_identifier}.zip ${wso2_product}/${wso2_product_pack_identifier}.zip
bosh -e $1 add-blob ${distributions}/${wso2_product_analytics_pack_identifier}.zip ${wso2_product}_analytics/${wso2_product_analytics_pack_identifier}.zip

echo "---> Uploading blobs..."
bosh -e $1 -n upload-blobs

# create the BOSH release
echo "---> Creating BOSH release..."
bosh -e $1 create-release --force
