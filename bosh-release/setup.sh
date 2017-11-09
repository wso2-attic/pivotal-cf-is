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

# MYSQL connection details
MYSQL_USERNAME="root"
MYSQL_PASSWORD="root"
MYSQL_HOST="127.0.0.1"

# MYSQL databases
UM_DB="WSO2_UM_DB"
IDENTITY_DB="WSO2_IDENTITY_DB"
GOV_REG_DB="WSO2_GOV_REG_DB"
BPS_DB="WSO2_BPS_DB"

# MYSQL database users
UM_USER="wso2umuser"
IDENTITY_USER="wso2identityuser"
GOV_REG_USER="wso2registryuser"
BPS_USER="wso2bpsuser"

# WSO2IS deployment artifacts
IS_PACK="../../wso2is-5.3.0*.zip"
JDK="../../jdk-8u144-linux-x64.tar.gz"
MYSQL_DRIVER="../../mysql-connector-java-5.1.44-bin.jar"

# Deployment environment variables
MYSQL_DOCKER_CONTAINER="mysql-5.7"

function deployMySQL {

    echo -e "\033[32m>> Setting up MYSQL  \033[0m"
    if [ ! "$(docker ps -aq -f name=$MYSQL_DOCKER_CONTAINER)" ]; then
        echo -e "\033[32m>> Pulling MySQL docker image... \033[0m"
        docker pull mysql/mysql-server:5.7

        echo -e "\033[32m>> Starting MySQL docker container... \033[0m"
        docker run -d --name $MYSQL_DOCKER_CONTAINER -p 3306:3306 -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD mysql/mysql-server:5.7 && docker ps -a

        checkMySQLState
    else
        if [ "$(docker inspect -f {{.State.Running}} $MYSQL_DOCKER_CONTAINER)" = "true" ]; then
            echo -e "\033[32m>> MySQL docker container is already running... \033[0m"
        else
            echo -e "\033[32m>> Starting MySQL docker container... \033[0m"
            docker start $MYSQL_DOCKER_CONTAINER && docker ps -a

            checkMySQLState
        fi
    fi
}

function checkMySQLState {

    echo -e "\033[32m>> Waiting MySQL to start on 3306... \033[0m"
    local docker_mysql_state=$(docker inspect -f {{.State.Health.Status}} mysql-5.7)
    until [ "$docker_mysql_state" = "healthy" ]; do
        sleep 1
        printf "."
        docker_mysql_state=$(docker inspect -f {{.State.Health.Status}} mysql-5.7)
    done
    local mysql_container_host=$(docker inspect -f {{.NetworkSettings.IPAddress}} $MYSQL_DOCKER_CONTAINER)
    echo ""
    echo -e "\033[32m>> MySQL Started at Host: $mysql_container_host Port: 3306. \033[0m"
}

function setupDatabases {

    echo -e "\033[32m>> Creating databases...  \033[0m"
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "DROP DATABASE IF EXISTS "$UM_DB"; DROP DATABASE IF
    EXISTS "$IDENTITY_DB"; DROP DATABASE IF EXISTS "$GOV_REG_DB"; DROP DATABASE IF EXISTS "$BPS_DB"; CREATE DATABASE
    "$UM_DB"; CREATE DATABASE "$IDENTITY_DB"; CREATE DATABASE "$GOV_REG_DB"; CREATE DATABASE "$BPS_DB";"

    echo -e "\033[32m>> Creating users...  \033[0m"
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "DROP USER IF EXISTS '$UM_USER'@'%'; DROP USER IF
    EXISTS '$IDENTITY_USER'@'%'; DROP USER IF EXISTS '$GOV_REG_USER'@'%'; DROP USER IF EXISTS '$BPS_USER'@'%'; FLUSH
    PRIVILEGES; CREATE USER '$UM_USER'@'%' IDENTIFIED BY '$UM_USER'; CREATE USER '$IDENTITY_USER'@'%' IDENTIFIED BY
    '$IDENTITY_USER'; CREATE USER '$GOV_REG_USER'@'%' IDENTIFIED BY '$GOV_REG_USER'; CREATE USER '$BPS_USER'@'%'
    IDENTIFIED BY '$BPS_USER';"

    echo -e "\033[32m>> Grant access for users...  \033[0m"
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $UM_DB.* TO '$UM_USER'@'%';
    GRANT ALL PRIVILEGES ON $IDENTITY_DB.* TO '$IDENTITY_USER'@'%'; GRANT ALL PRIVILEGES ON $GOV_REG_DB.* TO
    '$GOV_REG_USER'@'%'; GRANT ALL PRIVILEGES ON $BPS_DB.* TO '$BPS_USER'@'%';"

    echo -e "\033[32m>> Creating tables...  \033[0m"
    mysql -h $MYSQL_HOST -u $MYSQL_USERNAME -p$MYSQL_PASSWORD -e "USE "$UM_DB"; SOURCE dbscripts/mysql-5.7/um-mysql.sql;
    USE "$IDENTITY_DB"; SOURCE dbscripts/mysql-5.7/identity-mysql.sql; USE "$GOV_REG_DB";
    SOURCE dbscripts/mysql-5.7/gov-registry-mysql.sql; USE "$BPS_DB"; SOURCE dbscripts/mysql-5.7/bps-mysql.sql;"
}

function deployBoshEnvironment {

    echo -e "\033[32m>> Setting up BOSH environment  \033[0m"
    if [ ! -d ../../bosh-deployment ]; then
        echo -e "\033[32m>>  Cloning https://github.com/cloudfoundry/bosh-deployment... \033[0m"
        git clone https://github.com/cloudfoundry/bosh-deployment ../../bosh-deployment --depth 1
    fi

    if [ ! -d ../../vbox ]; then
        echo -e "\033[32m>>  Creating environment dir... \033[0m"
        mkdir ../../vbox
    fi

    echo -e "\033[32m>> Creating environment... \033[0m"
    bosh create-env ../../bosh-deployment/bosh.yml \
        --state ../../vbox/state.json \
        -o ../../bosh-deployment/virtualbox/cpi.yml \
        -o ../../bosh-deployment/virtualbox/outbound-network.yml \
        -o ../../bosh-deployment/bosh-lite.yml \
        -o ../../bosh-deployment/bosh-lite-runc.yml \
        -o ../../bosh-deployment/jumpbox-user.yml \
        --vars-store ../../vbox/creds.yml \
        -v director_name="Bosh Lite Director" \
        -v internal_ip=192.168.50.6 \
        -v internal_gw=192.168.50.1 \
        -v internal_cidr=192.168.50.0/24 \
        -v outbound_network_name=NatNetwork

    echo -e "\033[32m>> Setting alias for the environment... \033[0m"
    bosh -e 192.168.50.6 alias-env vbox --ca-cert <(bosh int ../../vbox/creds.yml --path /director_ssl/ca)

    echo -e "\033[32m>> Login in... \033[0m"
    bosh -e vbox login --client=admin --client-secret=$(bosh int ../../vbox/creds.yml --path /admin_password)

    echo -e "\033[32m>> Adding blobs... \033[0m"
    bosh -e vbox add-blob ../../jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
    bosh -e vbox add-blob ../../mysql-connector-java-5.1.44-bin.jar mysqldriver/mysql-connector-java-5.1.44-bin.jar
    bosh -e vbox add-blob ../../wso2is-5.3.0*.zip wso2is/wso2is-5.3.0.zip


    echo -e "\033[32m>> Uploading blobs... \033[0m"
    bosh -e vbox -n upload-blobs

    echo -e "\033[32m>> Creating bosh release... \033[0m"
    bosh -e vbox create-release --force

    echo -e "\033[32m>> Uploading bosh release... \033[0m"
    bosh -e vbox upload-release

    if [ ! -f ../../bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz ]; then
        echo -e "\033[32m>> Stemcell does not exist! Downloading... \033[0m"
        wget -P ../../ https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz
    fi

    echo -e "\033[32m>> Uploading Stemcell... \033[0m"
    bosh -e vbox upload-stemcell ../../bosh-stemcell-3445.7-warden-boshlite-ubuntu-trusty-go_agent.tgz

    echo -e "\033[32m>> Deploying bosh release... \033[0m"
    yes | bosh -e vbox -d wso2is deploy wso2is-manifest.yml

    echo -e "\033[32m>> Listing VMs... \033[0m"
    bosh -e vbox vms
}

function addRouteToBOSHVMNetwork {

    if [ $(uname) = "Darwin" ]; then
        routeExists=$(netstat -rn | grep 10.244/16 | wc -l)
        if [ ${routeExists} = 0 ]; then
            echo -e "\033[32m>> Adding route... \033[0m"
            sudo route -n add 10.244.0.0/16 192.168.50.6
        fi
    elif [ $(uname) = "Linux" ]; then
        routeExists=$(ip route show 10.244.0.0/16 | wc -l)
        if [ ${routeExists} = 0 ]; then
            echo -e "\033[32m>> Adding route... \033[0m"
            sudo route add -net 10.244.0.0/16 gw 192.168.50.6
        fi
    fi
}

function undeployMySQL {

    echo -e "\033[32m>> Tearing down MYSQL  \033[0m"
    if [ ! "$(docker ps -aq -f name=$MYSQL_DOCKER_CONTAINER)" ]; then
        echo -e "\033[32m>> No MYSQL docker container found! \033[0m"
    else
        if [ "$(docker ps -aq -f status=exited -f name=$MYSQL_DOCKER_CONTAINER)" ]; then
            echo -e "\033[32m>> Removing MySQL docker container... \033[0m"
            docker rm $MYSQL_DOCKER_CONTAINER && docker ps -a
        else
            echo -e "\033[32m>> Killing MySQL docker container... \033[0m"
            docker rm $(docker stop mysql-5.7) && docker ps -a
        fi
    fi
}

function undeployBoshEnvironment {

    echo -e "\033[32m>> Deleting existing environment... \033[0m"
    bosh delete-env ../../bosh-deployment/bosh.yml \
        --state ../../vbox/state.json \
        -o ../../bosh-deployment/virtualbox/cpi.yml \
        -o ../../bosh-deployment/virtualbox/outbound-network.yml \
        -o ../../bosh-deployment/bosh-lite.yml \
        -o ../../bosh-deployment/bosh-lite-runc.yml \
        -o ../../bosh-deployment/jumpbox-user.yml \
        --vars-store ../../vbox/creds.yml \
        -v director_name="Bosh Lite Director" \
        -v internal_ip=192.168.50.6 \
        -v internal_gw=192.168.50.1 \
        -v internal_cidr=192.168.50.0/24 \
        -v outbound_network_name=NatNetwork
}

function removeRouteToBOSHVMNetwork {

    if [ $(uname) = "Darwin" ]; then
        routeExists=$(netstat -rn | grep 10.244/16 | wc -l)
        if [ ${routeExists} = 1 ]; then
            echo -e "\033[32m>> Removing route... \033[0m"
            sudo route -n delete 10.244.0.0/16 192.168.50.6
        fi
    elif [ $(uname) = "Linux" ]; then
        routeExists=$(ip route show 10.244.0.0/16 | wc -l)
        if [ ${routeExists} = 1 ]; then
            echo -e "\033[32m>> Removing route... \033[0m"
            sudo route delete -net 10.244.0.0/16 gw 192.168.50.6
        fi
    fi
}

function verifyPrerequisites {

    if [ ! -f $IS_PACK ]; then
        echo -e "\033[31m>> IS 5.3.0 pack not found! \033[0m"
        exit 1
    fi

    if [ ! -f $JDK ]; then
        echo -e "\033[31m>> JDK distribution (jdk-8u144-linux-x64.tar.gz) not found! \033[0m"
        exit 1
    fi

    if [ ! -f $MYSQL_DRIVER ]; then
        echo -e "\033[31m>> MySQL Driver (mysql-connector-java-5.1.44-bin.jar) not found! \033[0m"
        exit 1
    fi

    if [ ! -x "$(command -v mysql)" ]; then
        echo -e "\033[31m>> Please install MySQL client. \033[0m"
        exit 1
    fi

    if [ ! -x "$(command -v git)" ]; then
        echo -e "\033[31m>> Please install Git client. \033[0m"
        exit 1
    fi

    if [ ! -x "$(command -v docker)" ]; then
        echo -e "\033[31m>> Please install Docker. \033[0m"
        exit 1
    fi
}

function usage {

    command=$0
    echo -e "\033[32m usage: $command -[deploy|undeploy] \033[0m"
    echo -e "\033[32m  -deploy     setup mysql and deploy wso2is in bosh \033[0m"
    echo -e "\033[32m  -undeploy   cleanup mysql and wso2is bosh environment \033[0m"
}

function deploy {

    deployMySQL
    setupDatabases
    deployBoshEnvironment
    addRouteToBOSHVMNetwork
}

function undeploy {

    undeployMySQL
    undeployBoshEnvironment
    removeRouteToBOSHVMNetwork
}


verifyPrerequisites

if [[ ($# = 0 || "$1" = "deploy" || "$1" = "-deploy" || "$1" = "--deploy") ]]; then
    echo -e "\033[32m>> Deploy... \033[0m"
    deploy
elif [[ ("$1" = "undeploy" || "$1" = "-undeploy" || "$1" = "--undeploy") ]]; then
    echo -e "\033[32m>> Undeploy... \033[0m"
    undeploy
else
    echo -e "\033[31m>> Invalid command. Please check usage. \033[0m"
    usage
    exit 1
fi


