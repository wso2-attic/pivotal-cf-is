# BOSH release for WSO2 Identity Server deployment pattern 1

This directory contains the BOSH release implementation for WSO2 Identity Server 5.7.0
[deployment pattern 1](https://docs.wso2.com/display/IS541/Deployment+Patterns#DeploymentPatterns-Pattern1-HAclustereddeploymentofWSO2IdentityServer).

![WSO2 Identity Server 5.7.0 deployment pattern 1](images/pattern-1.png)

The following sections provide general steps required for managing the WSO2 Identity Server 5.7.0 deployment pattern 1
BOSH release in a BOSH environment deployed in the desired IaaS.

For step-by-step guidelines to manage the BOSH release in specific environments, refer the following:

## Contents

* [Prerequisites](#prerequisites)
* [Create Release](#create-release)
* [Deploy Release](#deploy-release)
* [Output](#output)
* [Delete Deployment](#delete-deployment)
* [BOSH Release Structure](#bosh-release-structure)
* [References](#references)

## Prerequisites

1. Install the following software:

    - [BOSH Command Line Interface (CLI) v2+](https://bosh.io/docs/cli-v2.html)
    - [WSO2 Update Manager (WUM)](http://wso2.com/wum)
    - [Git client](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
    - Software requirements specific to the IaaS

2. Obtain the following software distributions.

    - WSO2 Identity Server 5.7.0 WUM updated product distribution
    - [Java Development Kit (JDK) 1.8](https://adoptopenjdk.net/archive.html)
    - Relevant Java Database Connectivity (JDBC) connector (e.g. [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/5.1.html)
    if the external DBMS used is MySQL)

3. Clone this Git repository.

    ```
    git clone https://github.com/wso2/pivotal-cf-is
    ```

   **Note**: In the remaining sections, the project root directory has been referred to as, **pivotal-cf-is**.

## Create the BOSH release

In order to create the BOSH release for deployment pattern 1, you must follow the standard steps for creating a release with BOSH.

1. Move to root directory of the deployment pattern 1 BOSH release.

    ```
    cd pivotal-cf-is/pattern-1/bosh-release/
    ```   

2. Create the BOSH release.
    ```
    ./create.sh
    ```
3. Export the BOSH release as a tarball.
    ```
    ./export.sh
    ```
## Build the CF tile.

In order to build the CF tile for deployment pattern 1, follow the below steps.

1. Move the BOSH release tarball created in the above step to the root of tile directory and navigate into it.

    ```
    mv wso2is-5.7.0-bosh-release.tgz ../tile/
    cd ../tile/
    ```   

2. Build the tile.
    ```
    ./build.sh
    ```
3. The tile will be created in the root of the ```product``` folder under tile directory.

4. Upload the tile to the Pivotal Environment and configure it.


## Output

To find the IP addresses of created instances via the BOSH CLI and access the WSO2 Identity Server management console via a web browser,

1. List all the deployments.

    ```
    bosh deployments
    ```

2. List all the instances within a deployment.

    ```
    bosh vms -d <Name>
    ```
3. SSH into the vm as follows.

    ```
    bosh -d <Name> ssh <Instance>
    ```

4. Access the WSO2 Identity Server management console URL using the static IPs of the created instances.

    ```
    https://wso2is.sys.<domain_name>/carbon
    ```

## Delete deployment

1. Delete the deployment.

    ```
    bosh -e <environment-alias> -d wso2is-pattern-1 delete-deployment
    ```

2. **[Optional]** Cleanup the BOSH release, stemcell, disks and etc.

    ```
    bosh -e <environment-alias> clean-up --all
    ```

## BOSH release structure

Structure of the directories and files of the BOSH release is as follows:

```
└── bosh-release
    ├── config
    ├── images
    ├── manifests
    ├── jobs
    ├── packages
    ├── src
    ├── create.sh
    ├── export.sh
    └── README.md
```

## References

* [BOSH CLI v2 commands](https://bosh.io/docs/cli-v2.html)
