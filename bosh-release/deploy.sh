#!/bin/bash

set -e

echo "Uploading WSO2 IS bosh release to bosh director..."
bosh -e vbox upload-release

echo "Deploying WSO2 IS bosh release..."
bosh -e vbox -d wso2is deploy wso2is-manifest.yml
echo "DONE!"
