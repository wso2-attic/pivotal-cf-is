# BOSH release for WSO2 Identity Server deployment pattern 1

This directory contains the BOSH release implementation for WSO2 Identity Server 5.4.0
[deployment pattern 1](https://docs.wso2.com/display/IS540/Deployment+Patterns#DeploymentPatterns-Pattern1-HAclustereddeploymentofWSO2IdentityServer).

![WSO2 Identity Server 5.4.0 deployment pattern 1](images/pattern-1.png)

The following sections provide step-by-step guidelines for managing the WSO2 Identity Server 5.4.0 deployment pattern 1 BOSH release.

For clarity, examples for the relevant steps have been provided for managing the BOSH release in a [BOSH Lite](https://bosh.io/docs/bosh-lite) environment.

## Prerequisites

1. Install the following software:

    - [BOSH Command Line Interface (CLI) v2+](https://bosh.io/docs/cli-v2.html)
    - [WSO2 Update Manager (WUM)](http://wso2.com/wum)
    - [Git client](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
    
2. Obtain the following software distributions.

    - WSO2 Identity Server 5.4.0 WUM updated product distribution
    - [Java Development Kit (JDK) 1.8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
    - [MySQL JDBC driver](https://dev.mysql.com/downloads/connector/j/5.1.html)
    
3. Clone this Git repository.

    ```
    git clone https://github.com/wso2/pivotal-cf-is
    ```
    
   **Note**: In the remaining sections, the project root directory has been referred to as, **pivotal-cf-is**.

## Create the BOSH Release

In order to create the BOSH release for deployment pattern 1, you must follow the standard steps for creating a release with BOSH.
 
1. Move to `.deployment` directory of the deployment pattern 1 BOSH release.

    ```
    cd <pivotal-cf-is>/pattern-1/bosh-release/.deployment
    ```   
    
2. Create a BOSH environment and login to it.

    Please refer the [BOSH documentation](http://bosh.io/docs/init.html) for instructions on creating a BOSH environment in the desired IaaS.

    **e.g.** Steps to create a BOSH environment with BOSH Lite as Director VM and login to it, can be found from
    [here](http://bosh.io/docs/bosh-lite.html#install).
    
    Once you setup the BOSH Lite environment, visit the VirtualBox application to confirm a new VM has been created.
    
    ![BOSH Lite VM](images/bosh-lite.png)

3. Move back to the root directory of deployment pattern 1 BOSH release (`<pivotal-cf-is>/pattern-1/bosh-release`).

    ```
    cd ..
    ```

4. Add the WSO2 Identity Server 5.4.0 WUM updated product distribution, JDK distribution and MySQL JDBC driver in the form of release blobs.

    Here, the **environment-alias** refers to the alias provided when saving the created environment, in step 2.

    ```
    bosh -e <environment-alias> add-blob <local_system_path_to_JDK_distribution> oraclejdk/jdk-8u<update-version>-linux-x64.tar.gz
    bosh -e <environment-alias> add-blob <local_system_path_to_MySQL_driver> mysqldriver/mysql-connector-java-<version>-bin.jar
    bosh -e <environment-alias> add-blob <local_system_path_to_WSO2_IS_distribution> wso2is/wso2is-<version>.zip
    ```

    **e.g.**
    Assuming that,

   - the created BOSH environment (with BOSH Lite as the Director) was saved with alias `vbox`, in step 2
   - the required binaries reside within `~/Downloads` directory
    
    ```
    bosh -e vbox add-blob ~/Downloads/jdk-8u144-linux-x64.tar.gz oraclejdk/jdk-8u144-linux-x64.tar.gz
    bosh -e vbox add-blob ~/Downloads/mysql-connector-java-5.1.34-bin.jar mysqldriver/mysql-connector-java-5.1.34-bin.jar
    bosh -e vbox add-blob ~/Downloads/wso2is-5.4.0.zip wso2is/wso2is-5.4.0.zip
    ```

5. **[Optional]** If the BOSH release is a final release, upload the blobs (added in step 4). Please refer
[BOSH documentation](https://bosh.io/docs/create-release.html#upload-blobs) for further details.

    **e.g.**
    ```
    bosh -e vbox -n upload-blobs
    ```

6. Create the BOSH release.

   - Dev release:
   ```
   bosh -e <environment-alias> create-release --force
   ```
   Please refer [BOSH Documentation](https://bosh.io/docs/create-release.html#dev-release) for detailed information on creating a dev release.
   
   - Final release:
   ```
   bosh -e <environment-alias> create-release
   ```
   Please refer [BOSH Documentation](https://bosh.io/docs/create-release.html#final-release) for detailed information on creating a final release.

## Deploy the BOSH Release

1. Setup and configure external product MySQL database(s).

    - Following table shows the external product database configurations, which have been set as properties under WSO2 Identity Server job specifications
    (**e.g.** see `properties` section under `<pivotal-cf-is>/pattern-1/bosh-release/jobs/wso2is_<job_number>/spec`).
    
   <br>
   
   Property | Description | Default
   -------- | ----------- | -------
   wso2is.mysql.host | Hostname/IP of the MySQL server in which WSO2 Identity Server product database resides. | 192.168.50.1
   wso2is.mysql.product_db | Name of the WSO2 Identity Server product database. | wso2is_db
   wso2is.product_db.username | Username of the WSO2 Identity Server product database user. | root
   wso2is.product_db.password | Password of the WSO2 Identity Server product database user. | root
      
   If you customize any of the above configurations in following steps, change the default property values to customized values in each job specification.
    
   - Create the product database. For this purpose, execute the `<pivotal-cf-is>/pattern-1/bosh-release/dbscripts/mysql.sql` script.
        
    ```
    DROP DATABASE IF EXISTS <wso2is.mysql.product_db>; CREATE DATABASE <wso2is.mysql.product_db>;
    USE <wso2is.mysql.product_db>; SOURCE /dbscripts/mysql.sql;
    ```
   
   This will create the tables to hold user management data, identity related data and workflow feature data
   (see [Setting Up Separate Databases for Clustering](https://docs.wso2.com/display/IS541/Setting+Up+Separate+Databases+for+Clustering)).

2. Move to the root directory of deployment pattern 1 BOSH release.

    ```
    cd <pivotal-cf-is>/pattern-1/bosh-release
    ```
    
3. Upload the deployment pattern 1 BOSH release.

    ```
    bosh -e <environment-alias> upload-release
    ```

4. Upload the desired stemcell directly to BOSH. [bosh.io](http://bosh.io/stemcells) provides a resource to find and download stemcells.

    ```
    bosh -e <environment-alias> upload-stemcell <URL/local_system_path_to_stemcell>
    ```

    **e.g.** When uploading the stemcell to BOSH Lite environment created in previous section (see example steps under section [Create the BOSH Release](#create-the-bosh-release)),
   
    ```
    bosh -e vbox upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
    ```
    
5. Upload the deployment manifest.

    ```
    bosh -e <environment-alias> -d wso2is-pattern-1 deploy manifests/wso2is-manifest.yml
    ```
    
    **e.g.** Uploading the deployment manifest to BOSH Lite environment
    
    ```
    bosh -e vbox -d wso2is-pattern-1 deploy manifests/wso2is-manifest.yml
    ```
    
## Output

To find the IP addresses of created instances via the BOSH CLI and access the WSO2 Identity Server management console via a web browser,

1. List all the instances within a deployment.

    ```
    bosh -e <environment-alias> -d wso2is-pattern-1 vms
    ```
    
    **e.g.** To find the deployed job instances within the deployment in BOSH Lite,
    ```
    bosh -e vbox -d wso2is-pattern-1 vms
    ```
    
    ![Job instances](images/output.png)

2. SSH into an instance.

    ```
    bosh -e <environment-alias> -d wso2is-pattern-1 ssh <instance_id>
    ```
    
    **e.g.** `bosh -e vbox -d wso2is-pattern-1 ssh wso2is_1/b549a7ef-75dd-44e2-9a58-3c3f3813bd96`
    
3. Access the WSO2 Identity Server management console URL.

    ```
    https://10.244.15.2:9443/carbon/
    ```

## Delete the BOSH release deployment

1. Delete the deployment.

    ```
    bosh -e <environment-alias> -d wso2is-pattern-1 delete-deployment
    ```
    
    **e.g.** To delete the WSO2 Identity Server pattern 1 deployment in the BOSH Lite environment,
    
    ```
    bosh -e vbox -d wso2is-pattern-1 delete-deployment
    ```

2. **[Optional]** Cleanup the BOSH release, stemcell, disks and etc.

    ```
    bosh -e <environment-alias> clean-up --all
    ```

## BOSH release structure

Structure of the directories and files of the BOSH release is as follows:

```
└── bosh-release
    ├── .deployment
    ├── config
    ├── dbscripts
    ├── images
    ├── jobs
    ├── manifests
        ├── wso2is-manifest.yml
    ├── packages
    └── README.md
```

## References

* [BOSH CLI v2 commands](https://bosh.io/docs/cli-v2.html)
* [A Guide to Using BOSH](http://mariash.github.io/learn-bosh/)
* [BOSH Lite](https://bosh.io/docs/bosh-lite.html)
