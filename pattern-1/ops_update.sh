#!/bin/bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

usage() { echo "Usage: $0 [-b <branch name>] [-u <username>] [-p <password>]" 1>&2; exit 1; }

while getopts ":b:u:p:" o; do
    case "${o}" in
        b)
            branch=${OPTARG}
            ;;
        u)
            username=${OPTARG}
            ;;
        p)
            password=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${branch}" ] || [ -z "${username}" ] || [ -z "${password}" ]; then
    usage
fi

echo "Pulling changes from branch..."
git fetch
git checkout ${branch}
# Check for changes
upstream=${1:-'@{u}'}
local=$(git rev-parse @)
remote=$(git rev-parse "$upstream")
base=$(git merge-base @ "$upstream")
if [ ${local} = ${remote} ]; then
    # up-to-date
    exit 0
elif [ ${local} = ${base} ]; then
    git pull origin ${branch}
elif [ ${remote} = ${base} ]; then
    echo "Changes made in local branch. Please revert changes and retry."
    exit 1
else
    echo "Local repository Diverged. Please revert changes and retry."
    exit 1
fi

echo "Updating tile..."
/bin/bash update.sh
rc=$?;
if [[ ${rc} != 0 ]]; then
    echo "Error occurred while updating tile. Terminating with exit code $rc"
    exit ${rc};
fi

echo "Obtaining access token..."
response=$(curl -s -k -H 'Accept: application/json;charset=utf-8' -d 'grant_type=password' -d "username=$username" -d "password=$password" -u 'opsman:' https://localhost/uaa/oauth/token)
access_token=$(echo ${response} | sed -nE 's/.*"access_token":"(.*)","token.*/\1/p')
if [ -z "$access_token" ]
then
    status_code=$(curl --write-out %{http_code} --output /dev/null -s -k -H 'Accept: application/json;charset=utf-8' -d 'grant_type=password' -d "username=$username" -d "password=$password" -u 'opsman:' https://localhost/uaa/oauth/token)
    echo "Access token could not be obtained. Status code: $status_code"
    exit 1
fi

echo "Uploading new tile..."
cd tile/product
product_dir=$(pwd)
: ${product_tile:="wso2is*.pivotal"}

# capture the exact product distribution identifiers
product_tile=$(ls ${product_tile})
tile_filepath=${product_dir}/${product_tile}

status_code=$(curl --write-out %{http_code} --output /dev/null -H "Authorization: Bearer $access_token" 'https://localhost/api/products' -F "product[file]=@$tile_filepath"  -X POST -k)
if [ ${status_code} = 200 ]; then
    echo "Updated tile successfully added to Ops Manager"
else
    echo "Error while adding tile to Ops Manager. Status code ${status_code}"
fi
