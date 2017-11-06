# WSO2 Identity Server BOSH Release

This repository includes a BOSH release that can be used to deploy WSO2 Identity Server 5.3.0 configured to use a
MySQL datasource on BOSH Director.

## Prerequisites

1. Linux/Unix environment
2. Install [BOSH Lite](https://bosh.io/docs/bosh-lite.html#install)
3. Install [Docker](https://docs.docker.com/engine/installation/)
4. (Optional)Install [WSO2 Update Manager](http://wso2.com/wum)

## Quick Start Guide

1. Create a workspace directory
   ```
   mkdir wso2-is-bosh-workspace
   ```

2. Navigate to the workspace directory and clone this repository
    ```
    cd wso2-is-bosh-workspace
    git clone https://github.com/wso2/pivotal-cf-is --depth 1
    ```

3. Download JDK jdk-8u144-linux-x64.tar.gz binary and copy that to the workspace directory

4. Download MySQL JDBC driver mysql-connector-java-5.1.44-bin.jar binary and copy that to the workspace directory

5. Get the WSO2 Identity Server 5.3.0 WUM updated distribution or the released [distribution](https://wso2.com/identity-and-access-management) and copy that to the workspace directory.

6. Give execute permissions to the wso2-is-bosh-release\setup.sh file within your worspace directory and execute
   ```
   cd pivotal-cf-is/bosh-release
   chmod +x setup.sh
   ./setup.sh
   ```
   Executing this script will setup MySQL, BOSH environment and will deploy WSO2 IS 5.3.0 on BOSH director

7. Find the VM IP address via the bosh CLI and access the WSO2 Identity Server Store via a web browser
    ```
    bosh -e vbox vms
    ...

    Deployment 'wso2is'

    Instance                                       Process State  AZ  IPs           VM CID                                VM Type
    wso2is/08b2075d-c7e6-49f8-b223-12d989b734c2  running        -   10.244.15.21  84cac420-fd02-4884-5821-0fad60e3ce29  wso2is-resource-pool
    ...
    ```
    To ssh to the instance
    ```
    bosh -e vbox -d wso2is ssh wso2is/08b2075d-c7e6-49f8-b223-12d989b734c2
    ```
    Access the management console with URL
    ```
    http://10.244.15.21:9763/carbon/
    ```

## Additional Info

Structure of the files of this repository will be as below :
```
└── bosh-release
    ├── config
    ├── jobs
    ├── packages
    ├── src
    ├── dbscripts
    ├── create.sh
    ├── deploy.sh
    ├── export.sh
    ├── setup.sh
    ├── README.md
    └── wso2is-manifest.yml
```
To know more about BOSH CLI commands to create a bosh environment, create a bosh release and upload, refer 
bosh-release/setup.sh script. 

## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
