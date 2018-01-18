# BOSH release for WSO2 Identity Server deployment pattern 1

This repository includes a BOSH release that can be used to deploy WSO2 Identity Server 5.4.0 deployment pattern 1
configured to use a MySQL database on BOSH Director.

## Prerequisites

Install the following software:

1. [BOSH CLI](https://bosh.io/docs/cli-v2.html)
2. [Docker](https://docs.docker.com/engine/installation/)
3. [VirtualBox](https://www.virtualbox.org/manual/ch02.html)
4. [WSO2 Update Manager](http://wso2.com/wum)
5. [Git client](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Quick Start Guide

1. Clone this Git repository
    ```
    git clone https://github.com/wso2/pivotal-cf-is
    ```

2. Navigate to `pivotal-cf-is/patterns/pattern-1/bosh-release` directory.

3. Add the following software distributions to the `dist` folder.

- [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

- [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/5.1.html)

- WSO2 Identity Server 5.4.0 WUM updated product distribution

4. Execute the deploy.sh script.
   ```
   ./deploy.sh
   ```
   Executing this script will setup MySQL, BOSH environment and will deploy WSO2 IS 5.4.0 deployment pattern 1 on BOSH director.

5. Find the IP addresses of created VMs via the BOSH CLI and access the WSO2 Identity Server Store via a web browser.
    ```
    bosh -e vbox vms
    ...
    
    Deployment 'wso2is'
    
    Instance                                       Process State  AZ  IPs          VM CID                                VM Type  
    wso2is_1/b277265a-6f11-4b59-a82d-87e14b01f898  running        -   10.244.15.2  c5a75be1-8acd-4d09-7a99-4cec2795ed15  wso2is-resource-pool  
    wso2is_2/1030d639-4b02-48e5-83b0-0ca6ed79fecb  running        -   10.244.15.3  f10c0fc0-7573-4fde-673f-9b6d25ef124c  wso2is-resource-pool  
    
    2 vms
    
    Succeeded
    ...
    ```
    To ssh to the instance
    ```
    bosh -e vbox -d wso2is ssh wso2is_1/b277265a-6f11-4b59-a82d-87e14b01f898
    ```
    Access the management console with URL
    ```
    https://10.244.15.2:9443/carbon/
    ```

## Additional Info

Structure of the files of this repository will be as below :
```
└── bosh-release
    ├── config
    ├── dbscripts
    ├── deployment
    ├── dist
    ├── jobs
    ├── packages
    ├── src
    ├── deploy.sh
    ├── undeploy.sh
    ├── README.md
    └── wso2is-manifest.yml
```
To know more about BOSH CLI commands to create a bosh environment, create a bosh release and upload, refer deploy.sh script.

## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
