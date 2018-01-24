# BOSH release for WSO2 Identity Server deployment pattern 2

This repository includes a BOSH release that can be used to deploy WSO2 Identity Server 5.4.0 deployment pattern 2
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
    
2. Navigate to `pivotal-cf-is/pattern-2/bosh-release` directory.

3. Add the following software distributions to the `dist` folder.

- [JDK 1.8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)

- [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/5.1.html)

- WSO2 Identity Server 5.4.0 WUM updated product distribution

- WSO2 Identity Server Analytics 5.4.0 WUM updated product distribution

4. Execute the deploy.sh script.
   ```
   ./deploy.sh
   ```
   Executing this script will setup MySQL, BOSH environment and will deploy WSO2 IS 5.4.0 deployment pattern 2 on BOSH director.

5. Find the IP addresses of created VMs via the BOSH CLI and access the WSO2 Identity Server and Analytics management consoles via a web browser.
    ```
    bosh -e vbox vms
    ...
    
    Deployment 'wso2is'
    
    Instance                                               Process State  AZ  IPs          VM CID                                VM Type  
    wso2is_1/b107e62a-97b1-4d4f-bbbb-f9f6abdc6bfe          running        -   10.244.15.2  074f1216-060e-4415-63df-451ee1cd40f5  wso2is-resource-pool  
    wso2is_2/d2757586-befb-4a31-8895-efe6f3a44b71          running        -   10.244.15.3  90823071-f5a7-4404-6d27-8c1a981ba142  wso2is-resource-pool  
    wso2is_analytics/b90f2ad8-42a3-4cc1-ab54-bebb6b87a172  running        -   10.244.15.4  1f685899-a4ae-4375-5fb1-a5c49b962e22  wso2is-resource-pool  
    
    3 vms
    
    Succeeded
    ...
    ```
    To ssh into an instance
    ```
    bosh -e vbox -d wso2is ssh <instance_id>
    e.g. bosh -e vbox -d wso2is ssh wso2is_1/b107e62a-97b1-4d4f-bbbb-f9f6abdc6bfe
    ```
    Access the management console with URL
    ```
    WSO2 Identity Server management console: https://10.244.15.2:9443/carbon/
    WSO2 Identity Server Analytics management console: https://10.244.15.4:9444/carbon/
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
    ├── create.sh
    ├── deploy.sh
    ├── export.sh
    ├── undeploy.sh
    ├── README.md
    └── wso2is-manifest.yml
```
To know more about BOSH CLI commands to create a bosh environment, create a bosh release and upload, refer deploy.sh script.

## References

* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
