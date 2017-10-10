#!/bin/bash

set -e

echo "Creating WSO2 IS bosh release..."
bosh -e vbox create-release --force
