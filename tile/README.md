# WSO2 Identity Server Pivotal Cloud Foundry Tile

This repository includes a Cloud Foundry Tile for deploying WSO2 Identity Server 5.3.0 on BOSH via Pivotal Ops Manager.

## Prerequisites

1. Linux/Unix environment
2. Install [BOSH Lite](https://bosh.io/docs/bosh-lite.html#install)
3. Install [Tile Generator](https://docs.pivotal.io/tiledev/tile-generator.html)

## Quick Start Guide

1. Clone this repository
    ```
    git clone https://github.com/wso2/pivotal-cf-is
    ```
    
2. Navigate to the pivotal-cf-is/bosh-release directory and execute export.sh
   ```
   cd pivotal-cf-is/bosh-release
   ./export.sh
   ```
   Executing this script will generate a BOSH release tarball for WSO2 IS 5.3.0

3. Navigate to pivotal-cf-is/tile directory and build the tile as below
    ```
    tile build 
    ```

## References

* [PCF Tile Developers Guide](https://docs.pivotal.io/tiledev/index.html)
