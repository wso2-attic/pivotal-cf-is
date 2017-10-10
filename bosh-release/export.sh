#!/bin/bash

set -e

echo "Exporting WSO2 IS bosh release..."
bosh -e vbox create-release --tarball wso2is-bosh-release.tar.gz
echo "DONE!"
